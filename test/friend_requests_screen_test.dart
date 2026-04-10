import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/features/friends/friend_requests_screen.dart';

class _FriendRequestsAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/friends/requests/incoming')) {
      return ResponseBody.fromString(
        jsonEncode({
          'items': [
            {
              'id': 'req_in_1',
              'from_custom_id': 'incoming_buddy',
              'created_at': '2026-04-01',
            },
          ],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.method == 'GET' && p.endsWith('/friends/requests/outgoing')) {
      return ResponseBody.fromString(
        jsonEncode({
          'items': [
            {
              'id': 'req_out_1',
              'to_custom_id': 'outgoing_target',
              'status': 'pending',
              'created_at': '2026-04-02',
            },
          ],
        }),
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
  testWidgets('loads incoming and outgoing friend request lists from API', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'test-device',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _FriendRequestsAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: FriendRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('好友申請'), findsOneWidget);
    expect(find.text('@incoming_buddy'), findsOneWidget);
    expect(find.text('2026-04-01'), findsOneWidget);

    await tester.tap(find.text('我發出的'));
    await tester.pumpAndSettle();

    expect(find.text('@outgoing_target'), findsOneWidget);
    expect(find.text('pending'), findsOneWidget);
    expect(find.text('2026-04-02'), findsOneWidget);
  });
}
