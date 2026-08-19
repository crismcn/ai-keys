import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/app_tokens.dart';
import '../../core/design_system/widgets/app_button.dart';
import '../../core/design_system/widgets/stat_card.dart';
import '../../core/design_system/widgets/theme_mode_button.dart';
import '../../core/providers/email_accounts_provider.dart';
import '../import_email/import_email_page.dart';
import 'widgets/email_list_section.dart';

/// APP 首页：统计卡 + 邮箱列表 + 导入入口。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const String route = '/';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  /// 首页登场编排：统计卡先起，列表区稍晚跟进。
  /// 用 AnimationController（可随组件 dispose，测试无残留 Timer）。
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.choreo,
  )..forward();

  int get _total => ref.watch(emailAccountsProvider).length;
  int get _activated => ref.watch(activatedCountProvider);

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final activated = _activated;
    final pending = total - activated;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.max, // 标题占满可用宽，文字可截断，防 130% 溢出
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.brand,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppGlow.of(
                  AppColors.indigo,
                  blur: 10,
                  alpha: 0.4,
                ),
              ),
              child: const Icon(Icons.bolt_rounded, size: 16, color: onNeon),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Flexible(
              child: Text(
                'AI Keys',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const ThemeModeButton(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: AppButton(
                label: '导入邮箱',
                icon: Icons.add_rounded,
                // 描边：一个屏幕一个高反差主操作（「激活」），导入降级。
                variant: AppButtonVariant.outline,
                size: AppButtonSize.sm,
                onPressed: () => context.push(ImportEmailPage.route),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 待激活缺口高亮：让一号动作「激活」可见（Zeigarnik）。
              _FadeRiseIn(
                controller: _entrance,
                start: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: '邮箱数量',
                        value: '$total',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: StatCard(
                        label: pending > 0 ? '待激活' : '已用数量',
                        value: pending > 0 ? '$pending' : '$activated',
                        icon: Icons.bolt_rounded,
                        accent:
                            pending > 0 ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // 邮箱列表
              Expanded(
                child: _FadeRiseIn(
                  controller: _entrance,
                  start: 0.2,
                  child: const EmailListSection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首页登场编排片断：淡入 + 8px 上滑，强调减速。
/// [start] 为进场起点（0 先起，0.2 延迟一段）。
class _FadeRiseIn extends StatelessWidget {
  const _FadeRiseIn({
    required this.controller,
    required this.start,
    required this.child,
  });

  final AnimationController controller;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1.0, curve: AppMotion.enterCurve),
    );
    // 只用 FadeTransition + Transform.translate（纯绘制变换，不动布局，
    // 免去 SlideTransition 在真实路由上下文破坏子树的坑）。
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - anim.value) * AppMotion.riseOffset),
          child: child,
        ),
      ),
    );
  }
}