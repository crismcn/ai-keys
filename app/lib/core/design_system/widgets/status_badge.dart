import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// 激活状态徽标：霓虹玻璃小胶囊 + 发光圆点。
class StatusBadge extends StatelessWidget {
  const StatusBadge.available({super.key})
      : activated = true,
        label = '可用';

  const StatusBadge.pending({super.key})
      : activated = false,
        label = '未激活';

  final bool activated;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final success = isLight ? AppColors.success : AppColors.successDark;
    final mutedFg =
        isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;

    final dotColor = activated ? success : mutedFg;
    final bg = activated
        ? (isLight
            ? AppColors.successSoft
            : success.withValues(alpha: 0.14))
        : (isLight ? AppColors.muted : AppColors.mutedDark);
    final fg = activated ? success : mutedFg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: activated
                  ? AppGlow.of(dotColor, blur: 8, alpha: 0.8)
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
