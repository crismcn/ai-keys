import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_palette.dart';
import '../core/tokens/app_tokens.dart';

/// Circular letter avatar; background/foreground cycled by index or name hash.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({
    super.key,
    required this.name,
    required this.letter,
    this.size = 40,
    this.colorIndex,
  });

  final String name;
  final String letter;
  final double size;

  /// When set, picks the palette by position instead of name hash — keeps the
  /// list colours stable and matching the design mockup (blue, green, …).
  final int? colorIndex;

  @override
  Widget build(BuildContext context) {
    final idx = colorIndex ?? name.hashCode.abs();
    final palette = AppColors.avatarPalette[idx % AppColors.avatarPalette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.$1,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: palette.$2,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Colored status dot + label (green = 可用 / grey = 未激活).
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.activated});

  final bool activated;

  @override
  Widget build(BuildContext context) {
    final color = activated ? AppColors.success : context.c.neutral;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          activated ? context.s.statusAvailable : context.s.statusInactive,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
