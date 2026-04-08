import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';

void main() {
  group('ApiDevSemantics.userFacingGoRouterMessage', () {
    test('maps known no routes prefix', () {
      expect(
        ApiDevSemantics.userFacingGoRouterMessage('no routes for location: /x'),
        '沒有符合此路徑的 App 頁面。',
      );
    });

    test('maps redirect loop', () {
      expect(
        ApiDevSemantics.userFacingGoRouterMessage('redirect loop detected (…)'),
        '重新導向發生循環，已停止。',
      );
    });

    test('maps too many redirects', () {
      expect(
        ApiDevSemantics.userFacingGoRouterMessage('too many redirects'),
        '重新導向次數過多，已停止。',
      );
    });

    test('maps empty location message', () {
      expect(
        ApiDevSemantics.userFacingGoRouterMessage('Location cannot be empty.'),
        '路由位置不可為空。',
      );
    });

    test('returns raw when unknown', () {
      expect(
        ApiDevSemantics.userFacingGoRouterMessage('something else'),
        'something else',
      );
    });
  });

  group('ApiDevSemantics.routeErrorSemanticsLabel', () {
    test('includes location when non-empty', () {
      final s = ApiDevSemantics.routeErrorSemanticsLabel(
        '錯誤',
        attemptedSafeLocation: '/safe',
      );
      expect(s, contains('錯誤'));
      expect(s, contains('嘗試開啟'));
      expect(s, contains('/safe'));
      expect(s, contains(ApiDevSemantics.routeNotFoundFootnote));
    });

    test('omits empty trimmed location', () {
      final s = ApiDevSemantics.routeErrorSemanticsLabel(
        '錯誤',
        attemptedSafeLocation: '   ',
      );
      expect(s.startsWith('錯誤 '), isTrue);
      expect(s.contains('嘗試開啟'), isFalse);
    });
  });
}
