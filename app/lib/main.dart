import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/app_scroll_behavior.dart';
import 'app/theme/app_theme.dart';
import 'core/settings/settings_controller.dart';
import 'core/state/email_store.dart';
import 'features/shell/home_shell.dart';

/// Optional dev-only HTTP proxy, set via `--dart-define=DEV_PROXY=host:port`.
/// Routes all app HTTP through a local proxy (e.g. Clash at `10.0.2.2:7897`
/// from an emulator) so hosts whose DNS is poisoned on the device network are
/// resolved by the proxy instead. Empty in normal builds → no proxy installed.
const _devProxy = String.fromEnvironment('DEV_PROXY');

class _ProxyHttpOverrides extends HttpOverrides {
  _ProxyHttpOverrides(this.proxy);
  final String proxy;
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..findProxy = (_) => 'PROXY $proxy';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (_devProxy.isNotEmpty) {
    HttpOverrides.global = _ProxyHttpOverrides(_devProxy);
  }
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
            title: 'AI Mails',
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
