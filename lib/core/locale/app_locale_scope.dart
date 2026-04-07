import "package:flutter/material.dart";
import "package:liuban/core/locale/app_locale_controller.dart";

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, "AppLocaleScope not found above this context");
    return scope!.notifier!;
  }
}
