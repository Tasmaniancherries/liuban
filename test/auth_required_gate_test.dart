import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/widgets/auth_required_gate.dart';

void main() {
  testWidgets('AuthRequiredGate shows login prompt without token', (
    tester,
  ) async {
    final session = AppSession();
    final tokens = AuthSessionTokens();
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
    );
    final router = GoRouter(
      initialLocation: '/secret',
      routes: [
        GoRoute(
          path: '/secret',
          builder: (context, state) => const AuthRequiredGate(
            title: '測試區',
            child: Scaffold(body: Text('SECRET_CONTENT')),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('LOGIN_PLACEHOLDER')),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) =>
              const Scaffold(body: Text('REGISTER_PLACEHOLDER')),
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
    await tester.pumpAndSettle();
    expect(find.text('測試區'), findsOneWidget);
    expect(find.text('請先登入以使用此功能'), findsOneWidget);
    expect(find.text('SECRET_CONTENT'), findsNothing);
  });

  testWidgets('AuthRequiredGate shows child when access token set', (
    tester,
  ) async {
    final session = AppSession();
    final tokens = AuthSessionTokens(accessToken: 'ok');
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
    );
    final router = GoRouter(
      initialLocation: '/secret',
      routes: [
        GoRoute(
          path: '/secret',
          builder: (context, state) => const AuthRequiredGate(
            child: Scaffold(body: Text('SECRET_CONTENT')),
          ),
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
    await tester.pumpAndSettle();
    expect(find.text('SECRET_CONTENT'), findsOneWidget);
  });
}
