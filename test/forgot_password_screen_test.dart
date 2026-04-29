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
import 'package:liuban/features/auth/forgot_password_screen.dart';

class _AuthRequestResetNonApiException extends AuthApi {
  _AuthRequestResetNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> requestPasswordResetEmail({required String email}) async {
    throw StateError(
      'simulated requestPasswordResetEmail non-LiubanApiException',
    );
  }
}

class _AuthRequestResetApiException extends AuthApi {
  _AuthRequestResetApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> requestPasswordResetEmail({required String email}) async {
    throw LiubanApiException(message: '郵件服務暫時不可用');
  }
}

class _PasswordResetRequestAdapter implements HttpClientAdapter {
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
        p.endsWith('/auth/password/reset/request')) {
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

void main() {
  testWidgets('invalid email shows validation snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('發送重設信'));
    await tester.pumpAndSettle();

    expect(find.text('請輸入有效郵箱'), findsOneWidget);
  });

  testWidgets('too long email shows validation snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '${'a' * 245}@test.example');
    await tester.pump();
    await tester.tap(find.text('發送重設信'));
    await tester.pumpAndSettle();

    expect(find.text('郵箱長度不可超過 254 字元'), findsOneWidget);
  });

  testWidgets('valid email sends POST and shows sent confirmation', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'peer@univ.edu.hk');
    await tester.pump();
    await tester.tap(find.text('發送重設信'));
    await tester.pumpAndSettle();

    expect(find.text('若該郵箱已註冊留伴，我們已寄出重設信。請檢查收件匣與垃圾郵件。'), findsOneWidget);
    expect(find.text('改用其他郵箱'), findsOneWidget);
  });

  testWidgets('back with email draft shows discard dialog', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/forgot'),
                child: const Text('OPEN_FORGOT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
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
    await tester.tap(find.text('OPEN_FORGOT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a@x.hk');
    await tester.pump();

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('捨棄輸入？'), findsOneWidget);
  });

  testWidgets('back with email draft and discard leaves page', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/forgot'),
                child: const Text('OPEN_FORGOT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
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
    await tester.tap(find.text('OPEN_FORGOT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a@x.hk');
    await tester.pump();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('捨棄輸入？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '捨棄'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_FORGOT'), findsOneWidget);
    expect(find.byType(ForgotPasswordScreen), findsNothing);
  });

  testWidgets('keyboard done submits forgot-password form successfully', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'peer@univ.edu.hk');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('若該郵箱已註冊留伴，我們已寄出重設信。請檢查收件匣與垃圾郵件。'), findsOneWidget);
    expect(find.text('改用其他郵箱'), findsOneWidget);
  });

  testWidgets('back after sent state pops directly without discard dialog', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/forgot'),
                child: const Text('OPEN_FORGOT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
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
    await tester.tap(find.text('OPEN_FORGOT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'peer@univ.edu.hk');
    await tester.pump();
    await tester.tap(find.text('發送重設信'));
    await tester.pumpAndSettle();
    expect(find.text('改用其他郵箱'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_FORGOT'), findsOneWidget);
    expect(find.text('捨棄輸入？'), findsNothing);
  });

  testWidgets('support tab back still prompts discard when email draft exists', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/forgot'),
                child: const Text('OPEN_FORGOT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
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
    await tester.tap(find.text('OPEN_FORGOT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a@x.hk');
    await tester.pump();
    await tester.tap(find.text('客服協助'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('捨棄輸入？'), findsOneWidget);
  });

  testWidgets('support tab back without draft pops directly', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/forgot'),
                child: const Text('OPEN_FORGOT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
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
    await tester.tap(find.text('OPEN_FORGOT'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('客服協助'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_FORGOT'), findsOneWidget);
    expect(find.text('捨棄輸入？'), findsNothing);
  });

  testWidgets('send non-API error shows generic snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
      authApi: _AuthRequestResetNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'peer@univ.edu.hk');
    await tester.pump();
    await tester.tap(find.text('發送重設信'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.authSubmitGenericFailureMessage),
      findsOneWidget,
    );
  });

  testWidgets('send API error shows API snackbar message', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
      authApi: _AuthRequestResetApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'peer@univ.edu.hk');
    await tester.pump();
    await tester.tap(find.text('發送重設信'));
    await tester.pumpAndSettle();

    expect(find.text('郵件服務暫時不可用'), findsOneWidget);
  });

  testWidgets('back without draft pops directly without discard dialog', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _PasswordResetRequestAdapter();

    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/forgot'),
                child: const Text('OPEN_FORGOT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
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
    await tester.tap(find.text('OPEN_FORGOT'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_FORGOT'), findsOneWidget);
    expect(find.text('捨棄輸入？'), findsNothing);
  });
}
