import 'package:flutter/material.dart';
import 'package:liuban/core/app_container.dart';

class AppContainerScope extends InheritedWidget {
  const AppContainerScope({
    super.key,
    required this.container,
    required super.child,
  });

  final AppContainer container;

  static AppContainer of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppContainerScope>();
    assert(scope != null, 'AppContainerScope 未找到');
    return scope!.container;
  }

  @override
  bool updateShouldNotify(covariant AppContainerScope oldWidget) =>
      oldWidget.container != container;
}
