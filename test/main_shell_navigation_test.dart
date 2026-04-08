import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/app/router.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';

void main() {
  testWidgets('MainShell bottom nav switches from feed to promotion', (
    tester,
  ) async {
    final session = AppSession();
    final tokens = AuthSessionTokens();
    final container = AppContainer(
      guestDeviceId: 't',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
    );
    final router = buildRouter(session, sessionTokens: tokens);
    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: session,
          child: MaterialApp.router(
            theme: LiubanTheme.light(),
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('留伴 · 廣場'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('推廣'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('推廣')),
      findsOneWidget,
    );
  });
}
