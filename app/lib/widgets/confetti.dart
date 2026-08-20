import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/tokens/app_tokens.dart';

/// A celebratory confetti burst that sprays from the two lower sides toward
/// the upper center, then falls back down under gravity. Colors are drawn from
/// the app's blue-forward theme. Drop it inside a [Stack] via
/// `Positioned.fill(child: ConfettiOverlay())`; it self-manages its animation
/// and fires as soon as it is inserted.
///
/// Used on both the activation-success and import-success screens so the
/// celebration looks identical across the app.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: ConfettiPainter(_controller.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Paints a two-sided confetti burst. [t] runs 0→1 over the animation.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter(this.t) : _particles = _buildParticles();

  final double t;
  final List<_ConfettiParticle> _particles;

  static const _colors = [
    AppColors.primary,
    AppColors.primaryLight,
    Color(0xFFA9C4FF), // pale blue
    AppColors.success,
    Color(0xFF8B5CF6), // purple accent
    Color(0xFF14B8A6), // teal accent
  ];

  static List<_ConfettiParticle> _buildParticles() {
    final rnd = math.Random(7);
    return List.generate(96, (i) {
      return _ConfettiParticle(
        // Alternate launch side: half spray from the left, half from the right.
        fromLeft: i.isEven,
        // Staggered emission over the first ~55% so it reads as a sustained
        // stream rather than one rigid, synchronized pop.
        delay: rnd.nextDouble() * 0.55,
        vx: 0.42 + rnd.nextDouble() * 0.4, // inward reach toward center
        vy0: 1.0 + rnd.nextDouble() * 0.5, // upward launch strength
        gravity: 1.3 + rnd.nextDouble() * 0.6, // pull back down
        // Launch from the two sides at roughly the lower-middle (2/5 up from
        // the bottom ≈ 0.6 of the height), spraying upward.
        originY: 0.56 + rnd.nextDouble() * 0.08,
        sway: 5 + rnd.nextDouble() * 14,
        color: _colors[i % _colors.length],
        w: 5 + rnd.nextDouble() * 5,
        h: 8 + rnd.nextDouble() * 8,
        spin: (rnd.nextDouble() - 0.5) * 14,
        wobble: rnd.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final progress = t.clamp(0.0, 1.0);
    if (progress == 0) return;

    for (final p in _particles) {
      // Each particle runs its own launch→arc→fall life, offset by its delay.
      final lt = (progress - p.delay) / (1 - p.delay);
      if (lt <= 0) continue;
      final l = lt.clamp(0.0, 1.0);

      final dir = p.fromLeft ? 1.0 : -1.0;
      final originX = p.fromLeft ? size.width * 0.03 : size.width * 0.97;
      final originY = size.height * p.originY;

      // Projectile motion: rises toward the upper center, then gravity wins.
      final x = originX +
          dir * size.width * p.vx * l +
          math.sin(p.wobble + l * 8) * p.sway;
      final y = originY - size.height * p.vy0 * l + size.height * p.gravity * l * l;

      // Quick fade-in on launch, gentle fade-out as the particle dies.
      final fadeIn = (l / 0.06).clamp(0.0, 1.0);
      final fadeOut = l > 0.75 ? (1 - (l - 0.75) / 0.25).clamp(0.0, 1.0) : 1.0;
      final opacity = fadeIn * fadeOut;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.wobble + p.spin * l);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter old) => old.t != t;
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.fromLeft,
    required this.delay,
    required this.vx,
    required this.vy0,
    required this.gravity,
    required this.originY,
    required this.sway,
    required this.color,
    required this.w,
    required this.h,
    required this.spin,
    required this.wobble,
  });

  final bool fromLeft;
  final double delay;
  final double vx;
  final double vy0;
  final double gravity;
  final double originY;
  final double sway;
  final Color color;
  final double w;
  final double h;
  final double spin;
  final double wobble;
}
