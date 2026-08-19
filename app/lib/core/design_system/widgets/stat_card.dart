import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// 首页顶部统计卡：专属渐变底 + 白色大数字 + 辉光。
/// 不传 [accent] 用品牌渐变（靛蓝 → 紫）；传 [AppColors.success] 用翠绿渐变。
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final gradient =
        accent == AppColors.success ? AppColors.emeraldGradient : AppColors.brand;
    final glowColor =
        accent == AppColors.success ? AppColors.emerald : AppColors.indigo;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppGlow.of(
          glowColor,
          blur: 20,
          alpha: isLight ? 0.32 : 0.5,
          offset: const Offset(0, 8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1, // ≥1.1，防数字上下裁切
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
