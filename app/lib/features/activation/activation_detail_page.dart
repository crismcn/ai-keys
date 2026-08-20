import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/email_account.dart';
import '../../core/state/email_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/confetti.dart';
import '../../widgets/section_card.dart';
import 'activation_webview_page.dart';

class _Step {
  const _Step(this.title, this.hint, this.doneHint, this.icon);
  final String title;
  final String hint;
  final String doneHint;
  final IconData icon;
}

class ActivationDetailPage extends StatefulWidget {
  const ActivationDetailPage({super.key, required this.account});

  final EmailAccount account;

  @override
  State<ActivationDetailPage> createState() => _ActivationDetailPageState();
}

class _ActivationDetailPageState extends State<ActivationDetailPage> {
  Timer? _timer;
  int _current = 0; // index of the active step
  int _elapsed = 0; // seconds elapsed on current step
  bool _done = false;
  String? _authLink; // auth link revealed when step 4 (index 3) is reached

  static const _stepDuration = 3; // seconds per step (simulated)

  List<_Step> get _steps => [
    _Step(
      context.s.step1Title,
      context.s.step1Hint,
      context.s.step1Done,
      Icons.send_rounded,
    ),
    _Step(
      context.s.step2Title,
      context.s.step2Hint,
      context.s.step2Done,
      Icons.mark_email_read_outlined,
    ),
    _Step(
      context.s.step3Title,
      context.s.step3Hint,
      context.s.step3Done,
      Icons.terminal_rounded,
    ),
    _Step(
      context.s.step4Title,
      context.s.step4Hint,
      context.s.step4Done,
      Icons.verified_user_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    setState(() {
      _elapsed++;
      if (_elapsed >= _stepDuration) {
        _elapsed = 0;
        if (_current < _steps.length - 1) {
          _current++;
          // Reaching the last step ("激活认证阶段") yields the auth link.
          if (_current == _steps.length - 1) {
            _authLink = _buildAuthLink();
          }
        } else {
          _done = true;
          timer.cancel();
          context.read<EmailStore>().markActivated(widget.account);
        }
      }
    });
  }

  /// Builds the activation auth link for this account.
  ///
  /// The real link will come from the activation backend; until that exists we
  /// derive a stable, well-formed placeholder from the account so the flow and
  /// the in-app webview can be exercised end to end.
  String _buildAuthLink() {
    final account = widget.account;
    final token = account.refreshToken.isNotEmpty
        ? account.refreshToken
        : account.email.hashCode.toRadixString(16);
    final params = <String, String>{'email': account.email, 'token': token};
    return Uri.https('example.com', '/activate', params).toString();
  }

  void _openAuthLink() {
    final url = _authLink;
    if (url == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ActivationWebViewPage(url: url)));
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
    return SectionCard(
      child: Row(
        children: [
          LetterAvatar(name: account.email, letter: account.initial, size: 48),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.accountName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.c.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                account.email,
                style: TextStyle(fontSize: 13, color: context.c.textSecondary),
              ),
            ],
          ),
        ],
      ),
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
              status: i < _current || (_done && i == _current)
                  ? _TileStatus.done
                  : i == _current
                  ? _TileStatus.active
                  : _TileStatus.pending,
              timeLabel: i < _current || (_done && i == _current)
                  ? _fmt(_stepDuration)
                  : i == _current
                  ? _fmt(_elapsed)
                  : '--:--',
            ),
        ],
      ),
    );
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
          InkWell(
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

enum _TileStatus { done, active, pending }

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.step,
    required this.status,
    required this.timeLabel,
    required this.isFirst,
    required this.isLast,
  });

  final _Step step;
  final _TileStatus status;
  final String timeLabel;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDone = status == _TileStatus.done;
    final isActive = status == _TileStatus.active;
    final accent = isDone
        ? AppColors.primaryLight
        : isActive
        ? AppColors.primary
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
              _node(context, isDone, isActive, accent),
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
                    isDone ? step.doneHint : step.hint,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _node(BuildContext context, bool isDone, bool isActive, Color accent) {
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
