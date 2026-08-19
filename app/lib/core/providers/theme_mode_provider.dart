import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式偏好（跟随系统 / 浅色 / 深色），持久化到本地。
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  ThemeModeController({this.initial = ThemeMode.system});

  /// 启动时的初始模式（main 里从本地读取后注入）。
  final ThemeMode initial;

  static const _key = 'theme_mode';

  @override
  ThemeMode build() => initial;

  void set(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
    unawaited(_persist(mode));
  }

  static Future<void> _persist(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// 读取本地保存的主题模式（启动时恢复，缺省跟随系统）。
  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}