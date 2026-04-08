import 'package:flutter/material.dart';
import 'package:liuban/core/locale/app_locale_preference.dart';
import 'package:liuban/core/persistence/app_persistence.dart';

/// 介面語言（與 [AppPersistence.writeAppLocalePreference] 同步）；測試可傳 `persistence: null` 僅記憶體。
class AppLocaleController extends ChangeNotifier {
  AppLocaleController({AppPersistence? persistence})
    : _persistence = persistence,
      _preference =
          persistence?.readAppLocalePreference() ?? AppLocalePreference.system;

  final AppPersistence? _persistence;
  AppLocalePreference _preference;

  AppLocalePreference get preference => _preference;

  /// 傳給 [MaterialApp.locale]；為 `null` 時跟隨系統。
  Locale? get resolvedLocale => _preference.materialLocale;

  Future<void> setPreference(AppLocalePreference next) async {
    if (_preference == next) return;
    final p = _persistence;
    if (p != null) {
      await p.writeAppLocalePreference(next);
    }
    _preference = next;
    notifyListeners();
  }
}
