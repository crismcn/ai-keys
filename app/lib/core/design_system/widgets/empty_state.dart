import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// 空态占位：霓虹玻璃图标块 + 标题 + 副标题 + 可选操作。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedFg =
        isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 46 : 60,
              height: compact ? 46 : 60,
              decoration: BoxDecoration(
                gradient: AppColors.brand,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppGlow.of(
                  AppColors.indigo,
                  blur: 20,
                  alpha: isLight ? 0.28 : 0.45,
                ),
              ),
              child: Icon(icon, size: compact ? 22 : 26, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w700,
                color: isLight ? AppColors.foreground : AppColors.foregroundDark,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5, color: mutedFg),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
