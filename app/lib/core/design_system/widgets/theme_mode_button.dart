import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_mode_provider.dart';
import '../app_tokens.dart';

/// 主题切换按钮：AppBar 图标 + 弹出三选菜单（跟随系统 / 浅色 / 深色）。
/// 图标随当前模式变化：自动 / 太阳 / 月亮；菜单当前项带勾选标记。
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedFg =
        isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;

    final icon = switch (current) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };

    return PopupMenuButton<ThemeMode>(
      tooltip: '切换主题',
      icon: Icon(icon, size: 20, color: mutedFg),
      initialValue: current,
      onSelected: (mode) => ref.read(themeModeProvider.notifier).set(mode),
      itemBuilder: (menuContext) => [
        _item(menuContext, Icons.brightness_auto_rounded, '跟随系统',
            ThemeMode.system, current),
        _item(menuContext, Icons.light_mode_rounded, '浅色', ThemeMode.light,
            current),
        _item(menuContext, Icons.dark_mode_rounded, '深色', ThemeMode.dark,
            current),
      ],
    );
  }

  PopupMenuEntry<ThemeMode> _item(
    BuildContext context,
    IconData icon,
    String label,
    ThemeMode mode,
    ThemeMode current,
  ) {
    final mutedFg = Theme.of(context).brightness == Brightness.light
        ? AppColors.mutedForeground
        : AppColors.mutedForegroundDark;
    final primary = Theme.of(context).brightness == Brightness.light
        ? AppColors.primary
        : AppColors.primaryDark;

    return PopupMenuItem<ThemeMode>(
      value: mode,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: mutedFg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          if (mode == current)
            Icon(Icons.check_rounded, size: 18, color: primary),
        ],
      ),
    );
  }
}