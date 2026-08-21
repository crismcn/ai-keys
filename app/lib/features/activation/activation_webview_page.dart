import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';

/// In-app browser that loads the activation auth link — also reused to open
/// links tapped inside a rendered email body.
///
/// When both [loginEmail] and [loginPassword] are supplied (the activation
/// flow), the page auto-drives sign-in after the auth link loads (AUTO-SCRIPT.MD):
/// once the verify-email page settles it navigates to [_signInUrl], then injects
/// JS to fill account/password, tick the agreement box, and submit. Credentials
/// are only ever injected on the hard-coded cun.ai sign-in origin — never on the
/// untrusted link itself or on email-body links (which pass these null).
class ActivationWebViewPage extends StatefulWidget {
  const ActivationWebViewPage({
    super.key,
    required this.url,
    this.title,
    this.loginEmail,
    this.loginPassword,
    this.onKeyCaptured,
  });

  final String url;

  /// Optional app-bar title; defaults to the activation-verification label.
  final String? title;

  /// Account + password to auto-fill on the sign-in page. Both null → the page
  /// is a plain in-app browser (no redirect, no injection).
  final String? loginEmail;
  final String? loginPassword;

  /// Called with the generated API key once it's created + copied on the keys
  /// page, so the caller can persist it onto the account. When it fires the
  /// page also pops itself, returning to the app.
  final ValueChanged<String>? onKeyCaptured;

  @override
  State<ActivationWebViewPage> createState() => _ActivationWebViewPageState();
}

class _ActivationWebViewPageState extends State<ActivationWebViewPage> {
  /// Hard-coded sign-in destination — credentials are only injected here.
  /// Hard-coded destinations — credentials/automation only run on these.
  static const _signInUrl = 'https://www.cun.ai/sign-in';
  static const _keysUrl = 'https://www.cun.ai/keys';

  late final WebViewController _controller;
  double _progress = 0;
  bool _error = false;

  // One-shot guards for each stage of the automated flow (AUTO-SCRIPT.MD).
  bool _redirectedToSignIn = false; // verify-email → sign-in redirect fired
  bool _signInInjected = false; // sign-in form filled + submitted
  bool _navigatedToKeys = false; // post-login → /keys navigation fired
  bool _createKeyInjected = false; // create/name/save/copy script injected
  bool _keyCaptured = false; // API key received from the page (once)

