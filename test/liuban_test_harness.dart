import "package:flutter/material.dart";
import "package:liuban/app/liuban_app.dart";
import "package:liuban/core/app_container.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/locale/app_locale_controller.dart";
import "package:liuban/core/locale/app_locale_scope.dart";
import "package:liuban/core/persistence/app_persistence.dart";
import "package:liuban/core/persistence/app_persistence_scope.dart";
import "package:liuban/core/session/app_session.dart";
import "package:liuban/core/session/app_session_scope.dart";
import "package:liuban/core/theme/theme_mode_controller.dart";
import "package:liuban/core/theme/theme_mode_scope.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

/// 建立用於 widget 測試的留伴 app 樹（預設 baseUrl 無效，不打出真實流量）。
Future<Widget> liubanAppTestWidget({TextScaler? textScaler}) async {
  SharedPreferences.setMockInitialValues({});
  final persistence = await AppPersistence.initialize();
  final session = AppSession();
  final container = AppContainer(
    sessionTokens: persistence.sessionTokens,
    guestDeviceId: persistence.guestDeviceId,
    baseUrl: "https://example.invalid",
    logHttpTraffic: false,
  );
  final tree = AppPersistenceScope(
    persistence: persistence,
    child: AppSessionScope(
      notifier: session,
      child: AppContainerScope(
        container: container,
        child: ThemeModeScope(
          controller: ThemeModeController(),
          child: AppLocaleScope(
            controller: AppLocaleController(),
            child: LiubanApp(
              session: session,
              sessionTokens: persistence.sessionTokens,
            ),
          ),
        ),
      ),
    ),
  );
  if (textScaler == null) return tree;
  return MediaQuery(
    data: MediaQueryData(textScaler: textScaler),
    child: tree,
  );
}

/// [pumpWidget] + [WidgetTester.pumpAndSettle]，方便一致性測試啟動。
Future<void> pumpLiubanApp(
  WidgetTester tester, {
  TextScaler? textScaler,
}) async {
  await tester.pumpWidget(await liubanAppTestWidget(textScaler: textScaler));
  await tester.pumpAndSettle();
}
