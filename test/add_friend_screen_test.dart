import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/features/friends/add_friend_screen.dart';

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
}
