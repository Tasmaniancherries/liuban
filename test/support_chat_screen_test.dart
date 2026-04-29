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
import 'package:liuban/data/api/support_api.dart';
import 'package:liuban/features/messages/support_chat_screen.dart';

class _SupportSendErrorAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' && p.endsWith('/support/messages')) {
      return ResponseBody.fromString(
        jsonEncode({'message': '客服送出測試錯誤'}),
        503,
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

/// 模擬 [SupportApi.sendMessage] 拋出非 [LiubanApiException]（例如未預期錯誤），
/// 對應 [SupportChatScreen] 的 generic [catch]。
class _SupportSendNonApiException extends SupportApi {
  _SupportSendNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> sendMessage({
    required String text,
    String? guestToken,
    String? contactHint,
  }) async {
    throw StateError('simulated non-LiubanApiException');
  }
}

class _SupportSendAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' && p.endsWith('/support/messages')) {
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
  testWidgets('empty input tap does not send message', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'guest-empty',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _SupportSendAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: SupportChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暫無客服訊息'), findsOneWidget);

    await tester.tap(find.byTooltip('傳送'));
    await tester.pumpAndSettle();

    expect(find.text('暫無客服訊息'), findsOneWidget);
    expect(find.text('可送出內容'), findsNothing);
  });

  testWidgets('send failure shows API error snackbar', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'guest-err',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _SupportSendErrorAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: SupportChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '這則不會成功');
    await tester.pump();
    await tester.tap(find.byTooltip('傳送'));
    await tester.pumpAndSettle();

    expect(find.text('客服送出測試錯誤'), findsOneWidget);
  });

  testWidgets('send non-API failure shows generic snackbar', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'guest-generic',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
      supportApi: _SupportSendNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: SupportChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '這則走 generic catch');
    await tester.pump();
    await tester.tap(find.byTooltip('傳送'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.supportSendMessageGenericFailureMessage),
      findsOneWidget,
    );
  });

  testWidgets('shows empty state and sends message via API', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'guest-dev-1',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _SupportSendAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: SupportChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('官方客服'), findsOneWidget);
    expect(find.text('暫無客服訊息'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '客服測試留言');
    await tester.pump();
    await tester.tap(find.byTooltip('傳送'));
    await tester.pumpAndSettle();

    expect(find.text('客服測試留言'), findsOneWidget);
    expect(find.text('暫無客服訊息'), findsNothing);
  });

  testWidgets('back with draft shows discard dialog', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _SupportSendAdapter();

    final router = GoRouter(
      initialLocation: '/entry',
      routes: [
        GoRoute(
          path: '/entry',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/support'),
                child: const Text('OPEN_SUPPORT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportChatScreen(),
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
    await tester.tap(find.text('OPEN_SUPPORT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('捨棄未送出訊息？'), findsOneWidget);
  });
}
