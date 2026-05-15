import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/persistence/app_persistence.dart';
import 'package:liuban/core/theme/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppPersistence> _buildPersistenceWithTheme(String? themeValue) async {
  SharedPreferences.setMockInitialValues({'liuban_theme_mode': ?themeValue});
  final prefs = await SharedPreferences.getInstance();
  return AppPersistence(prefs, AuthSessionTokens(), 'guest');
}

void main() {
  test('ThemeModeController without persistence updates mode', () async {
    final c = ThemeModeController();
    expect(c.mode, ThemeMode.system);
    var notifications = 0;
    c.addListener(() => notifications++);
    await c.setMode(ThemeMode.dark);
    expect(c.mode, ThemeMode.dark);
    expect(notifications, 1);
    await c.setMode(ThemeMode.dark);
    expect(notifications, 1);
    await c.setMode(ThemeMode.light);
    expect(c.mode, ThemeMode.light);
    expect(notifications, 2);
  });

  test('ThemeModeController reads initial mode from persistence', () async {
    final persistence = await _buildPersistenceWithTheme('dark');
    final c = ThemeModeController(persistence: persistence);
    expect(c.mode, ThemeMode.dark);
  });

  test('ThemeModeController writes next mode to persistence', () async {
    final persistence = await _buildPersistenceWithTheme('system');
    final c = ThemeModeController(persistence: persistence);
    expect(c.mode, ThemeMode.system);

    await c.setMode(ThemeMode.light);

    expect(c.mode, ThemeMode.light);
    expect(persistence.readThemeMode(), ThemeMode.light);
  });
}
