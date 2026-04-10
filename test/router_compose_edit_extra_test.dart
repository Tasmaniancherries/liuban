import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/data/models/feed_post_dto.dart';

import 'pump_liuban_router.dart';

void main() {
  testWidgets('/compose/edit with matching extra seeds edit form', (
    tester,
  ) async {
    final session = AppSession()..setPhase(AccountPhase.verifiedStudent);
    final tokens = AuthSessionTokens(accessToken: 'tok');
    final router = await pumpLiubanRouter(
      tester,
      session: session,
      tokens: tokens,
    );
    const post = FeedPostDto(
      id: 'p-1',
      authorId: 'u-1',
      authorDisplay: 'river',
      body: 'seed body from extra',
      audience: 'public',
    );

    unawaited(
      router.push('/compose/edit/${Uri.encodeComponent(post.id)}', extra: post),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expectLiubanAppBarTitle('編輯動態');
    expect(find.text('seed body from extra'), findsOneWidget);
    expect(find.bySemanticsLabel('載入中'), findsNothing);
  });
}
