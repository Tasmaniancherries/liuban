import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/features/feed/feed_post_share.dart';
import 'package:liuban/features/promotion/promotion_share.dart';

void main() {
  testWidgets('openFeedPostShareActions shows sheet with post share url', (
    tester,
  ) async {
    const postId = 'post-abc';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => openFeedPostShareActions(context, postId),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(feedPostShareUrl(postId)), findsOneWidget);
    expect(find.text('複製連結'), findsOneWidget);
  });

  testWidgets('openPromotionShareActions shows sheet with promotion url', (
    tester,
  ) async {
    const promoId = 'promo-xyz';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => openPromotionShareActions(context, promoId),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(promotionShareUrl(promoId)), findsOneWidget);
    expect(find.text('複製連結'), findsOneWidget);
  });
}
