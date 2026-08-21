import 'dart:convert';

import 'package:flutter/material.dart';
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

  /// Receives the API key posted from the keys page, hands it to the caller to
  /// persist, then pops back to the app. Guarded to run once.
  void _onKeyCaptured(String key) {
    if (_keyCaptured) return;
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    _keyCaptured = true;
    widget.onKeyCaptured?.call(trimmed);
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
  /// "test-api", click "保存更改 / Save changes", then read the generated key,
  /// post it back via the KeyBridge channel, and click the copy-key button.
  /// Buttons are matched by their (localized) text — with a plus-icon structural
  /// fallback for the create button — since their class lists are volatile
  /// Tailwind. Every step polls for its target to appear.
  String _createKeyScript() {
    return r'''
(function() {
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
          // #6 — after the key is created, capture it back, then copy.
          setTimeout(function() {
            waitFor(function() {
              return document.querySelector('#base-ui-_r_v9_')
                || document.querySelector('[role="dialog"] button[data-slot="tooltip-trigger"]')
                || document.querySelector('button[data-slot="tooltip-trigger"]');
            }, function(copyBtn) {
              var root = document.querySelector('[role="dialog"]') || document;
              var key = extractKey(root);
              if (key) { try { KeyBridge.postMessage(key); } catch (e) {} }
              copyBtn.click();
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
