import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/email_account.dart';
import '../../core/services/activation_service.dart';
import '../../core/state/email_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/confetti.dart';
import '../../widgets/section_card.dart';
import '../mail/mail_list_page.dart';
import 'activation_webview_page.dart';

class _Step {
  const _Step(this.title, this.hint, this.doneHint, this.errorHint, this.icon);
  final String title;
  final String hint;
  final String doneHint;
  final String errorHint;
  final IconData icon;
}

class ActivationDetailPage extends StatefulWidget {
  const ActivationDetailPage({super.key, required this.account});

  final EmailAccount account;

  @override
  State<ActivationDetailPage> createState() => _ActivationDetailPageState();
}

class _ActivationDetailPageState extends State<ActivationDetailPage> {
  Timer? _timer; // 1s ticker driving the active step's elapsed label
  int _current = 0; // index of the active step
  int _elapsed = 0; // seconds elapsed on current step
  bool _done = false;
  String? _stepError; // non-null → current step failed (shows retry)
  String? _authLink; // auth link revealed at step 4 (index 3)

  // Cached intermediate results so a retry can resume mid-pipeline.
  String? _messageId;
  String? _code;

  /// When the page was entered — only mails newer than this are accepted as
  /// the verification / claim email (a retry keeps this original instant).
  final DateTime _enteredAt = DateTime.now();

  List<_Step> get _steps => [
    _Step(
      context.s.step1Title,
      context.s.step1Hint,
      context.s.step1Done,
      context.s.step1Error,
      Icons.send_rounded,
    ),
    _Step(
      context.s.step2Title,
      context.s.step2Hint,
      context.s.step2Done,
      context.s.step2Error,
      Icons.mark_email_read_outlined,
    ),
    _Step(
      context.s.step3Title,
      context.s.step3Hint,
      context.s.step3Done,
      context.s.step3Error,
      Icons.terminal_rounded,
    ),
    _Step(
      context.s.step4Title,
      context.s.step4Hint,
      context.s.step4Done,
      context.s.step4Error,
      Icons.verified_user_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isCancelled() => !mounted;

  void _startTicker() {
    _timer?.cancel();
    _elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
  }

  /// Moves to [step], clearing any error and restarting the elapsed ticker.
  void _startStep(int step) {
    if (!mounted) return;
    setState(() {
      _current = step;
      _stepError = null;
    });
    _startTicker();
  }

  /// Drives the real activation pipeline (API.MD #1→#5), resuming from [from].
  /// Each stage awaits its interface; a failure stops on that step with a
  /// retry affordance instead of advancing.
  Future<void> _run({int from = 0}) async {
    final account = widget.account;
    try {
      if (from <= 0) {
        _startStep(0);
        await ActivationService.sendVerification(account);
        if (!mounted) return;
      }
      if (from <= 1) {
        _startStep(1);
        final vr = await ActivationService.awaitVerificationCode(
          account,
          since: _enteredAt,
          isCancelled: _isCancelled,
        );
        if (!mounted) return;
        _messageId = vr.messageId;
        _code = vr.code;
      }
      if (from <= 2) {
        _startStep(2);
        await ActivationService.register(
          account: account,
          messageId: _messageId!,
          code: _code!,
        );
        if (!mounted) return;
      }
      _startStep(3);
      final link = await ActivationService.awaitAuthLink(
        account,
        since: _enteredAt,
        isCancelled: _isCancelled,
      );
      if (!mounted) return;
      setState(() => _authLink = link);

      _timer?.cancel();
      setState(() => _done = true);
      if (mounted) context.read<EmailStore>().markActivated(account);
    } on ActivationException catch (e) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _stepError = e.message);
    }
  }

  void _retry() {
    if (_stepError == null) return;
    _run(from: _current);
  }

