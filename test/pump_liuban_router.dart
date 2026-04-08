import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/app/router.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/locale/app_locale_controller.dart';
import 'package:liuban/core/locale/app_locale_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/theme/theme_mode_controller.dart';
import 'package:liuban/core/theme/theme_mode_scope.dart';

/// Pumps [MaterialApp.router] with [buildRouter] and the same scopes as production
/// for routes that need [ThemeModeScope] / [AppLocaleScope] (e.g. [SettingsScreen]).
Future<GoRouter> pumpLiubanRouter(
  WidgetTester tester, {
  AppSession? session,
  AuthSessionTokens? tokens,
  Duration initialSettle = const Duration(seconds: 2),
}) async {
  final s = session ?? AppSession();
  final t = tokens ?? AuthSessionTokens();
  final container = AppContainer(
    guestDeviceId: 't',
    logHttpTraffic: false,
    baseUrl: 'https://example.invalid',
    sessionTokens: t,
  );
  final router = buildRouter(s, sessionTokens: t);
  await tester.pumpWidget(
    AppSessionScope(
      notifier: s,
      child: AppContainerScope(
        container: container,
        child: ThemeModeScope(
          controller: ThemeModeController(),
          child: AppLocaleScope(
            controller: AppLocaleController(),
            child: MaterialApp.router(
              theme: LiubanTheme.light(),
              routerConfig: router,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(initialSettle);
  return router;
}

void expectLiubanAppBarTitle(String title) {
  expect(
    find.descendant(of: find.byType(AppBar), matching: find.text(title)),
    findsOneWidget,
  );
}
