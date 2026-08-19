import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// 霓虹渐变按钮。
enum AppButtonVariant {
  /// 品牌渐变（靛蓝 → 紫）+ 辉光。
  primary,

  /// 描边按钮。
  outline,

  /// 幽灵（无背景）按钮。
  ghost,

  /// 危险渐变（红 → 玫瑰）+ 辉光。
  destructive,
}

enum AppButtonSize { sm, md }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  /// 按压状态：触发 0.97 缩放反馈。
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final enabled = widget.onPressed != null;
    final isSm = widget.size == AppButtonSize.sm;
    final radius = BorderRadius.circular(AppRadius.md);
    final primary = isLight ? AppColors.primary : AppColors.primaryDark;

    final padding = EdgeInsets.symmetric(
      horizontal: isSm ? AppSpacing.sm : AppSpacing.md,
      vertical: isSm ? AppSpacing.xs : AppSpacing.sm,
    );

    final Widget content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: isSm ? 14 : 16),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: isSm ? 13 : 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );

    // 变体 → (装饰, 前景色)
    final (BoxDecoration deco, Color fg) =
        switch (widget.variant) {
      AppButtonVariant.primary => (
          BoxDecoration(
            gradient: AppColors.brand,
            borderRadius: radius,
            boxShadow: enabled
                ? AppGlow.of(
                    AppColors.indigo,
                    blur: 16,
                    alpha: isLight ? 0.32 : 0.5,
                  )
                : null,
          ),
          AppColors.onNeon,
        ),
      AppButtonVariant.destructive => (
          BoxDecoration(
            gradient: AppColors.destructiveGradient,
            borderRadius: radius,
            boxShadow: enabled
                ? AppGlow.of(
                    AppColors.red,
                    blur: 16,
                    alpha: isLight ? 0.3 : 0.45,
                  )
                : null,
          ),
          Colors.white,
        ),
      AppButtonVariant.outline => (
          BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: primary, width: 1.4),
          ),
          primary,
        ),
      AppButtonVariant.ghost => (
          BoxDecoration(borderRadius: radius),
          primary,
        ),
    };

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: AnimatedScale(
          scale: _down ? AppMotion.pressScale : 1.0,
          duration: AppMotion.press,
          curve: AppMotion.pressCurve,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: deco,
              child: InkWell(
                borderRadius: radius,
                onTapDown: enabled ? (_) => setState(() => _down = true) : null,
                onTapUp: enabled ? (_) => setState(() => _down = false) : null,
                onTapCancel: () => setState(() => _down = false),
                onTap: widget.onPressed,
                splashColor: widget.variant == AppButtonVariant.primary ||
                        widget.variant == AppButtonVariant.destructive
                    ? Colors.white.withValues(alpha: 0.25)
                    : primary.withValues(alpha: 0.14),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: padding,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: fg),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}