import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/persistence/app_persistence.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('initialize restores session tokens and existing guest id', () async {
    SharedPreferences.setMockInitialValues({
      'liuban_access_token': 'acc',
      'liuban_refresh_token': 'ref',
      'liuban_guest_device_id': 'guest_123',
    });

    final persistence = await AppPersistence.initialize();

    expect(persistence.sessionTokens.accessToken, 'acc');
    expect(persistence.sessionTokens.refreshToken, 'ref');
    expect(persistence.guestDeviceId, 'guest_123');
  });

  test('initialize creates guest id when absent and persists it', () async {
    SharedPreferences.setMockInitialValues({});

    final persistence = await AppPersistence.initialize();
    final prefs = await SharedPreferences.getInstance();
    final persistedGuest = prefs.getString('liuban_guest_device_id');

    expect(persistence.guestDeviceId, isNotEmpty);
    expect(persistence.guestDeviceId, startsWith('g_'));
    expect(persistedGuest, persistence.guestDeviceId);
  });

  test('initialize regenerates guest id when stored value is empty', () async {
    SharedPreferences.setMockInitialValues({'liuban_guest_device_id': ''});

    final persistence = await AppPersistence.initialize();
    final prefs = await SharedPreferences.getInstance();
    final persistedGuest = prefs.getString('liuban_guest_device_id');

    expect(persistence.guestDeviceId, isNotEmpty);
    expect(persistence.guestDeviceId, startsWith('g_'));
    expect(persistedGuest, persistence.guestDeviceId);
  });

  test('persistSessionTokens writes and clears token keys correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = AuthSessionTokens(accessToken: 'a1', refreshToken: 'r1');
    final persistence = AppPersistence(prefs, tokens, 'guest');

    await persistence.persistSessionTokens();
    expect(prefs.getString('liuban_access_token'), 'a1');
    expect(prefs.getString('liuban_refresh_token'), 'r1');

    tokens.clear();
    await persistence.persistSessionTokens();
    expect(prefs.getString('liuban_access_token'), isNull);
    expect(prefs.getString('liuban_refresh_token'), isNull);
  });

  test('persistSessionTokens removes keys for empty token strings', () async {
    SharedPreferences.setMockInitialValues({
      'liuban_access_token': 'old_a',
      'liuban_refresh_token': 'old_r',
    });
    final prefs = await SharedPreferences.getInstance();
    final tokens = AuthSessionTokens(accessToken: '', refreshToken: '');
    final persistence = AppPersistence(prefs, tokens, 'guest');

    await persistence.persistSessionTokens();

    expect(prefs.getString('liuban_access_token'), isNull);
    expect(prefs.getString('liuban_refresh_token'), isNull);
  });

  test('readThemeMode defaults to system for unknown/missing value', () async {
    SharedPreferences.setMockInitialValues({});
    var prefs = await SharedPreferences.getInstance();
    var persistence = AppPersistence(prefs, AuthSessionTokens(), 'guest');
    expect(persistence.readThemeMode(), ThemeMode.system);

    SharedPreferences.setMockInitialValues({'liuban_theme_mode': 'weird'});
    prefs = await SharedPreferences.getInstance();
    persistence = AppPersistence(prefs, AuthSessionTokens(), 'guest');
    expect(persistence.readThemeMode(), ThemeMode.system);
  });

  test('writeThemeMode and readThemeMode round-trip all enum values', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = AppPersistence(prefs, AuthSessionTokens(), 'guest');

    await persistence.writeThemeMode(ThemeMode.dark);
    expect(persistence.readThemeMode(), ThemeMode.dark);
    expect(prefs.getString('liuban_theme_mode'), 'dark');

    await persistence.writeThemeMode(ThemeMode.light);
    expect(persistence.readThemeMode(), ThemeMode.light);
    expect(prefs.getString('liuban_theme_mode'), 'light');

    await persistence.writeThemeMode(ThemeMode.system);
    expect(persistence.readThemeMode(), ThemeMode.system);
    expect(prefs.getString('liuban_theme_mode'), 'system');
  });
}
