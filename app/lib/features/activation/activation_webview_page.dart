import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';

/// In-app browser that loads the activation auth link.
class ActivationWebViewPage extends StatefulWidget {
  const ActivationWebViewPage({super.key, required this.url});

  final String url;

  @override
  State<ActivationWebViewPage> createState() => _ActivationWebViewPageState();
}

class _ActivationWebViewPageState extends State<ActivationWebViewPage> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageStarted: (_) => setState(() {
            _error = false;
            _progress = 0;
          }),
          onPageFinished: (_) => setState(() => _progress = 1),
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

  void _reload() {
    setState(() {
      _error = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        title: Text(context.s.webviewTitle),
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
