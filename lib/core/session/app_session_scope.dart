import 'package:flutter/material.dart';
import 'package:liuban/core/session/app_session.dart';

class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    super.key,
    required AppSession super.notifier,
    required super.child,
  });

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    assert(scope != null, 'AppSessionScope not found');
    return scope!.notifier!;
  }
}
