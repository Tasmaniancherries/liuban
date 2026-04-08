import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/navigation/deep_link_guard.dart';

void main() {
  test('routeDedupKey normalizes path slashes and trailing slash', () {
    expect(routeDedupKey('//feed///'), '/feed');
    expect(routeDedupKey('/'), '/');
    expect(routeDedupKey('   /feed/   '), '/feed');
    expect(routeDedupKey('   '), '/');
    expect(routeDedupKey(r'/feed\\post/'), '/feed/post');
  });

  test('routeDedupKey normalizes query order', () {
    final a = routeDedupKey('/login?b=2&a=1');
    final b = routeDedupKey('/login?a=1&b=2');
    expect(a, b);
  });

  test(
    'routeDedupKey normalizes repeated query value order and drops fragment',
    () {
      final a = routeDedupKey('/feed?x=2&x=1#sec');
      final b = routeDedupKey('/feed?x=1&x=2');
      expect(a, b);
      expect(a.contains('#'), isFalse);
    },
  );

  test('isAllowedDeepLinkLocation accepts known app routes', () {
    expect(isAllowedDeepLinkLocation('/feed'), isTrue);
    expect(isAllowedDeepLinkLocation('/promotion'), isTrue);
    expect(isAllowedDeepLinkLocation('/promotion/9'), isTrue);
    expect(isAllowedDeepLinkLocation('/login?redirect=%2Ffeed'), isTrue);
    expect(isAllowedDeepLinkLocation('/dm/peer-1'), isTrue);
    expect(isAllowedDeepLinkLocation('//feed///'), isTrue);
    expect(isAllowedDeepLinkLocation('/feed#section'), isTrue);
    expect(isAllowedDeepLinkLocation('/dm/peer%2F2'), isTrue);
    expect(isAllowedDeepLinkLocation('/post/abc%2Fdef'), isTrue);
    expect(isAllowedDeepLinkLocation('/compose/edit/abc'), isTrue);
    expect(isAllowedDeepLinkLocation('/settings/blocked-users'), isTrue);
  });

  test('isAllowedDeepLinkLocation rejects unknown routes', () {
    expect(isAllowedDeepLinkLocation('/admin'), isFalse);
    expect(isAllowedDeepLinkLocation('/promotionx'), isFalse);
    expect(isAllowedDeepLinkLocation('/x/feed'), isFalse);
    expect(isAllowedDeepLinkLocation('   /admin   '), isFalse);
    expect(isAllowedDeepLinkLocation('https://liuban.app/feed'), isFalse);
    expect(isAllowedDeepLinkLocation('liuban://feed'), isFalse);
    expect(isAllowedDeepLinkLocation('https://liuban.app//feed///'), isFalse);
    expect(isAllowedDeepLinkLocation('://broken'), isFalse);
    expect(isAllowedDeepLinkLocation('/feed/../profile'), isFalse);
    expect(isAllowedDeepLinkLocation('/feed/./x'), isFalse);
    expect(isAllowedDeepLinkLocation('/feed/%2E%2E/profile'), isFalse);
    expect(isAllowedDeepLinkLocation('HTTPS://liuban.app/feed'), isFalse);
    expect(isAllowedDeepLinkLocation('//liuban.app/feed'), isFalse);
    expect(isAllowedDeepLinkLocation('/feed%0Aprofile'), isFalse);
    expect(isAllowedDeepLinkLocation('/feed%09x'), isFalse);
    expect(isAllowedDeepLinkLocation('/login?redirect=%0A%2Ffeed'), isFalse);
    expect(isAllowedDeepLinkLocation('/login?x=ok%09bad'), isFalse);
    expect(isAllowedDeepLinkLocation('/settings/unknown'), isFalse);
    expect(isAllowedDeepLinkLocation('/profile/extra'), isFalse);
    expect(isAllowedDeepLinkLocation('/dm/'), isFalse);
    expect(isAllowedDeepLinkLocation('/post/'), isFalse);
    expect(isAllowedDeepLinkLocation('/promotion/'), isFalse);
    expect(isAllowedDeepLinkLocation('/compose/edit/'), isFalse);
    expect(isAllowedDeepLinkLocation('/dm//x'), isFalse);
    expect(isAllowedDeepLinkLocation('/dm/x/y'), isFalse);
    expect(isAllowedDeepLinkLocation('/post/x/y'), isFalse);
    expect(isAllowedDeepLinkLocation('/compose/edit/x/y'), isFalse);
    final longSeg = List.filled(300, 'a').join();
    expect(isAllowedDeepLinkLocation('/dm/$longSeg'), isFalse);
    expect(isAllowedDeepLinkLocation('/dm/a/b/c/d/e/f/g/h'), isFalse);
    expect(isAllowedDeepLinkLocation('/dm%2Fpeer-2'), isFalse);
    expect(isAllowedDeepLinkLocation('/dm%5Cpeer-2'), isFalse);
    final longQueryKey = List.filled(140, 'k').join();
    expect(isAllowedDeepLinkLocation('/login?$longQueryKey=x'), isFalse);
    final longQueryValue = List.filled(600, 'v').join();
    expect(
      isAllowedDeepLinkLocation('/login?redirect=$longQueryValue'),
      isFalse,
    );
    final tooManyQueryKeys = List.generate(40, (i) => 'k$i=v').join('&');
    expect(isAllowedDeepLinkLocation('/login?$tooManyQueryKeys'), isFalse);
    final tooManyQueryValues = List.generate(40, (i) => 'x=$i').join('&');
    expect(isAllowedDeepLinkLocation('/login?$tooManyQueryValues'), isFalse);
    final tooManyQueryPairs = List.generate(
      17,
      (i) => 'k$i=v1&k$i=v2&k$i=v3&k$i=v4',
    ).join('&');
    expect(isAllowedDeepLinkLocation('/login?$tooManyQueryPairs'), isFalse);
    final long = "/feed?x=${List.filled(5000, "a").join()}";
    expect(isAllowedDeepLinkLocation(long), isFalse);
  });

  test('safeUriForLog redacts sensitive query values', () {
    final uri = Uri.parse(
      'https://liuban.app/reset-password?token=abc&code=123&x=ok#secret-fragment',
    );
    final safe = safeUriForLog(uri);
    expect(safe.contains('token=%2A%2A%2A'), isTrue);
    expect(safe.contains('code=%2A%2A%2A'), isTrue);
    expect(safe.contains('x=ok'), isTrue);
    expect(safe.contains('token=abc'), isFalse);
    expect(safe.contains('code=123'), isFalse);
    expect(safe.contains('#'), isFalse);
  });

  test('safeUriForLog truncates very long non-sensitive values', () {
    final long = List.filled(240, 'a').join();
    final uri = Uri.parse('https://liuban.app/feed?x=$long');
    final safe = safeUriForLog(uri);
    expect(safe.contains('x=$long'), isFalse);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeUriForLog truncates very long path', () {
    final longPath = List.filled(400, 'p').join();
    final uri = Uri.parse('https://liuban.app/$longPath?x=ok');
    final safe = safeUriForLog(uri);
    expect(safe.contains('/$longPath'), isFalse);
    expect(safe.contains('x=ok'), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeUriForLog truncates very long host', () {
    final longHost = List.filled(180, 'h').join();
    final uri = Uri.parse('https://$longHost/feed?x=ok');
    final safe = safeUriForLog(uri);
    expect(safe.contains(longHost), isFalse);
    expect(safe.contains('/feed'), isTrue);
    expect(safe.contains('x=ok'), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeUriForLog truncates very long query keys', () {
    final longKey = List.filled(180, 'k').join();
    final uri = Uri.parse('https://liuban.app/feed?$longKey=ok');
    final safe = safeUriForLog(uri);
    expect(safe.contains('$longKey=ok'), isFalse);
    expect(safe.contains('ok'), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeUriForLog avoids truncated query-key collisions', () {
    final prefix = List.filled(90, 'k').join();
    final k1 = '${prefix}a';
    final k2 = '${prefix}b';
    final uri = Uri.parse('https://liuban.app/feed?$k1=v1&$k2=v2');
    final safe = safeUriForLog(uri);
    expect(safe.contains('v1'), isTrue);
    expect(safe.contains('v2'), isTrue);
    expect(safe.contains('_1='), isTrue);
  });

  test(
    'safeUriForLog keeps repeated keys and redacts all sensitive values',
    () {
      final uri = Uri.parse('https://liuban.app/login?x=1&x=2&token=a&token=b');
      final safe = safeUriForLog(uri);
      expect(safe.contains('x=1'), isTrue);
      expect(safe.contains('x=2'), isTrue);
      expect(safe.contains('token=%2A%2A%2A'), isTrue);
      expect(safe.contains('token=a'), isFalse);
      expect(safe.contains('token=b'), isFalse);
    },
  );

  test('safeUriForLog sorts repeated query values for deterministic logs', () {
    final uri = Uri.parse('https://liuban.app/feed?x=2&x=1');
    final safe = safeUriForLog(uri);
    expect(safe, 'https://liuban.app/feed?x=1&x=2');
  });

  test('safeUriForLog limits excessive query pairs', () {
    final manyPairs = List.generate(60, (i) => 'k$i=v$i').join('&');
    final safe = safeUriForLog(Uri.parse('https://liuban.app/feed?$manyPairs'));
    expect(safe.contains('k59=v59'), isFalse);
    expect(safe.contains('__liuban_log_truncated_pairs__='), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeUriForLog redacts sensitive keys case-insensitively', () {
    final uri = Uri.parse(
      'https://liuban.app/login?Token=abc&ID_Token=def&oauth_token=ghi&state=ok',
    );
    final safe = safeUriForLog(uri);
    expect(safe.contains('Token=%2A%2A%2A'), isTrue);
    expect(safe.contains('ID_Token=%2A%2A%2A'), isTrue);
    expect(safe.contains('oauth_token=%2A%2A%2A'), isTrue);
    expect(safe.contains('state=ok'), isTrue);
    expect(safe.contains('Token=abc'), isFalse);
    expect(safe.contains('ID_Token=def'), isFalse);
    expect(safe.contains('oauth_token=ghi'), isFalse);
  });

  test('safeUriForLog redacts password and secret-like keys', () {
    final uri = Uri.parse(
      'https://liuban.app/login?password=pwd&api_key=ak&client_secret=cs&state=ok&monkey=banana',
    );
    final safe = safeUriForLog(uri);
    expect(safe.contains('password=%2A%2A%2A'), isTrue);
    expect(safe.contains('api_key=%2A%2A%2A'), isTrue);
    expect(safe.contains('client_secret=%2A%2A%2A'), isTrue);
    expect(safe.contains('state=ok'), isTrue);
    expect(safe.contains('monkey=banana'), isTrue);
    expect(safe.contains('password=pwd'), isFalse);
    expect(safe.contains('api_key=ak'), isFalse);
    expect(safe.contains('client_secret=cs'), isFalse);
  });

  test('safeUriForLog redacts sensitive keys even when value empty', () {
    final uri = Uri.parse('https://liuban.app/login?token=&state=ok');
    final safe = safeUriForLog(uri);
    expect(safe.contains('token=%2A%2A%2A'), isTrue);
    expect(safe.contains('state=ok'), isTrue);
    expect(safe.contains('token='), isTrue);
  });

  test('safeUriForLog strips userinfo credentials', () {
    final uri = Uri.parse('https://user:pass@liuban.app/login?token=abc');
    final safe = safeUriForLog(uri);
    expect(safe.contains('user:pass@'), isFalse);
    expect(safe.contains('token=%2A%2A%2A'), isTrue);
  });

  test('safeUriForLog strips userinfo and fragment without query', () {
    final uri = Uri.parse('https://user:pass@liuban.app/feed#frag');
    final safe = safeUriForLog(uri);
    expect(safe.contains('user:pass@'), isFalse);
    expect(safe.contains('#'), isFalse);
    expect(safe, 'https://liuban.app/feed');
  });

  test('safeUriForLog normalizes empty path to root slash', () {
    final uri = Uri.parse('https://liuban.app?state=ok&token=abc');
    final safe = safeUriForLog(uri);
    expect(safe, 'https://liuban.app/?state=ok&token=%2A%2A%2A');
  });

  test('safeUriForLog preserves no-authority scheme path shape', () {
    final uri = Uri.parse('mailto:foo@bar.com?token=abc&subject=hi');
    final safe = safeUriForLog(uri);
    expect(safe, 'mailto:foo@bar.com?subject=hi&token=%2A%2A%2A');
  });

  test(
    'safeLocationForLog redacts sensitive query values and drops fragment',
    () {
      final safe = safeLocationForLog(
        '/reset-password?token=abc&password=pwd&state=ok#secret',
      );
      expect(safe.contains('token=%2A%2A%2A'), isTrue);
      expect(safe.contains('password=%2A%2A%2A'), isTrue);
      expect(safe.contains('state=ok'), isTrue);
      expect(safe.contains('token=abc'), isFalse);
      expect(safe.contains('password=pwd'), isFalse);
      expect(safe.contains('#'), isFalse);
    },
  );

  test('safeLocationForLog redacts sensitive keys on parse fallback', () {
    final safe = safeLocationForLog('/login?token=%&state=ok#frag');
    expect(safe.contains('token=%2A%2A%2A'), isTrue);
    expect(safe.contains('state=ok'), isTrue);
    expect(safe.contains('#'), isFalse);
    expect(safe.contains('token=%25'), isFalse);
  });

  test('safeLocationForLog truncates long non-sensitive values', () {
    final long = List.filled(240, 'b').join();
    final safe = safeLocationForLog('/feed?note=$long');
    expect(safe.contains('note=$long'), isFalse);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog truncates long query keys', () {
    final longKey = List.filled(180, 'z').join();
    final safe = safeLocationForLog('/feed?$longKey=v');
    expect(safe.contains('$longKey=v'), isFalse);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog avoids truncated query-key collisions', () {
    final prefix = List.filled(90, 'y').join();
    final k1 = '${prefix}a';
    final k2 = '${prefix}b';
    final safe = safeLocationForLog('/feed?$k1=v1&$k2=v2');
    expect(safe.contains('v1'), isTrue);
    expect(safe.contains('v2'), isTrue);
    expect(safe.contains('_1='), isTrue);
  });

  test('safeLocationForLog limits excessive query pairs', () {
    final manyPairs = List.generate(60, (i) => 'k$i=v$i').join('&');
    final safe = safeLocationForLog('/feed?$manyPairs');
    expect(safe.contains('k59=v59'), isFalse);
    expect(safe.contains('__liuban_log_truncated_pairs__='), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog avoids meta-key collision', () {
    final manyPairs = List.generate(60, (i) => 'k$i=v$i').join('&');
    final safe = safeLocationForLog(
      '/feed?__liuban_log_truncated_pairs__=user&$manyPairs',
    );
    expect(safe.contains('__liuban_log_truncated_pairs__=user'), isTrue);
    expect(safe.contains('__liuban_log_truncated_pairs___1='), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog fallback limits excessive query pairs', () {
    final manyPairs = List.generate(60, (i) => 'k$i=%').join('&');
    final safe = safeLocationForLog('/feed?$manyPairs#frag');
    expect(safe.contains('k59=%25'), isFalse);
    expect(safe.contains('__liuban_log_truncated_pairs__='), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test("safeUriForLog keeps user '__more__' key distinct from meta", () {
    final base = List.generate(60, (i) => 'k$i=v$i').join('&');
    final safe = safeUriForLog(
      Uri.parse('https://liuban.app/feed?__more__=user-value&$base'),
    );
    expect(safe.contains('__more__=user-value'), isTrue);
    expect(safe.contains('__liuban_log_truncated_pairs__='), isTrue);
  });

  test('safeUriForLog avoids meta-key collision with user query key', () {
    final base = List.generate(60, (i) => 'k$i=v$i').join('&');
    final safe = safeUriForLog(
      Uri.parse(
        'https://liuban.app/feed?__liuban_log_truncated_pairs__=user&$base',
      ),
    );
    expect(safe.contains('__liuban_log_truncated_pairs__=user'), isTrue);
    expect(safe.contains('__liuban_log_truncated_pairs___1='), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog truncates long path', () {
    final longPath = List.filled(400, 'q').join();
    final safe = safeLocationForLog('/$longPath?state=ok');
    expect(safe.contains('/$longPath'), isFalse);
    expect(safe.contains('state=ok'), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog fallback truncates long path', () {
    final longPath = List.filled(400, 'r').join();
    final safe = safeLocationForLog('/$longPath?token=%#frag');
    expect(safe.contains('/$longPath'), isFalse);
    expect(safe.contains('token=%2A%2A%2A'), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog fallback avoids meta-key collision', () {
    final manyPairs = List.generate(60, (i) => 'k$i=%').join('&');
    final safe = safeLocationForLog(
      '/feed?__liuban_log_truncated_pairs__=user&$manyPairs#frag',
    );
    expect(safe.contains('__liuban_log_truncated_pairs__=user'), isTrue);
    expect(safe.contains('__liuban_log_truncated_pairs___1='), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog fallback avoids truncated query-key collisions', () {
    final prefix = List.filled(90, 'z').join();
    final k1 = '${prefix}a';
    final k2 = '${prefix}b';
    final safe = safeLocationForLog('/feed?$k1=%&$k2=%');
    expect(safe.contains('_1='), isTrue);
    expect(safe.contains('truncated'), isTrue);
  });

  test('safeLocationForLog normalizes query-only location with root path', () {
    final safe = safeLocationForLog('?state=ok&token=abc');
    expect(safe, '/?state=ok&token=%2A%2A%2A');
  });

  test(
    'safeLocationForLog fallback normalizes query-only location with root path',
    () {
      final safe = safeLocationForLog('?state=ok&token=%#frag');
      expect(safe.contains('/?'), isTrue);
      expect(safe.contains('state=ok'), isTrue);
      expect(safe.contains('token=%2A%2A%2A'), isTrue);
      expect(safe.contains('#'), isFalse);
    },
  );

  test('safeLocationForLog normalizes missing-leading-slash path', () {
    final safe = safeLocationForLog('feed?state=ok&token=abc');
    expect(safe, '/feed?state=ok&token=%2A%2A%2A');
  });

  test('safeLocationForLog fallback normalizes missing-leading-slash path', () {
    final safe = safeLocationForLog('feed#frag');
    expect(safe, '/feed');
  });

  test('safeLocationForLog normalizes surrounding whitespace in path', () {
    final safe = safeLocationForLog('  /feed///sub/?state=ok  ');
    expect(safe, '/feed/sub?state=ok');
  });

  test(
    'safeLocationForLog normalizes duplicate slashes and trailing slash',
    () {
      final safe = safeLocationForLog('/feed///sub///?state=ok');
      expect(safe, '/feed/sub?state=ok');
    },
  );

  test('safeLocationForLog fallback normalizes backslashes and slashes', () {
    final safe = safeLocationForLog(r'\feed\\sub///?token=%#frag');
    expect(safe, '/feed/sub?token=%2A%2A%2A');
  });

  test('safeLocationForLog fallback sorts repeated query values', () {
    final safe = safeLocationForLog('/feed?x=a&x=%');
    expect(safe, '/feed?x=%25&x=a');
  });

  test('safeLocationForLog fallback handles consecutive separators safely', () {
    final safe = safeLocationForLog('/feed?a=1&&b=%#frag');
    expect(safe, '/feed?a=1&b=%25');
  });

  test('safeLocationForLog fallback handles leading/trailing separators', () {
    final safe = safeLocationForLog('/feed?&&a=%&&b=%&&#frag');
    expect(safe, '/feed?a=%25&b=%25');
  });

  test(
    'safeLocationForLog fallback truncates excessively long raw query input',
    () {
      final long = List.filled(6000, 'a').join();
      final safe = safeLocationForLog('/feed?x=$long%#frag');
      expect(safe.contains('truncated'), isTrue);
      expect(safe.contains('#'), isFalse);
    },
  );

  test(
    'safeLocationForLog fallback truncates excessively many raw query pairs',
    () {
      final many = List.generate(600, (i) => 'k$i=%').join('&');
      final safe = safeLocationForLog('/feed?$many#frag');
      expect(safe.contains('truncated'), isTrue);
      expect(safe.contains('#'), isFalse);
    },
  );
}
