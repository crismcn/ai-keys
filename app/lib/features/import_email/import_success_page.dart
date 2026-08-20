import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/email_account.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';
import 'import_email_page.dart';

class ImportSuccessPage extends StatefulWidget {
  const ImportSuccessPage({super.key, required this.result});

  final ImportResult result;

  @override
  State<ImportSuccessPage> createState() => _ImportSuccessPageState();
}

class _ImportSuccessPageState extends State<ImportSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      _successMark(),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        context.s.importSuccess,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.s.importedCount(r.total),
                        style: TextStyle(
                            fontSize: 14, color: context.c.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _summaryCard(r),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: context.s.viewList,
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: context.s.continueImport,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ImportEmailPage()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
  // _MARK_

  Widget _successMark() {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BurstPainter(_controller.value),
            child: Center(
              child: Transform.scale(
                scale: Curves.elasticOut.transform(_controller.value.clamp(0, 1)),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: 82,
          height: 82,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x3322C55E), blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
        ),
      ),
    );
  }

  Widget _summaryCard(ImportResult r) {
    final rows = [
      (context.s.summaryAdded, '${r.added}', context.c.textPrimary),
      (context.s.summaryUpdated, '${r.updated}', context.c.textPrimary),
      (context.s.summaryFailed, '${r.failed}',
          r.failed > 0 ? AppColors.danger : context.c.textPrimary),
      (context.s.summaryAvailable, '${r.available}', AppColors.success),
    ];
    return SectionCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.c.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: TextStyle(fontSize: 14, color: context.c.textSecondary),
                  ),
                  Text(
                    rows[i].$2,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: rows[i].$3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Radiating dots behind the success checkmark.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final progress = Curves.easeOut.transform(t.clamp(0, 1));
    final colors = [AppColors.success, AppColors.primary];
    const count = 8;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final radius = 44 + progress * 24;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()..color = colors[i % 2].withValues(alpha: opacity);
      final dx = center.dx + math.cos(angle) * radius;
      final dy = center.dy + math.sin(angle) * radius;
      canvas.drawCircle(Offset(dx, dy), 3.5 * (1 - progress * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
