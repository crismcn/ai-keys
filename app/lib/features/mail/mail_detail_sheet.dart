import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/email_account.dart';
import '../../core/models/mail_message.dart';
import '../../core/services/mail_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/avatar.dart';

/// Bottom-sheet drawer showing one email's full content (API.MD #3).
///
/// Fetches the detail on open; when it arrives, [onRead] is fired once so the
/// caller can mark the mail read (keyed by mailbox address + date — see
/// [MailReadStore.keyFor]).
class MailDetailSheet extends StatefulWidget {
  const MailDetailSheet({
    super.key,
    required this.account,
    required this.messageId,
    required this.headerSubject,
    required this.headerSender,
    required this.onRead,
  });

  final EmailAccount account;
  final String messageId;
  final String headerSubject;
  final String headerSender;
  final VoidCallback onRead;

  @override
  State<MailDetailSheet> createState() => _MailDetailSheetState();
}

class _MailDetailSheetState extends State<MailDetailSheet> {
  MailDetail? _detail;
  bool _loading = true;
  bool _error = false;

  /// Renders the email's HTML body when the detail has one; null → plain text.
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final detail = await MailService.fetchEmailDetail(
        account: widget.account,
        messageId: widget.messageId,
      );
      if (!mounted) return;
      // Build an HTML renderer up front so the body region can embed it. Email
      // HTML is untrusted, so JavaScript stays disabled.
      _webController = detail.html.trim().isNotEmpty
          ? (WebViewController()
              ..setJavaScriptMode(JavaScriptMode.disabled)
              ..setBackgroundColor(context.c.surface)
              ..loadHtmlString(_wrapHtml(detail.html)))
          : null;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      widget.onRead();
    } on MailException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  /// Wraps raw email HTML in a responsive, theme-aware document so it fits the
  /// sheet width and matches the current light/dark surface.
  String _wrapHtml(String inner) {
    final c = context.c;
    String hex(Color x) =>
        '#${(x.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=5">
<style>
  html, body { margin: 0; padding: 0; background: ${hex(c.surface)}; }
  body {
    padding: 16px;
    color: ${hex(c.textPrimary)};
    font-size: 15px;
    line-height: 1.6;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
      Helvetica, Arial, sans-serif;
    word-break: break-word;
    overflow-wrap: break-word;
    -webkit-text-size-adjust: 100%;
  }
  img { max-width: 100%; height: auto; }
  a { color: ${hex(AppColors.primary)}; }
  table { max-width: 100%; }
  pre { white-space: pre-wrap; word-wrap: break-word; }
  * { max-width: 100%; box-sizing: border-box; }
</style>
</head>
<body>$inner</body>
</html>
''';
  }
  // _BODY_

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
        child: Column(
          children: [
            _grabHandle(),
            _header(),
            Divider(height: 1, color: context.c.border),
            Expanded(
              child: _loading
                  ? _loadingState()
                  : _error
                      ? _errorState()
                      : _content(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grabHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.c.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.headerSubject.isNotEmpty
                  ? widget.headerSubject
                  : widget.headerSender,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: context.c.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: context.c.neutral),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
  // _CONTENT_

  Widget _content() {
    final d = _detail!;
    final webController = _webController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _senderRow(d),
              const SizedBox(height: AppSpacing.lg),
              _metaRow(context.s.mailTo, _addressOnly(d.to)),
              const SizedBox(height: 6),
              _metaRow(context.s.mailFrom, d.from),
            ],
          ),
        ),
        Divider(height: 1, color: context.c.border),
        Expanded(
          child: webController != null
              ? WebViewWidget(controller: webController)
              : _plainBody(d),
        ),
      ],
    );
  }

  /// Fallback for emails with no HTML part: the plain-text body, selectable.
  Widget _plainBody(MailDetail d) {
    final body = d.displayBody;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SelectableText(
          body.isNotEmpty ? body : context.s.mailNoBody,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: body.isNotEmpty
                ? context.c.textPrimary
                : context.c.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _senderRow(MailDetail d) {
    final sender = _nameOf(d.from);
    return Row(
      children: [
        LetterAvatar(
          name: sender,
          letter: sender.isNotEmpty ? sender[0].toUpperCase() : '?',
          size: 44,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sender,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.c.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                d.displayDate,
                style: TextStyle(fontSize: 12, color: context.c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: context.c.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: context.c.textPrimary),
          ),
        ),
      ],
    );
  }
  // _STATES_

  Widget _loadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.s.mailLoading,
            style: TextStyle(fontSize: 13, color: context.c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: context.c.neutral),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.s.mailLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.s.mailRetry),
            ),
          ],
        ),
      ),
    );
  }

  /// `Name <email>` → `Name` (or the local part when unnamed).
  String _nameOf(String raw) {
    final r = raw.trim();
    final lt = r.indexOf('<');
    var name = (lt > 0 ? r.substring(0, lt) : r).replaceAll('"', '').trim();
    if (name.isEmpty) {
      final addr = _addressOnly(r);
      final at = addr.indexOf('@');
      name = at > 0 ? addr.substring(0, at) : addr;
    }
    return name;
  }

  /// `Name <email>` → `email`.
  String _addressOnly(String raw) {
    final lt = raw.indexOf('<');
    final gt = raw.indexOf('>');
    if (lt >= 0 && gt > lt) return raw.substring(lt + 1, gt).trim();
    return raw.trim();
  }
}
