import 'package:flutter/material.dart';

/// Theme-dependent semantic colors. Registered as a [ThemeExtension] on both
/// the light and dark [ThemeData] and read via `context.c`.
///
/// Brand colors (primary / success / danger) are constant across themes and
/// live in [AppColors]; only surfaces, text, borders and tints vary here.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.primarySoft,
    required this.successSoft,
    required this.neutral,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.cardShadow,
  });

  final Color bg;
  final Color surface;
  final Color primarySoft;
  final Color successSoft;
  final Color neutral;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final List<BoxShadow> cardShadow;

  /// Light palette — mapped from light.png.
  static const light = AppPalette(
    bg: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFEAF0FF),
    successSoft: Color(0xFFE8F8EE),
    neutral: Color(0xFF9CA3AF),
    textPrimary: Color(0xFF1F2430),
    textSecondary: Color(0xFF8A90A0),
    border: Color(0xFFEAECEF),
    cardShadow: [
      BoxShadow(
        color: Color(0x0F1B2A4E),
        blurRadius: 24,
        offset: Offset(0, 10),
        spreadRadius: -8,
      ),
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 4,
        offset: Offset(0, 2),
        spreadRadius: -2,
      ),
    ],
  );

  /// Dark palette — mapped from dark.png.
  static const dark = AppPalette(
    bg: Color(0xFF0C0E12),
    surface: Color(0xFF181B21),
    primarySoft: Color(0xFF1C2740),
    successSoft: Color(0xFF12301E),
    neutral: Color(0xFF6E7480),
    textPrimary: Color(0xFFEDEFF3),
    textSecondary: Color(0xFF9096A2),
    border: Color(0xFF262A31),
    cardShadow: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 18,
        offset: Offset(0, 8),
        spreadRadius: -6,
      ),
    ],
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? primarySoft,
    Color? successSoft,
    Color? neutral,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    List<BoxShadow>? cardShadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      primarySoft: primarySoft ?? this.primarySoft,
      successSoft: successSoft ?? this.successSoft,
      neutral: neutral ?? this.neutral,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

/// Convenient access to the active [AppPalette]: `context.c.surface`.
extension AppPaletteX on BuildContext {
  AppPalette get c => Theme.of(this).extension<AppPalette>()!;
}
