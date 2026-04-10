import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/ui/scroll_constants.dart';

void main() {
  test('kLiubanListCacheExtent is positive', () {
    expect(kLiubanListCacheExtent, greaterThan(0));
  });
}
