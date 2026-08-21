import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/email_account.dart';
import '../../core/state/email_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/section_card.dart';

/// Activation records tab (ACTIVE-RECORDS.MD): a minimal timeline list of
/// every activated account, each showing its email, auth link, parsed quota,
/// API key (tap to copy) and a status dot.
class ActivationRecordsPage extends StatelessWidget {
  const ActivationRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EmailStore>();
    // Records = accounts that have gone through activation.
    final records = store.accounts.where((a) => a.activated).toList();

    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  context.s.navActivation,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: context.c.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? _emptyState(context)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.lg,
                        ),
                        itemCount: records.length,
                        itemBuilder: (_, i) => _RecordTile(
                          account: records[i],
                          isLast: i == records.length - 1,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 44,
            color: context.c.neutral.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.s.recordsEmpty,
            style: TextStyle(color: context.c.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
// _TILE_

/// One activation record: a timeline node + dashed connector on the left, and
/// a card of the account's activation details on the right.
class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.account, required this.isLast});

  final EmailAccount account;
  final bool isLast;

  Color _statusColor(BuildContext context) => switch (account.status) {
        AccountStatus.used => AppColors.used,
        AccountStatus.available => AppColors.success,
        AccountStatus.inactive => context.c.neutral,
      };

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: isLast
                    ? const SizedBox(width: 2)
                    : _DashedLine(color: context.c.border),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: _card(context, statusColor),
            ),
          ),
        ],
      ),
    );
  }
  // _CARD_

  Widget _card(BuildContext context, Color statusColor) {
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Status: dot only, no label (ACTIVE-RECORDS.MD #2).
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          if (account.quota.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _quotaPill(context),
          ],
          if (account.authLink.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _infoRow(
              context,
              icon: Icons.link_rounded,
              value: account.authLink,
              onTap: () => _copy(context, account.authLink),
            ),
          ],
          if (account.apiKey.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _infoRow(
              context,
              icon: Icons.key_rounded,
              value: account.apiKey,
              onTap: () => _copy(context, account.apiKey),
            ),
          ],
        ],
      ),
    );
  }
  // _HELPERS_

  /// Small amber credit pill, e.g. "额度 $5.80".
  Widget _quotaPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.used.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.savings_outlined, size: 13, color: AppColors.used),
          const SizedBox(width: 5),
          Text(
            '${context.s.quotaLabel} ${account.quota}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.used,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Tap-to-copy row: leading icon + ellipsized value + copy icon.
  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: context.c.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin vertical dashed connector between timeline nodes (matches the
/// activation detail timeline).
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
        Offset(x, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

