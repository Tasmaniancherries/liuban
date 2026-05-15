import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/features/auth/reset_password_confirm_screen.dart';

class _AuthCompleteResetNonApiException extends AuthApi {
  _AuthCompleteResetNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> completePasswordResetWithToken({
    required String token,
    required String newPassword,
  }) async {
    throw StateError(
      'simulated completePasswordResetWithToken non-LiubanApiException',
    );
  }
}

class _AuthCompleteResetApiException extends AuthApi {
  _AuthCompleteResetApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> completePasswordResetWithToken({
    required String token,
    required String newPassword,
  }) async {
    throw LiubanApiException(message: '重設憑證無效或已過期');
  }
}

class _ResetCompleteAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' &&
        p.endsWith('/auth/password/reset/complete')) {
      return ResponseBody.fromString(
        jsonEncode({}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'unexpected'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

Finder _resetList() {
  return find.descendant(
    of: find.byType(ResetPasswordConfirmScreen),
    matching: find.byType(ListView),
  );
}

void _bindTallSurface(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1.0;
}

Future<void> _revealSubmit(WidgetTester tester) async {
  await tester.drag(_resetList(), const Offset(0, -900));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty token shows snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _ResetCompleteAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordConfirmScreen(initialToken: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).at(1), 'newpass123');
    await tester.enterText(find.byType(TextField).at(2), 'newpass123');
    await tester.pump();

    await tester.tap(find.text('完成重設'));
    await tester.pumpAndSettle();

    expect(find.text('請輸入重設憑證（token）'), findsOneWidget);
  });

  testWidgets('too long token shows validation snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _ResetCompleteAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordConfirmScreen(initialToken: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).first, 't' * 513);
    await tester.enterText(find.byType(TextField).at(1), 'newpass123');
    await tester.enterText(find.byType(TextField).at(2), 'newpass123');
    await tester.pump();
    await tester.tap(find.text('完成重設'));
    await tester.pumpAndSettle();

    expect(find.text('重設憑證長度不可超過 512 字元'), findsOneWidget);
  });

  testWidgets('too long new password shows validation snackbar', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _ResetCompleteAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordConfirmScreen(initialToken: 'mail_token_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).at(1), 'a' * 129);
    await tester.enterText(find.byType(TextField).at(2), 'a' * 129);
    await tester.pump();
    await tester.tap(find.text('完成重設'));
    await tester.pumpAndSettle();

    expect(find.text('新密碼長度不可超過 128 字元'), findsOneWidget);
  });

  testWidgets('short password shows length validation snackbar', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _ResetCompleteAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordConfirmScreen(initialToken: 'mail_token_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).at(1), 'short');
    await tester.enterText(find.byType(TextField).at(2), 'short');
    await tester.pump();
    await tester.tap(find.text('完成重設'));
    await tester.pumpAndSettle();

    expect(find.text('新密碼至少 8 字元'), findsOneWidget);
  });

  testWidgets('password mismatch shows mismatch validation snackbar', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _ResetCompleteAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordConfirmScreen(initialToken: 'mail_token_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).at(1), 'newpass123');
    await tester.enterText(find.byType(TextField).at(2), 'newpassXYZ');
    await tester.pump();
    await tester.tap(find.text('完成重設'));
    await tester.pumpAndSettle();

    expect(find.text('兩次密碼不一致'), findsOneWidget);
  });

  testWidgets('success posts and navigates to login', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _ResetCompleteAdapter();

    final router = GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('LOGIN_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) =>
              const ResetPasswordConfirmScreen(initialToken: 'mail_token_1'),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).at(1), 'newpass123');
    await tester.enterText(find.byType(TextField).at(2), 'newpass123');
    await tester.pump();

    await tester.tap(find.text('完成重設'));
    await tester.pumpAndSettle();

    expect(find.text('密碼已重設，請使用新密碼登入'), findsOneWidget);
    expect(find.text('LOGIN_ROUTE_MARKER'), findsOneWidget);
  });

  testWidgets('complete reset non-API error shows generic snackbar', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
      authApi: _AuthCompleteResetNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordConfirmScreen(initialToken: 'mail_token_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).at(1), 'newpass123');
    await tester.enterText(find.byType(TextField).at(2), 'newpass123');
    await tester.pump();

    await tester.tap(find.text('完成重設'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.authSubmitGenericFailureMessage),
      findsOneWidget,
    );
  });

  testWidgets('complete reset API error shows API snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
      authApi: _AuthCompleteResetApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: ResetPasswordConfirmScreen(initialToken: 'mail_token_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).at(1), 'newpass123');
    await tester.enterText(find.byType(TextField).at(2), 'newpass123');
    await tester.pump();

    await tester.tap(find.text('完成重設'));
    await tester.pumpAndSettle();

    expect(find.text('重設憑證無效或已過期'), findsOneWidget);
  });

  testWidgets('back without draft pops directly', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/reset'),
                child: const Text('OPEN_RESET'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) =>
              const ResetPasswordConfirmScreen(initialToken: ''),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_RESET'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_RESET'), findsOneWidget);
    expect(find.text('捨棄輸入？'), findsNothing);
  });

  testWidgets('back with draft shows discard dialog and cancel keeps page', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/reset'),
                child: const Text('OPEN_RESET'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) =>
              const ResetPasswordConfirmScreen(initialToken: ''),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_RESET'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'draft_token');
    await tester.pump();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('捨棄輸入？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(find.byType(ResetPasswordConfirmScreen), findsOneWidget);
    expect(find.text('OPEN_RESET'), findsNothing);
  });

  testWidgets('back with draft and discard leaves page', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/reset'),
                child: const Text('OPEN_RESET'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) =>
              const ResetPasswordConfirmScreen(initialToken: ''),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_RESET'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'draft_token');
    await tester.pump();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('捨棄輸入？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '捨棄'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_RESET'), findsOneWidget);
    expect(find.byType(ResetPasswordConfirmScreen), findsNothing);
  });

  testWidgets('keyboard done submits reset form successfully', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _ResetCompleteAdapter();

    final router = GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('LOGIN_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) =>
              const ResetPasswordConfirmScreen(initialToken: 'mail_token_1'),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.enterText(find.byType(TextField).at(1), 'newpass123');
    await tester.enterText(find.byType(TextField).at(2), 'newpass123');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('密碼已重設，請使用新密碼登入'), findsOneWidget);
    expect(find.text('LOGIN_ROUTE_MARKER'), findsOneWidget);
  });

  testWidgets('return login button navigates to login route', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );

    final router = GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('LOGIN_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              const Scaffold(body: Text('FORGOT_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) =>
              const Scaffold(body: Text('REGISTER_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) =>
              const ResetPasswordConfirmScreen(initialToken: ''),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.tap(find.text('返回登入'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN_ROUTE_MARKER'), findsOneWidget);
  });

  testWidgets('forgot-password button navigates to forgot-password route', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );

    final router = GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('LOGIN_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              const Scaffold(body: Text('FORGOT_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) =>
              const Scaffold(body: Text('REGISTER_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) =>
              const ResetPasswordConfirmScreen(initialToken: ''),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.tap(find.text('忘記密碼？'));
    await tester.pumpAndSettle();

    expect(find.text('FORGOT_ROUTE_MARKER'), findsOneWidget);
  });

  testWidgets('register button navigates to register route', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );

    final router = GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('LOGIN_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              const Scaffold(body: Text('FORGOT_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) =>
              const Scaffold(body: Text('REGISTER_ROUTE_MARKER')),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) =>
              const ResetPasswordConfirmScreen(initialToken: ''),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.tap(find.text('還沒有帳號？註冊'));
    await tester.pumpAndSettle();

    expect(find.text('REGISTER_ROUTE_MARKER'), findsOneWidget);
  });
}
