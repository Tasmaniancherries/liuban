import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/data/models/verification_state_dto.dart';
import 'package:liuban/widgets/compose_access_gate.dart';

class _AuthFetchVerificationNonApiException extends AuthApi {
  _AuthFetchVerificationNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<VerificationStateDto> fetchVerificationStatus() async {
    throw StateError(
      'simulated fetchVerificationStatus non-LiubanApiException',
    );
  }
}

void main() {
  testWidgets('ComposeAccessGate shows auth prompt when not logged in', (
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
      initialLocation: '/compose',
      routes: [
        GoRoute(
          path: '/compose',
          builder: (context, state) => const ComposeAccessGate(),
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
    expect(find.text('發佈動態'), findsWidgets);
    expect(find.text('請先登入以使用此功能'), findsOneWidget);
  });

  testWidgets(
    'ComposeAccessGate shows verification prompt when logged in but guest-like',
    (tester) async {
      final session = AppSession()..setPhase(AccountPhase.pendingVerification);
      final tokens = AuthSessionTokens(accessToken: 'tok');
      final container = AppContainer(
        guestDeviceId: 'g',
        logHttpTraffic: false,
        baseUrl: 'https://example.invalid',
        sessionTokens: tokens,
      );
      final router = GoRouter(
        initialLocation: '/compose',
        routes: [
          GoRoute(
            path: '/compose',
            builder: (context, state) => const ComposeAccessGate(),
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
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                const Scaffold(body: Text('PROFILE_PLACEHOLDER')),
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
      expect(find.text('通過身分審核後才可發佈廣場動態'), findsOneWidget);
      expect(find.text('同步審核狀態'), findsOneWidget);
    },
  );

  testWidgets('sync verification non-API error shows generic snackbar', (
    tester,
  ) async {
    final session = AppSession()..setPhase(AccountPhase.pendingVerification);
    final tokens = AuthSessionTokens(accessToken: 'tok');
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
      authApi: _AuthFetchVerificationNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );
    final router = GoRouter(
      initialLocation: '/compose',
      routes: [
        GoRoute(
          path: '/compose',
          builder: (context, state) => const ComposeAccessGate(),
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

    await tester.tap(find.text('同步審核狀態'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.verificationSyncGenericFailureMessage),
      findsOneWidget,
    );
  });
}