  /// Auto sign-in is on only when the caller supplied both credentials.
  bool get _autoLogin =>
      widget.loginEmail != null && widget.loginPassword != null;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'KeyBridge',
        onMessageReceived: (msg) => _onKeyCaptured(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageStarted: (_) => setState(() {
            _error = false;
            _progress = 0;
          }),
          onPageFinished: (url) {
            setState(() => _progress = 1);
            if (_autoLogin) _handleAutoLogin(url);
          },
          onUrlChange: (change) {
            // SPA route changes (history API) don't fire onPageFinished, so the
            // post-login redirect and dialog steps are driven from here too.
            final url = change.url;
            if (_autoLogin && url != null) _handleAutoLogin(url);
          },
          onWebResourceError: (err) {
            // Ignore sub-resource errors; only flag the main frame failing.
            if (err.isForMainFrame ?? true) {
              setState(() => _error = true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    // Clear the web session on exit so the next activation doesn't resume the
    // previous account: without this, cun.ai's auth cookies + cached storage
    // persist and the sign-in page loads already logged in as the old account.
    if (_autoLogin) {
      _controller.clearCache();
      _controller.clearLocalStorage();
      WebViewCookieManager().clearCookies();
    }
    super.dispose();
  }

  /// URL-driven state machine for the automated flow (AUTO-SCRIPT.MD #1–#5).
  /// Called from both onPageFinished (full loads) and onUrlChange (SPA routes),
  /// so every branch is guarded to run its side effect exactly once.
  void _handleAutoLogin(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    if (!host.endsWith('cun.ai')) return; // never automate off cun.ai
    final path = uri?.path ?? '';

    if (path.contains('/sign-in')) {
      // #2 — fill account/password, tick agreement, submit.
      if (!_signInInjected) {
        _signInInjected = true;
        _controller.runJavaScript(_signInScript());
      }
      return;
    }

    if (path.contains('/keys')) {
      // #3–#5 — create an API key, name it, save, copy.
      if (!_createKeyInjected) {
        _createKeyInjected = true;
        _controller.runJavaScript(_createKeyScript());
      }
      return;
    }

    if (!_signInInjected && !_redirectedToSignIn) {
      // #1 — still on the verify-email link; let its request settle, then go
      // to the sign-in page.
      _redirectedToSignIn = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _controller.loadRequest(Uri.parse(_signInUrl));
      });
    } else if (_signInInjected && !_navigatedToKeys) {
      // #3 — sign-in submitted and we've left /sign-in → login succeeded, so
      // head to the keys page.
      _navigatedToKeys = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _controller.loadRequest(Uri.parse(_keysUrl));
      });
    }
  }

  /// Signalled by the keys page (step 6) once it has clicked the copy button
  /// and verified a valid `sk-...` key was copied ([window.__copiedKey], with a
  /// scrape / clipboard fallback). We re-verify the format here, persist the key
  /// onto the account, then **clear the system clipboard** (the key is already
  /// saved and shown with its own copy button, so no need to leave it lingering)
  /// and pop back to the app. Guarded to run once; if nothing valid arrives it
  /// stays disarmed so a later signal can retry.
  Future<void> _onKeyCaptured(String captured) async {
    if (_keyCaptured) return;

    final keyRe = RegExp(r'sk-[A-Za-z0-9_\-]{20,}');
    var key = '';

    // 1) The string the page copied — the real, unmasked key.
    final m = keyRe.firstMatch(captured.trim());
    if (m != null) key = m.group(0)!;

    // 2) Fall back to verifying the actual system clipboard.
    if (key.isEmpty) {
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final cm = keyRe.firstMatch(data?.text?.trim() ?? '');
        if (cm != null) key = cm.group(0)!;
      } catch (_) {
        // Clipboard unavailable — ignore.
      }
    }

    if (key.isEmpty) return; // no valid sk- key yet; stay disarmed for a retry
    _keyCaptured = true;

    widget.onKeyCaptured?.call(key);

    // Verification succeeded → wipe the clipboard so the key doesn't linger.
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (_) {}

    if (mounted) Navigator.of(context).maybePop();
  }

  /// JS injected on the sign-in page. The form is a React/Base-UI SPA, so it
  /// polls until the fields hydrate, sets values through the native setter (so
  /// React's onChange fires), ticks the agreement checkbox, and submits.
  /// [widget.loginEmail]/[widget.loginPassword] are JSON-encoded into safe JS
  /// string literals to avoid injection. Selectors prefer the IDs from
  /// AUTO-SCRIPT.MD, with type-based fallbacks in case the generated IDs shift.
  String _signInScript() {
    final email = jsonEncode(widget.loginEmail);
    final password = jsonEncode(widget.loginPassword);
    return '''
(function() {
  var EMAIL = $email;
  var PASSWORD = $password;
  var tries = 0;
  function setValue(el, value) {
    var proto = el.tagName === 'TEXTAREA'
      ? window.HTMLTextAreaElement.prototype
      : window.HTMLInputElement.prototype;
    var setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
    setter.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }
  function emailField() {
    return document.querySelector('#_r_1_-form-item')
      || document.querySelector('input[type="email"]')
      || document.querySelector('input[name*="email" i]')
      || document.querySelector('input[type="text"]');
  }
  function passwordField() {
    return document.querySelector('#_r_3_-form-item')
      || document.querySelector('input[type="password"]');
  }
  function agreeBox() {
    return document.querySelector('#base-ui-_r_5_')
      || document.querySelector('[role="checkbox"]');
  }
  function submitBtn() {
    return document.querySelector('button[type="submit"]');
  }
  function attempt() {
    tries++;
    var email = emailField();
    var pwd = passwordField();
    if (email && pwd) {
      setValue(email, EMAIL);
      setValue(pwd, PASSWORD);
      var cb = agreeBox();
      if (cb && cb.getAttribute('aria-checked') !== 'true') cb.click();
      var btn = submitBtn();
      var disabled = btn && (btn.disabled || btn.getAttribute('aria-disabled') === 'true');
      if (btn && !disabled) { btn.click(); return; }
    }
    if (tries < 40) setTimeout(attempt, 250);
  }
  attempt();
})();
''';
  }

  /// JS injected on the keys page (AUTO-SCRIPT.MD #4–#6): after a short wait,
  /// click "创建 API 密钥 / Create API Key", fill the dialog name with
  /// "test-api", click "保存更改 / Save changes"; then wait ~5s and click the
  /// copy button (a tooltip-trigger carrying the copy icon) a few times to be
  /// sure the key lands on the system clipboard, then signal Dart via KeyBridge.
  /// Dart ([_onKeyCaptured]) reads the copied key back off the clipboard, saves
  /// it and pops. Buttons/inputs are matched by text or structural icon since
  /// their Tailwind classes are volatile. Every step polls for its target.
  String _createKeyScript() {
    return r'''
(function() {
  // Capture whatever the page tries to copy AT ITS SOURCE. A synthetic
  // btn.click() has no transient user activation, so navigator.clipboard.
  // writeText() is rejected and the system clipboard stays empty even though
  // the button's tooltip fires. By intercepting the copy call we grab the real
  // (unmasked) key string directly and hand it to Dart, which writes it to the
  // system clipboard itself. Installed before the copy button is ever clicked.
  window.__copiedKey = '';
  function rememberCopy(t) {
    if (typeof t !== 'string') return;
    t = t.trim();
    if (!t) return;
    if (t.indexOf('sk-') !== -1) { window.__copiedKey = t; return; }
    if (!window.__copiedKey && t.length >= 20 && t.indexOf(' ') === -1) {
      window.__copiedKey = t;
    }
  }
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      var _origWrite = navigator.clipboard.writeText.bind(navigator.clipboard);
      navigator.clipboard.writeText = function(t) {
        rememberCopy(t);
        try { return _origWrite(t); } catch (e) { return Promise.resolve(); }
      };
    }
  } catch (e) {}
  try {
    var _origExec = document.execCommand.bind(document);
    document.execCommand = function(cmd) {
      if (String(cmd).toLowerCase() === 'copy') {
        var a = document.activeElement;
        if (a) rememberCopy(a.value || a.textContent || '');
        if (window.getSelection) rememberCopy(window.getSelection().toString());
      }
      return _origExec.apply(document, arguments);
    };
  } catch (e) {}
  document.addEventListener('copy', function(e) {
    try {
      var d = e.clipboardData || window.clipboardData;
      if (d && d.getData) rememberCopy(d.getData('text/plain'));
    } catch (err) {}
  }, true);

  function btnByText(texts) {
    var btns = document.querySelectorAll('button');
    for (var i = 0; i < btns.length; i++) {
      var label = (btns[i].textContent || '').trim();
      for (var t = 0; t < texts.length; t++) {
        if (label.indexOf(texts[t]) !== -1) return btns[i];
      }
    }
    return null;
  }
  function createBtn() {
    var b = btnByText(['创建 API 密钥', '创建API密钥', 'Create API Key']);
    if (b) return b;
    // Structural fallback: the button carrying the lucide "plus" icon.
    var plus = document.querySelector('button svg.lucide-plus');
    return plus ? plus.closest('button') : null;
  }
  function setValue(el, value) {
    var setter = Object.getOwnPropertyDescriptor(
      window.HTMLInputElement.prototype, 'value').set;
    setter.call(el, value);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  }
  function waitFor(getter, cb, tries) {
    tries = tries || 0;
    var el = getter();
    if (el) { cb(el); return; }
    if (tries < 60) setTimeout(function() { waitFor(getter, cb, tries + 1); }, 250);
  }
  // Pull the freshly-created key out of the dialog: first a long token in any
  // input/textarea, else a long standalone token in code/pre/span text.
  function extractKey(root) {
    var fields = root.querySelectorAll('input, textarea');
    for (var i = 0; i < fields.length; i++) {
      var v = (fields[i].value || '').trim();
      if (/^[A-Za-z0-9_\-\.]{20,}$/.test(v)) return v;
    }
    var nodes = root.querySelectorAll('code, pre, span, div');
    for (var j = 0; j < nodes.length; j++) {
      var t = (nodes[j].textContent || '').trim();
      if (t.indexOf(' ') === -1 && /^[A-Za-z0-9][A-Za-z0-9_\-\.]{23,}$/.test(t)) return t;
    }
    return '';
  }
  // The copy button (AUTO-SCRIPT.MD #6): the button whose subtree carries the
  // lucide "copy" icon — scan all buttons and take the first match. Fall back to
  // the tooltip-trigger selectors in case the icon class ever shifts.
  function copyBtn() {
    var btns = document.querySelectorAll('button');
    for (var i = 0; i < btns.length; i++) {
      if (btns[i].querySelector('svg.lucide-copy')) return btns[i];
    }
    var el = document.querySelector('button[data-slot="tooltip-trigger"] svg.lucide-copy');
    if (el) return el.closest('button');
    return document.querySelector('button[data-slot="tooltip-trigger"]');
  }

  // #4 — wait ~2s for the page to settle, then open the create-key dialog.
  setTimeout(function() {
    waitFor(createBtn, function(btn) {
      btn.click();
      // #5 — name the key and save.
      waitFor(function() {
        return document.querySelector('#_r_lu_-form-item')
          || document.querySelector('[role="dialog"] input[type="text"]')
          || document.querySelector('[role="dialog"] input');
      }, function(nameInput) {
        setValue(nameInput, 'test-api');
        waitFor(function() {
          return btnByText(['保存更改', 'Save changes', 'Save']);
        }, function(saveBtn) {
          saveBtn.click();
          // #6 — wait ~5s for the key dialog to render, then click the copy
          // button a few times (a single click can silently no-op) so the key
          // lands on the system clipboard. Then signal Dart via KeyBridge; Dart
          // reads the copied key back off the clipboard, saves it to the account
          // and pops back to the app. The page-scraped key is passed along as a
          // fallback for when the clipboard read comes back empty.
          setTimeout(function() {
            var pageKey = extractKey(document.querySelector('[role="dialog"]') || document)
              || extractKey(document);
            var keyRe = /sk-[A-Za-z0-9_\-]{20,}/;
            waitFor(copyBtn, function(btn) {
              var attempts = 0;
              // Click the copy button, then verify what actually landed. A
              // single synthetic click often no-ops (no user activation), so we
              // keep clicking and re-checking until the copied value is a valid
              // sk- key, then hand THAT verified key to Dart. Give up after a
              // bounded number of tries and let Dart fall back.
              function tryCopy() {
                attempts++;
                try { btn.click(); } catch (e) {}
                setTimeout(function() {
                  var got = window.__copiedKey || '';
                  if (keyRe.test(got)) {
                    try { KeyBridge.postMessage(got); } catch (e) {}
                  } else if (attempts < 12) {
                    tryCopy();
                  } else {
                    try { KeyBridge.postMessage(window.__copiedKey || pageKey); } catch (e) {}
                  }
                }, 1000);
              }
              tryCopy();
            });
          }, 5000);
        });
      });
    });
  }, 2000);
})();
''';
  }

  void _reload() {
    setState(() {
      _error = false;
      _progress = 0;
    });
    // Restart the whole automated flow from the original link on manual reload.
    _redirectedToSignIn = false;
    _signInInjected = false;
    _navigatedToKeys = false;
    _createKeyInjected = false;
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        title: Text(widget.title ?? context.s.webviewTitle),
        bottom: _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: _error
            ? _errorView(context)
            : WebViewWidget(controller: _controller),
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: context.c.neutral),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.s.webviewLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.s.webviewRetry),
            ),
          ],
        ),
      ),
    );
  }
}
