import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/features/account/change_password_screen.dart';

class _AuthChangePasswordNonApiException extends AuthApi {
  _AuthChangePasswordNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw StateError('simulated changePassword non-LiubanApiException');
  }
}

class _ChangePasswordAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' && p.endsWith('/auth/password')) {
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

Finder _changePasswordList() {
  return find.descendant(
    of: find.byType(ChangePasswordScreen),
    matching: find.byType(ListView),
  );
}

void _bindTallSurface(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
}

Future<void> _revealSubmit(WidgetTester tester) async {
  await tester.drag(_changePasswordList(), const Offset(0, -800));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty submit shows incomplete snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _ChangePasswordAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ChangePasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    await tester.tap(find.text('確認修改'));
    await tester.pumpAndSettle();

    expect(find.text('請填寫完整'), findsOneWidget);
  });

  testWidgets('short new password shows length snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _ChangePasswordAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ChangePasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'oldpass12');
    await tester.enterText(fields.at(1), 'short');
    await tester.enterText(fields.at(2), 'short');
    await tester.pump();

    await tester.tap(find.text('確認修改'));
    await tester.pumpAndSettle();

    expect(find.text('新密碼至少 8 字元'), findsOneWidget);
  });

  testWidgets('too long password shows length snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _ChangePasswordAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ChangePasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'oldpass12');
    await tester.enterText(fields.at(1), 'a' * 129);
    await tester.enterText(fields.at(2), 'a' * 129);
    await tester.pump();

    await tester.tap(find.text('確認修改'));
    await tester.pumpAndSettle();

    expect(find.text('密碼長度不可超過 128 字元'), findsOneWidget);
  });

  testWidgets('mismatch new passwords shows snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _ChangePasswordAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ChangePasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'oldpass12');
    await tester.enterText(fields.at(1), 'newpass123');
    await tester.enterText(fields.at(2), 'newpass999');
    await tester.pump();

    await tester.tap(find.text('確認修改'));
    await tester.pumpAndSettle();

    expect(find.text('兩次新密碼不一致'), findsOneWidget);
  });

  testWidgets('success sends POST and pops with snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _ChangePasswordAdapter();

    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/pwd'),
                child: const Text('OPEN_CHANGE_PWD'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/pwd',
          builder: (context, state) => const ChangePasswordScreen(),
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

    await tester.tap(find.text('OPEN_CHANGE_PWD'));
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'currentOld1');
    await tester.enterText(fields.at(1), 'newpass123');
    await tester.enterText(fields.at(2), 'newpass123');
    await tester.pump();

    await tester.tap(find.text('確認修改'));
    await tester.pumpAndSettle();

    expect(find.text('已更新密碼'), findsOneWidget);
    expect(find.text('OPEN_CHANGE_PWD'), findsOneWidget);
  });

  testWidgets('submit non-API error shows generic snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      authApi: _AuthChangePasswordNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ChangePasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealSubmit(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'currentOld1');
    await tester.enterText(fields.at(1), 'newpass123');
    await tester.enterText(fields.at(2), 'newpass123');
    await tester.pump();

    await tester.tap(find.text('確認修改'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.authSubmitGenericFailureMessage),
      findsOneWidget,
    );
  });
}
