import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/locale/app_locale_controller.dart';
import 'package:liuban/core/locale/app_locale_preference.dart';
import 'package:liuban/core/locale/app_locale_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/persistence/app_persistence.dart';
import 'package:liuban/core/theme/theme_mode_controller.dart';
import 'package:liuban/core/theme/theme_mode_scope.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ThrowingLocaleWritePersistence extends AppPersistence {
  _ThrowingLocaleWritePersistence(
    super._prefs,
    super.sessionTokens,
    super.guestDeviceId,
  );

  @override
  Future<void> writeAppLocalePreference(AppLocalePreference preference) async {
    throw StateError('simulated writeAppLocalePreference failure');
  }
}

/// 模擬 [AppLocaleController.setPreference] 非 API 失敗，對應設定頁 catch 與 SnackBar。
class _ThrowingSetPreferenceLocaleController extends AppLocaleController {
  @override
  Future<void> setPreference(AppLocalePreference next) async {
    throw StateError('simulated setPreference failure');
  }
}

Widget _buildHarness(Widget child, {AppLocaleController? localeController}) {
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
        controller: localeController ?? AppLocaleController(),
        child: MaterialApp(home: child),
      ),
    ),
  );
}

void main() {
  test('throwing locale persistence makes setPreference fail', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = AppLocaleController(
      persistence: _ThrowingLocaleWritePersistence(
        prefs,
        AuthSessionTokens(),
        'test-device',
      ),
    );
    expect(controller.preference, AppLocalePreference.system);
    await expectLater(
      controller.setPreference(AppLocalePreference.english),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('locale persist failure shows persistence snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        const SettingsScreen(),
        localeController: _ThrowingSetPreferenceLocaleController(),
      ),
    );

    await tester.tap(find.text('介面語言'));
    await tester.pumpAndSettle();

    // 以路由結果模擬選取 English，避免依賴 ListTile 點擊（widget test 曾無法關閉對話框）。
    Navigator.of(
      tester.element(find.byType(AlertDialog)),
      rootNavigator: true,
    ).pop(AppLocalePreference.english);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(ApiDevSemantics.settingsPersistenceFailedMessage),
      findsOneWidget,
    );
  });

  testWidgets('theme dialog marks current option with check icon', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    await tester.tap(find.text('主題'));
    await tester.pumpAndSettle();

    expect(find.text('外觀'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('locale dialog marks current option with check icon', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    await tester.tap(find.text('介面語言'));
    await tester.pumpAndSettle();

    expect(find.text('介面語言'), findsWidgets);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

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

  testWidgets('about dialog close button dismisses the dialog', (tester) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    await tester.tap(find.text('關於留伴'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutDialog), findsOneWidget);

    final closeLabel = MaterialLocalizations.of(
      tester.element(find.byType(AboutDialog)),
    ).closeButtonLabel;

    await tester.tap(find.text(closeLabel));
    await tester.pumpAndSettle();

    expect(find.byType(AboutDialog), findsNothing);
  });

  testWidgets('legal dialog close button dismisses the dialog', (tester) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    await tester.tap(find.text('用戶協議與隱私'));
    await tester.pumpAndSettle();
    expect(find.text(ApiDevSemantics.settingsLegalPlaceholder), findsOneWidget);

    await tester.tap(find.text('關閉'));
    await tester.pumpAndSettle();
    expect(find.text(ApiDevSemantics.settingsLegalPlaceholder), findsNothing);
  });

  testWidgets('opens open-source licenses page from settings', (tester) async {
    await tester.pumpWidget(_buildHarness(const SettingsScreen()));

    final licenseTile = find.widgetWithText(ListTile, '開源許可');
    await tester.ensureVisible(licenseTile);
    await tester.pumpAndSettle();
    await tester.tap(licenseTile);
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
