import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// 激活步骤条：霓虹渐变编号圆点 + 渐变连接线 + 标签。
/// [currentStep] 为正在运行的步骤下标；小于它的为已完成，大于它的为待执行。
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.labels,
    required this.currentStep,
  });

  final List<String> labels;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final border = isLight ? AppColors.border : AppColors.borderDark;
    final fg = isLight ? AppColors.foreground : AppColors.foregroundDark;
    final mutedFg =
        isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;

    final children = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) {
        final done = i <= currentStep; // 连接线是否已走完
        children.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                gradient: done ? AppColors.brand : null,
                color: done ? null : border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        );
      }
      children.add(_StepNode(
        index: i,
        label: labels[i],
        state: i < currentStep
            ? _StepState.done
            : i == currentStep
                ? _StepState.running
                : _StepState.pending,
        border: border,
        fg: fg,
        mutedFg: mutedFg,
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

enum _StepState { done, running, pending }

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.state,
    required this.border,
    required this.fg,
    required this.mutedFg,
  });

  final int index;
  final String label;
  final _StepState state;
  final Color border;
  final Color fg;
  final Color mutedFg;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final running = state == _StepState.running;

    final Widget circle;
    switch (state) {
      case _StepState.done:
      case _StepState.running:
        // 已完成 / 进行中：品牌渐变圆 + 辉光。
        circle = Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.brand,
            shape: BoxShape.circle,
            boxShadow: AppGlow.of(
              AppColors.indigo,
              blur: 12,
              alpha: isLight ? 0.35 : 0.5,
            ),
          ),
          child: running
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onNeon,
                  ),
                )
              : const Center(
                  child: Icon(Icons.check_rounded, size: 16, color: AppColors.onNeon),
                ),
        );
      case _StepState.pending:
        circle = Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isLight ? AppColors.muted : AppColors.mutedDark,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: mutedFg,
              ),
            ),
          ),
        );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: 56,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 11,
              height: 1.3,
              fontWeight: state == _StepState.pending ? FontWeight.w400 : FontWeight.w600,
              color: state == _StepState.pending ? mutedFg : fg,
            ),
          ),
        ),
      ],
    );
  }
}
