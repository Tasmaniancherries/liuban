import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/features/settings/blocked_users_screen.dart';

class _BlocksListAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/friends/blocks')) {
      return ResponseBody.fromString(
        jsonEncode({
          'items': [
            {'user_id': 'u1', 'custom_id': '@blocked_user'},
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
  testWidgets('loads blocked users list from API', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'test-device',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _BlocksListAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('@blocked_user'), findsOneWidget);
    expect(find.text('ID · u1'), findsOneWidget);
    expect(find.text('解除'), findsOneWidget);
  });
}
