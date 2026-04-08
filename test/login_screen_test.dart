import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/features/auth/login_screen.dart';

void main() {
  Future<void> pumpWithLoginRoute(WidgetTester tester) async {
    final session = AppSession();
    final tokens = AuthSessionTokens();
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
    );
    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('OPEN_LOGIN'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );
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
  }

  testWidgets('LoginScreen back without draft pops route', (tester) async {
    await pumpWithLoginRoute(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_LOGIN'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('OPEN_LOGIN'), findsOneWidget);
  });

  testWidgets('LoginScreen back with draft shows discard dialog', (
    tester,
  ) async {
    await pumpWithLoginRoute(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_LOGIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'u');
    await tester.pump();

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('捨棄輸入？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('LoginScreen discard confirm pops route', (tester) async {
    await pumpWithLoginRoute(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_LOGIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'u');
    await tester.pump();

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('捨棄'));
    await tester.pumpAndSettle();
    expect(find.text('OPEN_LOGIN'), findsOneWidget);
  });

  testWidgets('LoginScreen submit empty shows validation snack', (
    tester,
  ) async {
    await pumpWithLoginRoute(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_LOGIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '登入'));
    await tester.pumpAndSettle();
    expect(find.text('請輸入帳號與密碼'), findsOneWidget);
  });
}
