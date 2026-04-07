import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:liuban/core/theme/theme_mode_controller.dart";

void main() {
  test("ThemeModeController without persistence updates mode", () async {
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
}
