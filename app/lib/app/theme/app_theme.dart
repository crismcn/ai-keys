import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/app_tokens.dart';

/// 霓虹玻璃（Neon Glass）应用主题（明 / 暗双主题）。
///
/// Scaffold 背景透明，真正的底色由 [GradientBackdrop]（挂载于 MaterialApp.builder）
/// 提供；卡片 / 输入框 / 弹窗均为半透明玻璃质感，透出下方霓虹光斑。
abstract final class AppTheme {
  static ThemeData get light => _build(_scheme(Brightness.light));
  static ThemeData get dark => _build(_scheme(Brightness.dark));

  static ColorScheme _scheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ColorScheme(
      brightness: brightness,
      primary: isLight ? AppColors.primary : AppColors.primaryDark,
      onPrimary: AppColors.onNeon,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: isLight ? AppColors.primary : AppColors.primaryDark,
      secondary: isLight ? AppColors.muted : AppColors.mutedDark,
      onSecondary: isLight ? AppColors.foreground : AppColors.foregroundDark,
      surface: Colors.transparent,
      onSurface: isLight ? AppColors.foreground : AppColors.foregroundDark,
      surfaceContainerHighest: isLight ? AppColors.muted : AppColors.mutedDark,
      onSurfaceVariant:
          isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark,
      error: AppColors.destructive,
      onError: Colors.white,
      outline: isLight ? AppColors.border : AppColors.borderDark,
      outlineVariant: isLight ? AppColors.border : AppColors.borderDark,
      surfaceContainerLowest:
          isLight ? AppColors.card : AppColors.cardDark,
      surfaceContainerLow: isLight ? AppColors.card : AppColors.cardDark,
      surfaceContainer: isLight ? AppColors.card : AppColors.cardDark,
      surfaceContainerHigh: isLight ? AppColors.card : AppColors.cardDark,
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final fg = scheme.onSurface;
    final mutedFg = scheme.onSurfaceVariant;
    final primary = scheme.primary;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: fg, displayColor: fg)
          .copyWith(
            // UI Kit 式：更大、更粗的标题字。
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: fg,
            ),
            titleMedium: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: fg,
            ),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
            bodySmall: TextStyle(fontSize: 13, height: 1.4, color: mutedFg),
            labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
            labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mutedFg,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: fg,
        ),
      ),
      cardTheme: CardThemeData(
        color: isLight ? AppColors.card : AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: BorderSide(
            color: isLight ? AppColors.border : AppColors.borderDark,
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.muted : AppColors.mutedDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: TextStyle(color: mutedFg, fontSize: 14),
        labelStyle: TextStyle(color: mutedFg, fontSize: 14),
        enabledBorder: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        border: InputBorder.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.card : AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.foreground : AppColors.foregroundDark,
        contentTextStyle: TextStyle(
          fontSize: 13,
          color: isLight ? Colors.white : AppColors.backgroundDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.border : AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? AppColors.card : AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      // 全 App 平滑转场：纯淡入（320ms 强调减速 / 200ms 加速退出）。
      // 只用 FadeTransition（纯绘制变换），避免路由上下文里的布局级转场坑。
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const _FadePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// 全平台统一的纯淡入页面转场。
/// 进入 320ms 强调减速（起手快），退出 200ms 强调加速；尊重系统减少动态效果。
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotion.enterCurve,
        reverseCurve: AppMotion.exitCurve,
      ),
      child: child,
    );
  }
}

/// 全局滚动行为：关闭回弹 / 拉伸过界效果，滚动「贴边即止」。
///
/// Material 3 在 Android 上默认带 [StretchingOverscrollIndicator] 的橡皮筋效果，
/// 这里统一改为 Clamping 物理 + 不绘制过界指示器，覆盖所有页面 / 列表。
class NoBounceScrollBehavior extends MaterialScrollBehavior {
  const NoBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}
