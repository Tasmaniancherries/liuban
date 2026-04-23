import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/friends_api.dart';
import 'package:liuban/data/models/friend_inbox_item_dto.dart';
import 'package:liuban/features/messages/messages_screen.dart';

class _FriendsListInboxNonApiException extends FriendsApi {
  _FriendsListInboxNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<List<FriendInboxItemDto>> listInbox() async {
    throw StateError('simulated listInbox non-LiubanApiException');
  }
}

void main() {
  testWidgets('shows 訊息 tabs and official support entry', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: AppSession(),
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: MessagesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectLiubanAppBarTitle('訊息');
    expect(find.text('官方客服'), findsOneWidget);
    expect(find.text('好友'), findsOneWidget);
    expect(find.text('與留伴客服對話'), findsOneWidget);
  });

  testWidgets('好友 tab shows guest lock when not verified', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: AppSession(),
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: MessagesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('好友'));
    await tester.pumpAndSettle();

    expect(find.text('好友私信'), findsOneWidget);
    expect(find.text('通過身分審核並互為好友後，可在此發起聊天。'), findsOneWidget);
  });

  testWidgets('好友 inbox non-API error shows empty state and generic snackbar', (
    tester,
  ) async {
    final session = AppSession()..setPhase(AccountPhase.verifiedStudent);
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      friendsApi: _FriendsListInboxNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: session,
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: MessagesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('好友'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.friendsInboxLoadFailedMessage),
      findsOneWidget,
    );
    expect(find.text('暫無好友會話'), findsOneWidget);
  });
}

void expectLiubanAppBarTitle(String title) {
  expect(
    find.descendant(of: find.byType(AppBar), matching: find.text(title)),
    findsOneWidget,
  );
}
