import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/widgets/gradient_backdrop.dart';
import '../../core/providers/theme_mode_provider.dart';
import 'router/router.dart';
import 'theme/app_theme.dart';

/// AI Keys 根组件。
class AiKeysApp extends ConsumerWidget {
  const AiKeysApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'AI Keys',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const NoBounceScrollBehavior(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // 霓虹光斑背景放在整个导航栈最底层，所有页面透明 Scaffold 之上透出。
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          const GradientBackdrop(),
          child ?? const SizedBox.shrink(),
        ],
      ),
      routerConfig: appRouter,
    );
  }
}
