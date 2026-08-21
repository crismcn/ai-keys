import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';

/// Holds user preferences (theme mode + locale) and persists them.
class SettingsController extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('zh');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Active string table for [locale]. Adding a locale is just a new branch.
  AppStrings get strings =>
      _locale.languageCode == 'en' ? const AppStringsEn() : const AppStrings();

  /// Read the controller without listening — the whole tree is rebuilt by the
  /// [Consumer] wrapping `MaterialApp` when a preference changes.
  static SettingsController of(BuildContext context) =>
      Provider.of<SettingsController>(context, listen: false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _decodeThemeMode(prefs.getString(_themeKey));
    final code = prefs.getString(_localeKey);
    if (code != null && code.isNotEmpty) _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  ThemeMode _decodeThemeMode(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