  void _openAuthLink() {
    final url = _authLink;
    if (url == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ActivationWebViewPage(url: url)));
  }

  void _copyAuthLink() {
    final url = _authLink;
    if (url == null) return;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.s.copied),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openMail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MailListPage(account: widget.account),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    required Color actionColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: actionColor),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Swipe-left (endToStart) marks the account activated; swipe-right
  /// (startToEnd) marks it used. Both confirm first and never remove the card.
  Future<void> _onAccountSwipe(DismissDirection direction) async {
    final account = widget.account;
    final store = context.read<EmailStore>();
    if (direction == DismissDirection.endToStart) {
      final ok = await _confirm(
        title: context.s.confirmActivateTitle,
        body: context.s.confirmActivateBody(account.accountName),
        action: context.s.activate,
        actionColor: AppColors.success,
      );
      if (ok) {
        await store.markActivated(account);
        if (mounted) _toast(context.s.activatedToast);
      }
    } else {
      final ok = await _confirm(
        title: context.s.confirmUsedTitle,
        body: context.s.confirmUsedBody(account.accountName),
        action: context.s.markUsed,
        actionColor: AppColors.used,
      );
      if (ok) {
        await store.markUsed(account);
        if (mounted) _toast(context.s.usedToast);
      }
    }
  }

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
  // _BODY_

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(title: Text(context.s.activationTitle)),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _accountCard(account),
                const SizedBox(height: AppSpacing.lg),
                _timelineCard(),
                if (_authLink != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _authLinkCard(),
                ],
                const SizedBox(height: AppSpacing.lg),
                _warningBanner(),
              ],
            ),
            if (_done) const Positioned.fill(child: ConfettiOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _accountCard(EmailAccount account) {
    return Dismissible(
      key: ValueKey('activation-account-${account.email}'),
      confirmDismiss: (direction) async {
        // Never dismiss: swipe just advances state, then the card snaps back.
        await _onAccountSwipe(direction);
        return false;
      },
      // startToEnd (右滑) → 已使用 (黄); endToStart (左滑) → 激活 (绿).
      background: _swipeBackground(
        color: AppColors.used,
        icon: Icons.hourglass_bottom_rounded,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBackground(
        color: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        alignment: Alignment.centerRight,
      ),
      child: SectionCard(
        onTap: _openMail,
        child: Row(
          children: [
            LetterAvatar(name: account.email, letter: account.initial, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.accountName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    account.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: context.c.neutral, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _timelineCard() {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            _TimelineTile(
              step: _steps[i],
              isFirst: i == 0,
              isLast: i == _steps.length - 1,
              status: _statusFor(i),
              timeLabel: i == _current && _stepError == null && !_done
                  ? _fmt(_elapsed)
                  : (_statusFor(i) == _TileStatus.done ? '' : '--:--'),
              errorText: _statusFor(i) == _TileStatus.failed ? _stepError : null,
              onRetry: _retry,
            ),
        ],
      ),
    );
  }

  _TileStatus _statusFor(int i) {
    if (i == _current && _stepError != null) return _TileStatus.failed;
    if (i < _current || (_done && i == _current)) return _TileStatus.done;
    if (i == _current) return _TileStatus.active;
    return _TileStatus.pending;
  }

  Widget _authLinkCard() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.c.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.s.authLinkTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.s.authLinkHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _openAuthLink,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _authLink ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: _copyAuthLink,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _warningBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.s.warnTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.c.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.s.warnBody,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.c.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// _TILE_

enum _TileStatus { done, active, pending, failed }

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.step,
    required this.status,
    required this.timeLabel,
    required this.isFirst,
    required this.isLast,
    this.errorText,
    this.onRetry,
  });

  final _Step step;
  final _TileStatus status;
  final String timeLabel;
  final bool isFirst;
  final bool isLast;
  final String? errorText;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDone = status == _TileStatus.done;
    final isActive = status == _TileStatus.active;
    final isFailed = status == _TileStatus.failed;
    final accent = isDone
        ? AppColors.primaryLight
        : isActive
        ? AppColors.primary
        : isFailed
        ? AppColors.danger
        : context.c.neutral;
    final titleColor = status == _TileStatus.pending
        ? context.c.textSecondary
        : context.c.textPrimary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _node(context, isDone, isActive, isFailed, accent),
              Expanded(
                child: isLast
                    ? const SizedBox(width: 2)
                    : _DashedLine(
                        color: isDone
                            ? AppColors.primaryLight
                            : context.c.border,
                      ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: isLast ? 6 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? AppColors.primary
                              : context.c.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFailed
                        ? (errorText ?? step.errorHint)
                        : isDone
                        ? step.doneHint
                        : step.hint,
                    style: TextStyle(
                      fontSize: 12,
                      color: isFailed ? AppColors.danger : context.c.textSecondary,
                    ),
                  ),
                  if (isFailed && onRetry != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(context.s.activationRetry),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _node(
    BuildContext context,
    bool isDone,
    bool isActive,
    bool isFailed,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(
        width: 26,
        height: 26,
        child: isDone
            ? Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : isFailed
            ? Container(
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : isActive
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating loading ring around the active node.
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              )
            : Icon(step.icon, size: 18, color: context.c.neutral),
      ),
    );
  }
}

/// A thin vertical dashed connector between timeline nodes.
class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      child: CustomPaint(painter: _DashedLinePainter(color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    var y = 0.0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + dash, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
