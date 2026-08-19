import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// 霓虹光斑背景：基底色 + 几团径向渐变光斑（靛蓝 / 紫 / 青）。
///
/// 挂在 [MaterialApp.builder] 的 Stack 最底层，所有路由（含透明 AppBar / 玻璃卡片）
/// 都在它之上渲染，形成「深空霓虹」/「亮白霓虹」两套底色。
/// 纯静态绘制（无动画），外层包 [RepaintBoundary]，滚动时不会重复绘制。
class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AuroraPainter(
          base: isLight ? AppColors.background : AppColors.backgroundDark,
          blobs: isLight
              ? const [
                  _Blob(AppColors.indigo, 0.10, 0.06, 0.06, 0.55),
                  _Blob(AppColors.violet, 0.08, 0.95, 0.18, 0.5),
                  _Blob(AppColors.cyan, 0.06, 0.72, 0.92, 0.48),
                ]
              : const [
                  _Blob(AppColors.indigo, 0.20, 0.04, 0.02, 0.55),
                  _Blob(AppColors.violet, 0.16, 0.96, 0.20, 0.52),
                  _Blob(AppColors.cyan, 0.10, 0.68, 0.96, 0.5),
                ],
        ),
      ),
    );
  }
}

/// 一团光斑：颜色 / 峰值透明度 / 中心在尺寸上的分数坐标 / 半径分数。
class _Blob {
  const _Blob(this.color, this.alpha, this.cx, this.cy, this.r);

  final Color color;
  final double alpha;
  final double cx;
  final double cy;
  final double r;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.base, required this.blobs});

  final Color base;
  final List<_Blob> blobs;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    for (final b in blobs) {
      final center = Offset(size.width * b.cx, size.height * b.cy);
      final radius = size.longestSide * b.r;
      final shader = RadialGradient(
        colors: [
          b.color.withValues(alpha: b.alpha),
          b.color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, Paint()..shader = shader);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.base != base || !identical(oldDelegate.blobs, blobs);
}
