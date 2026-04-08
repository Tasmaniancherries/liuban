import "dart:math";

import "package:flutter/material.dart";
import "package:liuban/core/locale/app_locale_preference.dart";
import "package:liuban/core/network/auth_session_tokens.dart";
import "package:shared_preferences/shared_preferences.dart";

/// 啟動時還原 token、並配置穩定的訪客裝置 ID（供客服與風控）。
class AppPersistence {
  AppPersistence(this._prefs, this.sessionTokens, this.guestDeviceId);

  final SharedPreferences _prefs;
  final AuthSessionTokens sessionTokens;
  final String guestDeviceId;

  static const _kAccessToken = "liuban_access_token";
  static const _kRefreshToken = "liuban_refresh_token";
  static const _kGuestDevice = "liuban_guest_device_id";
  static const _kThemeMode = "liuban_theme_mode";
  static const _kAppLocale = "liuban_app_locale";
  static const _kFeedTabIndex = "liuban_feed_tab_index";
  static const _kMessagesTabIndex = "liuban_messages_tab_index";

  static Future<AppPersistence> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_kAccessToken);
    final refresh = prefs.getString(_kRefreshToken);
    final sessionTokens = AuthSessionTokens(
      accessToken: access,
      refreshToken: refresh,
    );

    var guest = prefs.getString(_kGuestDevice);
    if (guest == null || guest.isEmpty) {
      guest =
          "g_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 24)}";
      await prefs.setString(_kGuestDevice, guest);
    }

    return AppPersistence(prefs, sessionTokens, guest);
  }

  Future<void> persistSessionTokens() async {
    final a = sessionTokens.accessToken;
    final r = sessionTokens.refreshToken;
    if (a == null || a.isEmpty) {
      await _prefs.remove(_kAccessToken);
    } else {
      await _prefs.setString(_kAccessToken, a);
    }
    if (r == null || r.isEmpty) {
      await _prefs.remove(_kRefreshToken);
    } else {
      await _prefs.setString(_kRefreshToken, r);
    }
  }

  ThemeMode readThemeMode() {
    final s = _prefs.getString(_kThemeMode);
    return switch (s) {
      "dark" => ThemeMode.dark,
      "light" => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    final v = switch (mode) {
      ThemeMode.dark => "dark",
      ThemeMode.light => "light",
      ThemeMode.system => "system",
    };
    await _prefs.setString(_kThemeMode, v);
  }

  /// 未寫入過時為 [AppLocalePreference.system]（跟隨系統）。
  AppLocalePreference readAppLocalePreference() {
    return AppLocalePreference.parseStored(_prefs.getString(_kAppLocale));
  }

  Future<void> writeAppLocalePreference(AppLocalePreference preference) async {
    await _prefs.setString(_kAppLocale, preference.persistenceKey);
  }

  /// 廣場 [TabController] 索引，範圍 `0..2`（公開／本校／好友）。
  int readFeedTabIndex() {
    final v = _prefs.getInt(_kFeedTabIndex);
    if (v == null) return 0;
    return v.clamp(0, 2);
  }

  Future<void> writeFeedTabIndex(int index) async {
    await _prefs.setInt(_kFeedTabIndex, index.clamp(0, 2));
  }

  /// 訊息頁 [DefaultTabController] 索引，範圍 `0..1`（官方客服／好友）。
  int readMessagesTabIndex() {
    final v = _prefs.getInt(_kMessagesTabIndex);
    if (v == null) return 0;
    return v.clamp(0, 1);
  }

  Future<void> writeMessagesTabIndex(int index) async {
    await _prefs.setInt(_kMessagesTabIndex, index.clamp(0, 1));
  }
}
