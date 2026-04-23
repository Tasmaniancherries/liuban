import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/friends_api.dart';
import 'package:liuban/data/models/dm_message_dto.dart';
import 'package:liuban/features/messages/dm_chat_screen.dart';

/// 模擬 [FriendsApi.listDmMessages] 拋出非 [LiubanApiException]（載入對話 generic [catch]）。
class _FriendsListDmNonApiException extends FriendsApi {
  _FriendsListDmNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<List<DmMessageDto>> listDmMessages({required String peerId}) async {
    throw StateError('simulated listDmMessages non-LiubanApiException');
  }
}

/// 模擬 [FriendsApi.sendDmMessage] 拋出非 [LiubanApiException]（傳送 generic [catch]）。
class _FriendsSendDmNonApiException extends FriendsApi {
  _FriendsSendDmNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> sendDmMessage({
    required String peerId,
    required String text,
  }) async {
    throw StateError('simulated sendDmMessage non-LiubanApiException');
  }
}

class _DmThreadAdapter implements HttpClientAdapter {
  _DmThreadAdapter();

  final List<Map<String, dynamic>> messages = [
    {'id': 'm1', 'body': '對方載入測試', 'is_mine': false, 'created_at': '10:00'},
  ];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' &&
        p.contains('/friends/dm/') &&
        p.endsWith('/messages')) {
      return ResponseBody.fromString(
        jsonEncode(messages),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.method == 'POST' &&
        p.contains('/friends/dm/') &&
        p.endsWith('/messages')) {
      final data = options.data;
      final text = data is Map<String, dynamic>
          ? (data['text'] as String? ?? '')
          : '';
      messages.add({
        'id': 'm2',
        'body': text,
        'is_mine': true,
        'created_at': '10:01',
      });
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
  testWidgets('loads thread and sends message', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    final adapter = _DmThreadAdapter();
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = adapter;

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: DmChatScreen(peerId: 'peer_z', peerCustomId: 'peer_z'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('@peer_z'), findsOneWidget);
    expect(find.text('對方載入測試'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '我回覆一句');
    await tester.pump();
    await tester.tap(find.byTooltip('傳送'));
    await tester.pumpAndSettle();

    expect(find.text('我回覆一句'), findsOneWidget);
  });

  testWidgets('thread load non-API error shows empty state and generic snackbar', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      friendsApi: _FriendsListDmNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: DmChatScreen(peerId: 'peer_z', peerCustomId: 'peer_z'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.dmThreadLoadFailedMessage),
      findsOneWidget,
    );
    expect(find.text('暫無對話訊息'), findsOneWidget);
  });

  testWidgets('send non-API error shows generic snackbar', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    final adapter = _DmThreadAdapter();
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      friendsApiFactory: (dio) {
        dio.httpClientAdapter = adapter;
        return _FriendsSendDmNonApiException(
          dio,
          apiPrefix: AppConfig.apiPrefix,
        );
      },
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: DmChatScreen(peerId: 'peer_z', peerCustomId: 'peer_z'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '這則不會成功');
    await tester.pump();
    await tester.tap(find.byTooltip('傳送'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.dmSendMessageGenericFailureMessage),
      findsOneWidget,
    );
  });
}
