import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/features/feed/feed_post_share.dart';
import 'package:liuban/features/promotion/promotion_share.dart';

void main() {
  test('feedPostShareUrl encodes post id into /post path', () {
    final url = feedPostShareUrl('post id/中文?x=1');
    expect(url, contains('/post/'));
    expect(url, contains(Uri.encodeComponent('post id/中文?x=1')));
  });

  test('promotionShareUrl encodes promotion id into /promotion path', () {
    final url = promotionShareUrl('promo id/測試?x=1');
    expect(url, contains('/promotion/'));
    expect(url, contains(Uri.encodeComponent('promo id/測試?x=1')));
  });

  test('share urls do not end with slash after id', () {
    expect(feedPostShareUrl('abc').endsWith('/'), isFalse);
    expect(promotionShareUrl('xyz').endsWith('/'), isFalse);
  });
}
