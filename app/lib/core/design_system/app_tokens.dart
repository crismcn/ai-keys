import 'package:flutter/material.dart';

/// 霓虹玻璃（Neon Glass）设计 token —— Flutter UI Challenge / UI Kit 风格。
///
/// 设计语言：
/// - 深空 / 亮白基底上漂浮霓虹渐变光斑（靛蓝 / 紫 / 青），见 [GradientBackdrop]；
/// - 半透明玻璃卡片（明暗两套，白 @ 一定透明度 + 细亮边）；
/// - 品牌渐变（靛蓝 → 紫）用于主按钮 / 头像 / 步骤高亮；
/// - 辉光阴影（带色 blur）代替纯黑投影；
/// - 大圆角。
///
/// 命名保持与旧 shadcn 版一致，方便业务代码直接切换视觉语言。
abstract final class AppColors {
  AppColors._();

  // ---- 霓虹色相（明暗共享）----
  static const Color indigo = Color(0xFF6366F1);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color pink = Color(0xFFEC4899);
  static const Color emerald = Color(0xFF10B981);
  static const Color teal = Color(0xFF14B8A6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color rose = Color(0xFFF43F5E);

  /// 品牌主色（纯色，用于文字 / 图标 / 进度圈）。
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF8B98F8);

  /// 品牌渐变（靛蓝 → 紫）。
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violet],
  );

  /// 成功渐变（翠绿 → 青）。
  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald, teal],
  );

  /// 危险渐变（红 → 玫瑰）。
  static const LinearGradient destructiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, rose],
  );

  /// 主色柔和底（图标 / 头像 / 强调底色）。
  static const Color primarySoft = Color(0x146B6BF8);

  // ---- 背景基底（配合光斑，见 GradientBackdrop）----
  static const Color background = Color(0xFFF5F6FF);
  static const Color backgroundDark = Color(0xFF070B16);

  // ---- 前景 ----
  static const Color foreground = Color(0xFF191D33);
  static const Color foregroundDark = Color(0xFFF2F4FB);
  static const Color mutedForeground = Color(0xFF5D6584);
  static const Color mutedForegroundDark = Color(0xFF97A1BF);

  // ---- 玻璃卡片（扁平：纯色填充 + 大圆角，无边框线）----
  static const Color card = Color(0xF2FFFFFF); // 白 95%（浅色玻璃）
  static const Color cardDark = Color(0x14FFFFFF); // 白 8%（深色玻璃）
  static const Color border = Color(0xFFE9EBFA); // 浅色卡细边（备用）
  static const Color borderDark = Color(0x26FFFFFF); // 白 15%

  // ---- 中性底（标签 / 输入框 / 占位）----
  static const Color muted = Color(0xFFEFF0FB);
  static const Color mutedDark = Color(0x0DFFFFFF);

  // ---- 语义色 ----
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);
  static const Color successSoft = Color(0x1F10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveSoft = Color(0x1FEF4444);

  /// 渐变上的文字颜色（白）。
  static const Color onNeon = Color(0xFFFFFFFF);
}

/// 间距刻度。
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// 圆角刻度（霓虹玻璃走大圆角）。
class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 26;
  static const double pill = 999;
}

/// 辉光阴影：带色 blur，替代纯黑投影。
abstract final class AppGlow {
  AppGlow._();

  static List<BoxShadow> of(
    Color color, {
    double blur = 16,
    double alpha = 0.35,
    Offset offset = Offset.zero,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: blur,
          offset: offset,
        ),
      ];
}

/// 阴影（兼容旧引用；新代码优先用 [AppGlow]）。
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x148B5CF6), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1F6366F1), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

/// 动效 token —— Smooth & Premium。
/// 单点定义时长/曲线/位移，禁止在业务代码散落动画魔数。
abstract final class AppMotion {
  AppMotion._();

  // ---- 时长 ----
  /// 按压反馈、小块状态变化（120ms）。
  static const Duration press = Duration(milliseconds: 120);

  /// 就地 UI 过渡（≤300ms 上限内的常用档）。
  static const Duration base = Duration(milliseconds: 250);

  /// 容器/页面进入。
  static const Duration enter = Duration(milliseconds: 320);

  /// 退出（进入的 ~60%，更快）。
  static const Duration exit = Duration(milliseconds: 200);

  /// 首页入口编排总时长上限。
  static const Duration choreo = Duration(milliseconds: 500);

  // ---- 曲线 ----
  /// 元素进入：强调减速（起手快，响应感强）。
  static const Curve enterCurve = Easing.emphasizedDecelerate;

  /// 元素退出：强调加速。
  static const Curve exitCurve = Easing.emphasizedAccelerate;

  /// 屏内状态/形态变化（轴向运动用 emo 衰减后就够）。
  static const Curve onScreenCurve = Curves.easeInOutCubicEmphasized;

  /// 按压回弹。
  static const Curve pressCurve = Curves.easeOut;

  // ---- 位移 ----
  /// 组件级进场从下往上滑的距离。
  static const double riseOffset = 8;

  /// 按压缩放比（0.97）。
  static const double pressScale = 0.97;

  /// 页面转场纵向位移（百分比）。
  static const double pageSlide = 0.012;
}

/// 渐变上的文字颜色语义名（替代散落的内联 Colors.white）。
/// 放在文件末尾便于 grep；内容即 [AppColors.onNeon]。
const Color onNeon = Color(0xFFFFFFFF);
