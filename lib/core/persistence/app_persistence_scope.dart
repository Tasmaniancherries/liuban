import 'package:flutter/material.dart';
import 'package:liuban/core/persistence/app_persistence.dart';

class AppPersistenceScope extends InheritedWidget {
  const AppPersistenceScope({
    super.key,
    required this.persistence,
    required super.child,
  });

  final AppPersistence persistence;

  static AppPersistence of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPersistenceScope>();
    assert(scope != null, 'AppPersistenceScope not found above this context');
    return scope!.persistence;
  }

  /// 測試或獨立畫面未掛載 scope 時為 `null`，廣場分頁會退回預設索引。
  static AppPersistence? maybeOf(BuildContext context) {
    final scope = context.findAncestorWidgetOfExactType<AppPersistenceScope>();
    return scope?.persistence;
  }

  @override
  bool updateShouldNotify(AppPersistenceScope oldWidget) =>
      persistence != oldWidget.persistence;
}
