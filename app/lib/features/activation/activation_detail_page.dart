import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/app_tokens.dart';
import '../../core/design_system/widgets/app_button.dart';
import '../../core/design_system/widgets/app_card.dart';
import '../../core/design_system/widgets/status_badge.dart';
import '../../core/design_system/widgets/step_indicator.dart';
import '../../core/providers/email_accounts_provider.dart';

/// 激活详情页。
///
/// 进入即自动开始激活，用步骤条展示当前所处阶段，无需人工干预。
///
/// TODO(逻辑接入)：当前进度为本地模拟（定时器逐步骤推进）；
/// 真实逻辑接入后端 HTTP 控制层（发送验证码 → 收取验证码 → 脚本注册 → 激活认证），
/// 页面结构与状态机保持不变，只需替换数据来源。
class ActivationDetailPage extends ConsumerStatefulWidget {
  const ActivationDetailPage({super.key, required this.email});

  final String email;

  static const String route = '/activation/:email';
  static String pathOf(String email) => '/activation/$email';

  @override
  ConsumerState<ActivationDetailPage> createState() =>
      _ActivationDetailPageState();
}

class _ActivationStep {
  const _ActivationStep(this.label, this.description);

  final String label;
  final String description;
}

class _ActivationDetailPageState
    extends ConsumerState<ActivationDetailPage> {
  static const List<_ActivationStep> _steps = [
    _ActivationStep('发送验证码', '向邮箱发送 6 位验证码'),
    _ActivationStep('收取验证码', '轮询收件箱并提取验证码'),
    _ActivationStep('脚本注册', '提交账号完成注册'),
    _ActivationStep('激活认证', '点击认证链接完成激活'),
  ];

  /// 正在执行的步骤下标；等于 _steps.length 表示全部完成。
  int _currentStep = 0;
  bool _finished = false;
  Timer? _timer;
  final List<({int step, DateTime time})> _logs = [];

  @override
  void initState() {
    super.initState();
    _simulate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 模拟激活流程：每 1.6s 推进一个步骤。
  /// TODO(逻辑接入)：替换为真实激活流程的异步状态流。
  void _simulate() {
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      setState(() {
        _logs.add((step: _currentStep, time: DateTime.now()));
        _currentStep++;
        if (_currentStep >= _steps.length) {
          _finished = true;
          timer.cancel();
          // 完成时刻：轻触感 = 完成确认（≤300ms，调低音量）。
          HapticFeedback.mediumImpact();
          // 激活成功后标记为可用（首页绿点区分）。
          ref.read(emailAccountsProvider.notifier).markActivated(widget.email);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(emailAccountsProvider);
    final account =
        accounts.where((e) => e.email == widget.email).firstOrNull;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = isLight ? AppColors.foreground : AppColors.foregroundDark;
    final mutedFg = isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;

    return Scaffold(
      appBar: AppBar(title: const Text('激活详情')),
      body: SafeArea(
        child: account == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '未找到该账号',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _accountHeader(context, account.account, account.activated),
                  const SizedBox(height: AppSpacing.md),
                  // 步骤条
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '激活进度',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: fg,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? AppColors.warning.withValues(alpha: 0.12)
                                    : AppColors.warning.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: const Text(
                                '模拟',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        StepIndicator(
                          labels: [for (final s in _steps) s.label],
                          currentStep: _finished ? _steps.length : _currentStep,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // 当前步骤描述
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _finished
                              ? Row(
                                  key: const ValueKey('done'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Text(
                                      '全部步骤已完成',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  key: ValueKey('step-$_currentStep'),
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        '${_steps[_currentStep].label} · ${_steps[_currentStep].description}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: fg,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 日志时间线
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.xs,
                          ),
                          child: Text(
                            '运行日志',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (_logs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              '等待开始…',
                              style: TextStyle(fontSize: 13, color: mutedFg),
                            ),
                          )
                        else
                          for (final log in _logs)
                            _LogRow(
                              step: log.step,
                              label: _steps[log.step].label,
                              time: log.time,
                            ),
                      ],
                    ),
                  ),
                  // 完成操作
                  if (_finished) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      color: isLight
                          ? AppColors.successSoft
                          : AppColors.success.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 20,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '激活成功，该账号已标记为可用',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: '返回首页',
                      icon: Icons.arrow_back_rounded,
                      expand: true,
                      onPressed: () => context.go('/'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// 账号信息头卡。
  Widget _accountHeader(BuildContext context, String account, bool activated) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedFg = isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: activated
                  ? AppColors.emeraldGradient
                  : AppColors.brand,
              shape: BoxShape.circle,
              boxShadow: AppGlow.of(
                activated ? AppColors.success : AppColors.indigo,
                blur: 12,
                alpha: isLight ? 0.35 : 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              account.isEmpty ? '?' : account[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isLight ? AppColors.foreground : AppColors.foregroundDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.email,
                  style: TextStyle(fontSize: 12, color: mutedFg),
                ),
              ],
            ),
          ),
          if (activated)
            const StatusBadge.available()
          else
            const StatusBadge.pending(),
        ],
      ),
    );
  }
}

/// 日志行：步骤名 + 时间 + 完成标记。
class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.step,
    required this.label,
    required this.time,
  });

  final int step;
  final String label;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedFg = isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;
    final fg = isLight ? AppColors.foreground : AppColors.foregroundDark;

    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: step == 3 ? AppColors.success : AppColors.success.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '步骤 ${step + 1} · $label',
              style: TextStyle(fontSize: 13, color: fg),
            ),
          ),
          Text(
            '$hh:$mm:$ss',
            style: TextStyle(
              fontSize: 11,
              color: mutedFg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
