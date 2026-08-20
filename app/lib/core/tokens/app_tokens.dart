import 'package:flutter/material.dart';

/// Brand colors — identical across light & dark themes.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF3B6EF5);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);

  /// Lighter blue used for completed activation steps (softer than [primary]).
  static const primaryLight = Color.fromARGB(255, 89, 132, 250);

  /// Soft palette for letter avatars (cycled by index / hash) — same in both themes.
  static const avatarPalette = <(Color bg, Color fg)>[
    (Color(0xFFEAF0FF), Color(0xFF3B6EF5)), // blue
    (Color(0xFFE8F8EE), Color(0xFF22C55E)), // green
    (Color(0xFFFFF1E6), Color(0xFFF59E42)), // orange
    (Color(0xFFF3ECFF), Color(0xFF8B5CF6)), // purple
    (Color(0xFFE6FBFA), Color(0xFF14B8A6)), // teal
    (Color(0xFFFFEBF1), Color(0xFFEC4899)), // pink
  ];
}

class AppRadius {
  AppRadius._();
  static const card = 16.0;
  static const button = 12.0;
  static const field = 12.0;
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}
