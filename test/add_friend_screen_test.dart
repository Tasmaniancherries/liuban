import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/friends_api.dart';
import 'package:liuban/features/friends/add_friend_screen.dart';

class _FriendsSendFriendRequestNonApiException extends FriendsApi {
  _FriendsSendFriendRequestNonApiException(
    super.dio, {
    required super.apiPrefix,
  });

  @override
  Future<void> sendFriendRequest({required String targetCustomId}) async {
    throw StateError('simulated sendFriendRequest non-LiubanApiException');
  }
}

class _SendFriendRequestAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' && p.endsWith('/friends/requests')) {
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
  Future<void> pumpAddFriendStack(WidgetTester tester) async {
    final container = AppContainer(
      guestDeviceId: 'test-device',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _SendFriendRequestAdapter();

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/add-friend'),
                child: const Text('OPEN_ADD_FRIEND'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/add-friend',
          builder: (context, state) => const AddFriendScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('submit sends POST and pops with success snackbar', (
    tester,
  ) async {
    await pumpAddFriendStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_ADD_FRIEND'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'cool_peer');
    await tester.pump();
    await tester.tap(find.text('發送申請'));
    await tester.pumpAndSettle();

    expect(find.text('已向 @cool_peer 發出好友申請'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('OPEN_ADD_FRIEND'), findsOneWidget);
  });

  testWidgets('empty submit shows validation snackbar', (tester) async {
    await pumpAddFriendStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_ADD_FRIEND'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('發送申請'));
    await tester.pumpAndSettle();

    expect(find.text('請輸入 ID'), findsOneWidget);
  });

  testWidgets('too long id shows validation snackbar', (tester) async {
    await pumpAddFriendStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_ADD_FRIEND'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a' * 33);
    await tester.pump();
    await tester.tap(find.text('發送申請'));
    await tester.pumpAndSettle();

    expect(find.text('ID 長度不可超過 32 字元'), findsOneWidget);
  });

  testWidgets('submit non-API error shows generic snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'test-device',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      friendsApi: _FriendsSendFriendRequestNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/add-friend'),
                child: const Text('OPEN_ADD_FRIEND'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/add-friend',
          builder: (context, state) => const AddFriendScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_ADD_FRIEND'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'generic_fail_id');
    await tester.pump();
    await tester.tap(find.text('發送申請'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.friendsWriteGenericFailureMessage),
      findsOneWidget,
    );
  });

  testWidgets('back with draft shows discard dialog and cancel keeps page', (
    tester,
  ) async {
    await pumpAddFriendStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_ADD_FRIEND'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'draft_id');
    await tester.pump();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('捨棄輸入？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(find.byType(AddFriendScreen), findsOneWidget);
    expect(find.text('OPEN_ADD_FRIEND'), findsNothing);
  });

  testWidgets('back with draft and discard leaves page', (tester) async {
    await pumpAddFriendStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_ADD_FRIEND'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'draft_id');
    await tester.pump();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('捨棄輸入？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '捨棄'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_ADD_FRIEND'), findsOneWidget);
    expect(find.byType(AddFriendScreen), findsNothing);
  });

  testWidgets('keyboard done submits and normalizes leading @', (tester) async {
    await pumpAddFriendStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_ADD_FRIEND'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '@cool_peer');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('已向 @cool_peer 發出好友申請'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('OPEN_ADD_FRIEND'), findsOneWidget);
  });

  testWidgets('back without draft leaves page directly', (tester) async {
    await pumpAddFriendStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_ADD_FRIEND'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('OPEN_ADD_FRIEND'), findsOneWidget);
    expect(find.byType(AddFriendScreen), findsNothing);
    expect(find.text('捨棄輸入？'), findsNothing);
  });
}
