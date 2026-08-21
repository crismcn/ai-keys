import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/email_account.dart';
import '../../core/state/email_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';
import '../mail/mail_list_page.dart';
import 'activation_webview_page.dart';

/// Activation records tab (ACTIVE-RECORDS.MD): a minimal timeline list of
/// activated accounts. Each row shows a bordered letter-avatar node, its email
/// (tap to copy), the auth link (opens the automated web flow), the parsed
/// quota, a masked API key (tap to copy) and a status dot. The title is a
/// [已使用 | 待使用] segmented filter that links to the list below; a top-right
/// export button mirrors the home import button (not wired up yet).
class ActivationRecordsPage extends StatefulWidget {
  const ActivationRecordsPage({super.key});

  @override
  State<ActivationRecordsPage> createState() => _ActivationRecordsPageState();
}

class _ActivationRecordsPageState extends State<ActivationRecordsPage> {
  // Selected filter: 0 = 待使用 (activated but not yet used), 1 = 已使用 (used).
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EmailStore>();
    // Records = accounts that have gone through activation, most recent first.
    // activatedAt is ISO-8601 so a descending string sort is chronological;
    // empty timestamps (legacy records) sort last.
    final records = store.accounts.where((a) => a.activated).toList()
      ..sort((a, b) => b.activatedAt.compareTo(a.activatedAt));
    // Split by the tab filter: 待使用 (pending) first, then 已使用 (used).
    final shown = records
        .where((a) => _tab == 0
            ? a.status != AccountStatus.used
            : a.status == AccountStatus.used)
        .toList();

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
                child: Row(
                  children: [
                    // Title → segmented filter (ACTIVE-RECORDS.MD #4); switching
                    // slides the pill and re-filters the list below.
                    _FilterTabs(
                      index: _tab,
                      labels: [context.s.recordsTabPending, context.s.recordsTabUsed],
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    const Spacer(),
                    // Export (ACTIVE-RECORDS.MD #3): mirrors the home import
                    // button; wiring is deferred, so it just hints "coming soon".
                    SoftPillButton(
                      label: context.s.exportRecords,
                      icon: Icons.file_upload_outlined,
                      onPressed: () => _comingSoon(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                // Cross-fade the list when the tab changes so the filter feels
                // linked to the timeline.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: shown.isEmpty
                      ? _emptyState(context)
                      : ListView.builder(
                          key: ValueKey(_tab),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: AppSpacing.sm,
                            bottom: AppSpacing.lg,
                          ),
                          itemCount: shown.length,
                          itemBuilder: (_, i) => _RecordTile(
                            account: shown[i],
                            isLast: i == shown.length - 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.s.comingSoon(context.s.exportRecords)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget _emptyState(BuildContext context) {    return Center(
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

/// A compact two-segment [已使用 | 待使用] filter that replaces the page title.
/// The highlight pill slides between the halves ([AnimatedAlign]) and the label
/// colours cross-fade ([AnimatedDefaultTextStyle]) when the selection changes.
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index; // 0 or 1
  final List<String> labels; // exactly two
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.c.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Stack(
        children: [
          // Sliding highlight — half the track, aligned to the active segment.
          AnimatedAlign(
            alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.button - 3),
                ),
              ),
            ),
          ),
          Row(children: [_segment(context, 0), _segment(context, 1)]),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, int i) {
    final selected = index == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 240),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.c.textSecondary,
            ),
            child: Text(labels[i]),
          ),
        ),
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

  /// Opens the cun.ai home in the automated WebView to create the API key —
  /// the same auto sign-in → keys → create-key script as the activation flow.
  /// On capture the key is saved onto this record via [_saveApiKey].
  void _openCreateFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivationWebViewPage(
          url: 'https://www.cun.ai/',
          loginEmail: account.email,
          loginPassword: account.password,
          onKeyCaptured: (key) => _saveApiKey(context, key),
        ),
      ),
    );
  }

  void _saveApiKey(BuildContext context, String key) {
    context.read<EmailStore>().setApiKey(account, key);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.s.apiKeySaved),
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
              // Timeline origin = the account's letter avatar (ACTIVE-RECORDS.MD
              // #2), wrapped in a soft translucent-white ring so the node reads
              // as separate from the dashed connector below it.
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 3,
                    ),
                  ),
                  child: LetterAvatar(
                    name: account.email,
                    letter: account.initial,
                    size: 34,
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
              // Pending items (not yet used) can be right-swiped to mark used.
              child: account.status == AccountStatus.used
                  ? _card(context, statusColor)
                  : _swipeToUse(context, _card(context, statusColor)),
            ),
          ),
        ],
      ),
    );
  }
  // _CARD_

  /// Wraps a pending record's card so a right-swipe (startToEnd) marks the
  /// account used. Confirms first and never actually dismisses — the store
  /// re-filter drops it from the 待使用 list once the status flips.
  Widget _swipeToUse(BuildContext context, Widget child) {
    return Dismissible(
      key: ValueKey('record-${account.email}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _markUsed(context);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.used,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white),
      ),
      child: child,
    );
  }

  Future<void> _markUsed(BuildContext context) async {
    final store = context.read<EmailStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.s.confirmUsedTitle),
        content: Text(context.s.confirmUsedBody(account.accountName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.used),
            child: Text(context.s.markUsed),
          ),
        ],
      ),
    );
    if (ok == true) store.markUsed(account);
  }

  Widget _card(BuildContext context, Color statusColor) {
    // Used records hide the quota + auth link (req 3); pending records hide the
    // auth link once a key exists (req 1). The key row shows whenever present.
    final isUsed = account.status == AccountStatus.used;
    return SectionCard(
      // Tapping a pending record opens its mailbox (mail list).
      onTap: isUsed ? null : () => _openMailList(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Email — tap to copy (ACTIVE-RECORDS.MD #2). The avatar now lives
              // on the timeline rail, so the header is just email + status dot.
              Expanded(
                child: GestureDetector(
                  onTap: () => _copy(context, account.email),
                  behavior: HitTestBehavior.opaque,
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
          // Quota: shown for both lists, defaulting to $ 0.000000 when the
          // activation email carried no parsed quota.
          const SizedBox(height: AppSpacing.sm),
          _quotaPill(context),
          // Key row: masked + copyable when present; otherwise the pending list
          // shows a "去创建" row whose trailing jump button opens the cun.ai auth
          // flow (same automated create-key script) instead of a copy button.
          if (account.apiKey.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _infoRow(
              context,
              icon: Icons.key_rounded,
              value: _maskedKey,
              onTap: () => _copy(context, account.apiKey),
            ),
          ] else if (!isUsed) ...[
            const SizedBox(height: AppSpacing.sm),
            _infoRow(
              context,
              icon: Icons.key_rounded,
              value: context.s.keyNotCreated,
              trailing: Icons.open_in_new_rounded,
              onTap: () => _openCreateFlow(context),
            ),
          ],
        ],
      ),
    );
  }
  // _HELPERS_

  void _openMailList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MailListPage(account: account)),
    );
  }

  /// Small amber credit pill, e.g. "额度 $5.80". Falls back to "$ 0.000000"
  /// when the activation email carried no parsed quota.
  Widget _quotaPill(BuildContext context) {
    final value = account.quota.isNotEmpty ? account.quota : '\$ 0.000000';
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
            '${context.s.quotaLabel} $value',
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

  /// The API key shown masked as `sk-••••<last4>` (ACTIVE-RECORDS.MD #2); the
  /// full key is what actually gets copied on tap.
  String get _maskedKey {
    final k = account.apiKey;
    if (k.length <= 7) return k;
    final head = k.startsWith('sk-') ? 'sk-' : k.substring(0, 3);
    return '$head••••${k.substring(k.length - 4)}';
  }

  /// Tap row: leading icon + ellipsized value + a trailing action icon
  /// ([trailing], default copy).
  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    IconData trailing = Icons.copy_rounded,
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
              Icon(trailing, size: 13, color: AppColors.primary),
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

