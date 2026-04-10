import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/data/api/feed_api.dart';
import 'package:liuban/data/api/friends_api.dart';
import 'package:liuban/data/api/promotion_api.dart';
import 'package:liuban/data/api/support_api.dart';

void main() {
  test('AppContainer wires provided tokens, baseUrl, and API clients', () {
    final tokens = AuthSessionTokens(accessToken: 'a', refreshToken: 'r');
    final c = AppContainer(
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
      guestDeviceId: 'guest-1',
      logHttpTraffic: false,
    );

    expect(identical(c.sessionTokens, tokens), isTrue);
    expect(c.guestDeviceId, 'guest-1');
    expect(c.plainDio.options.baseUrl, 'https://example.invalid');
    expect(c.dio.options.baseUrl, 'https://example.invalid');

    expect(c.auth, isA<AuthApi>());
    expect(c.feed, isA<FeedApi>());
    expect(c.friends, isA<FriendsApi>());
    expect(c.promotion, isA<PromotionApi>());
    expect(c.support, isA<SupportApi>());
  });

  test('AppContainer creates tokens when omitted', () {
    final c = AppContainer(
      baseUrl: 'https://example.invalid',
      guestDeviceId: 'guest-2',
      logHttpTraffic: false,
    );
    expect(c.sessionTokens, isA<AuthSessionTokens>());
    expect(c.plainDio, isA<Dio>());
    expect(c.dio, isA<Dio>());
  });
}
