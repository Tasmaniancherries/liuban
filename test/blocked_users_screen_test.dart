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
import 'package:liuban/data/models/blocked_user_dto.dart';
import 'package:liuban/features/settings/blocked_users_screen.dart';

class _FriendsListBlockedNonApiException extends FriendsApi {
  _FriendsListBlockedNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<List<BlockedUserDto>> listBlockedUsers() async {
    throw StateError('simulated listBlockedUsers non-LiubanApiException');
  }
}

class _FriendsUnblockNonApiException extends FriendsApi {
  _FriendsUnblockNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> unblockUser({required String userId}) async {
    throw StateError('simulated unblockUser non-LiubanApiException');
  }
}

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

  testWidgets('list non-API error shows empty state and generic snackbar', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'test-device',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      friendsApi: _FriendsListBlockedNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('尚無屏蔽對象'), findsOneWidget);
    expect(
      find.text(ApiDevSemantics.blockedUsersListLoadFailedMessage),
      findsOneWidget,
    );
  });

  testWidgets('unblock non-API error shows generic snackbar', (tester) async {
    final adapter = _BlocksListAdapter();
    final container = AppContainer(
      guestDeviceId: 'test-device',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      friendsApiFactory: (dio) {
        dio.httpClientAdapter = adapter;
        return _FriendsUnblockNonApiException(
          dio,
          apiPrefix: AppConfig.apiPrefix,
        );
      },
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('解除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '解除'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.friendsWriteGenericFailureMessage),
      findsOneWidget,
    );
  });
}
