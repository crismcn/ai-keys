import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 启动时恢复上次选择的主题模式（缺省跟随系统）。
  final savedThemeMode = await ThemeModeController.load();
  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeController(initial: savedThemeMode),
        ),
      ],
      child: const AiKeysApp(),
    ),
  );
}