import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';

/// Light & dark themes mapped from light.png / dark.png. Semantic colors are
/// carried by the [AppPalette] theme extension (read via `context.c`).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      surface: palette.surface,
      error: AppColors.danger,
    );

    return base.copyWith(
      scaffoldBackgroundColor: palette.bg,
      canvasColor: palette.surface,
      colorScheme: scheme,
      splashFactory: InkRipple.splashFactory,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: palette.textPrimary,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.surface),
      textTheme: base.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      dividerColor: palette.border,
    );
  }
}
