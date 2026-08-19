import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// 霓虹玻璃卡片（扁平）：半透明纯色底 + 大圆角 + 柔和彩影，无边框线。
/// 底色半透明，透出下方 [GradientBackdrop] 的霓虹光斑。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// 覆盖默认玻璃底色（如成功绿卡）。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? (isLight ? AppColors.card : AppColors.cardDark),
        borderRadius: radius,
        boxShadow: isLight
            ? AppGlow.of(AppColors.violet, blur: 22, alpha: 0.10, offset: const Offset(0, 8))
            : null,
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            )
          : Padding(padding: padding, child: child),
    );
  }
}
