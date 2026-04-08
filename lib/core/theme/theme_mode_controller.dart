import "package:flutter/material.dart";
import "package:liuban/core/persistence/app_persistence.dart";

/// 主題模式（與 [AppPersistence.writeThemeMode] 同步）；測試可傳 `persistence: null` 僅記憶體。
class ThemeModeController extends ChangeNotifier {
  ThemeModeController({AppPersistence? persistence})
    : _persistence = persistence,
      _mode = persistence?.readThemeMode() ?? ThemeMode.system;

  final AppPersistence? _persistence;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode next) async {
    if (_mode == next) return;
    final p = _persistence;
    if (p != null) {
      await p.writeThemeMode(next);
    }
    _mode = next;
    notifyListeners();
  }
}
