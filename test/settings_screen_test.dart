import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/locale/app_locale_controller.dart';
import 'package:liuban/core/locale/app_locale_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/theme/theme_mode_controller.dart';
import 'package:liuban/core/theme/theme_mode_scope.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/features/settings/settings_screen.dart';

Widget _buildHarness(Widget child) {
  final container = AppContainer(
    guestDeviceId: 'test-device',
    logHttpTraffic: false,
    baseUrl: 'https://example.invalid',
    sessionTokens: AuthSessionTokens(),
  );
  return AppContainerScope(
    container: container,
    child: ThemeModeScope(
      controller: ThemeModeController(),
      child: AppLocaleScope(
        controller: AppLocaleController(),
        child: MaterialApp(home: child),
      ),
    ),
  );
}

void main() {
  testWidgets('changes theme mode from dialog and updates subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    await tester.tap(find.text('主題'));
    await tester.pumpAndSettle();
    expect(find.text('外觀'), findsOneWidget);

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    expect(find.text('深色'), findsOneWidget);
  });

  testWidgets('changes locale from dialog and updates subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    await tester.tap(find.text('介面語言'));
    await tester.pumpAndSettle();
    expect(find.text('介面語言'), findsWidgets);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('opens legal dialog and shows placeholder text', (tester) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    await tester.tap(find.text('用戶協議與隱私'));
    await tester.pumpAndSettle();

    expect(find.text('用戶協議與隱私'), findsWidgets);
    expect(find.text(ApiDevSemantics.settingsLegalPlaceholder), findsOneWidget);
  });

  testWidgets('opens about dialog and shows app version', (tester) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    await tester.tap(find.text('關於留伴'));
    await tester.pumpAndSettle();

    expect(find.text('留伴'), findsOneWidget);
    expect(find.text('版本 ${AppConfig.appVersion}'), findsWidgets);
  });
}
