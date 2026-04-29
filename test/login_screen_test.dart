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
import 'package:liuban/data/models/token_pair_dto.dart';
import 'package:liuban/data/models/verification_state_dto.dart';
import 'package:liuban/features/auth/login_screen.dart';

class _AuthLoginNonApiException extends AuthApi {
  _AuthLoginNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<TokenPairDto> login({
    required String account,
    required String password,
  }) async {
    throw StateError('simulated login non-LiubanApiException');
  }
}

/// 登入成功後 [AuthApi.fetchVerificationStatus] 拋非 [LiubanApiException]（內層 catch）。
class _AuthLoginOkFetchVerificationNonApiException extends AuthApi {
  _AuthLoginOkFetchVerificationNonApiException(
    super.dio, {
    required super.apiPrefix,
  });

  @override
  Future<TokenPairDto> login({
    required String account,
    required String password,
  }) async {
    return const TokenPairDto(
      accessToken: 't_access',
      refreshToken: 't_refresh',
    );
  }

  @override
  Future<VerificationStateDto> fetchVerificationStatus() async {
    throw StateError(
      'simulated fetchVerificationStatus non-LiubanApiException',
    );
  }
}

void main() {
  Future<AppSession> pumpWithLoginRoute(
    WidgetTester tester, {
    AuthApi? authApi,
  }) async {
    final session = AppSession();
    final tokens = AuthSessionTokens();
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
      authApi: authApi,
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
    return session;
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

  testWidgets('LoginScreen too long account shows validation snack', (
    tester,
  ) async {
    await pumpWithLoginRoute(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_LOGIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'a' * 129);
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '登入'));
    await tester.pumpAndSettle();
    expect(find.text('帳號長度不可超過 128 字元'), findsOneWidget);
  });

  testWidgets('LoginScreen too long password shows validation snack', (
    tester,
  ) async {
    await pumpWithLoginRoute(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_LOGIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'user@test');
    await tester.enterText(find.byType(TextField).last, 'p' * 129);
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, '登入'));
    await tester.pumpAndSettle();
    expect(find.text('密碼長度不可超過 128 字元'), findsOneWidget);
  });

  testWidgets('submit non-API error shows generic snackbar', (tester) async {
    await pumpWithLoginRoute(
      tester,
      authApi: _AuthLoginNonApiException(Dio(), apiPrefix: AppConfig.apiPrefix),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_LOGIN'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'user@test');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '登入'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.authSubmitGenericFailureMessage),
      findsOneWidget,
    );
  });

  testWidgets(
    'login succeeds but fetchVerificationStatus non-API error still shows success snackbar and pending phase',
    (tester) async {
      final session = await pumpWithLoginRoute(
        tester,
        authApi: _AuthLoginOkFetchVerificationNonApiException(
          Dio(),
          apiPrefix: AppConfig.apiPrefix,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPEN_LOGIN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'user@test');
      await tester.enterText(find.byType(TextField).last, 'secret');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '登入'));
      await tester.pumpAndSettle();

      expect(session.phase, AccountPhase.pendingVerification);
      expect(find.text('登入成功'), findsOneWidget);
    },
  );
}
