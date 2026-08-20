import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/app_scroll_behavior.dart';
import 'app/theme/app_theme.dart';
import 'core/settings/settings_controller.dart';
import 'core/state/email_store.dart';
import 'features/shell/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AiKeysApp());
}

class AiKeysApp extends StatelessWidget {
  const AiKeysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmailStore()..load()),
        ChangeNotifierProvider(create: (_) => SettingsController()..load()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'AI Keys',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            locale: settings.locale,
            scrollBehavior: const AppScrollBehavior(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh'), Locale('en')],
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
