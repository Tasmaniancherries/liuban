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

/// Full shell tests need the same scopes as [SettingsScreen] when opening stack routes.
Future<GoRouter> pumpMainShell(
  WidgetTester tester, {
  AppSession? session,
  AuthSessionTokens? tokens,
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
  await tester.pump(const Duration(seconds: 2));
  return router;
}

Future<void> tapBottomNav(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void expectAppBarTitle(String title) {
  expect(
    find.descendant(of: find.byType(AppBar), matching: find.text(title)),
    findsOneWidget,
  );
}

void main() {
  testWidgets('MainShell bottom nav: feed → 推廣', (tester) async {
    await pumpMainShell(tester);
    expect(find.text('留伴 · 廣場'), findsOneWidget);
    await tapBottomNav(tester, '推廣');
    expectAppBarTitle('推廣');
  });

  testWidgets('MainShell bottom nav: feed → 訊息', (tester) async {
    await pumpMainShell(tester);
    await tapBottomNav(tester, '訊息');
    expectAppBarTitle('訊息');
  });

  testWidgets('MainShell bottom nav: feed → 我的', (tester) async {
    await pumpMainShell(tester);
    await tapBottomNav(tester, '我的');
    expectAppBarTitle('我的');
  });

  testWidgets('MainShell bottom nav: 推廣 → 廣場', (tester) async {
    await pumpMainShell(tester);
    await tapBottomNav(tester, '推廣');
    expectAppBarTitle('推廣');
    await tapBottomNav(tester, '廣場');
    expect(find.text('留伴 · 廣場'), findsOneWidget);
  });

  testWidgets('buildRouter /settings shows 設定 app bar', (tester) async {
    final router = await pumpMainShell(tester);
    router.go('/settings');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expectAppBarTitle('設定');
  });
}
