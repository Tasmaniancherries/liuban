import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/config/app_config.dart';
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

  test('AppContainer uses injected FeedApi', () {
    final custom = FeedApi(Dio(), apiPrefix: AppConfig.apiPrefix);
    final c = AppContainer(
      baseUrl: 'https://example.invalid',
      guestDeviceId: 'guest-feed',
      logHttpTraffic: false,
      feedApi: custom,
    );
    expect(identical(c.feed, custom), isTrue);
  });

  test('AppContainer uses injected AuthApi', () {
    final custom = AuthApi(Dio(), apiPrefix: AppConfig.apiPrefix);
    final c = AppContainer(
      baseUrl: 'https://example.invalid',
      guestDeviceId: 'guest-auth',
      logHttpTraffic: false,
      authApi: custom,
    );
    expect(identical(c.auth, custom), isTrue);
  });

  test('AppContainer authApiFactory receives session Dio', () {
    Dio? passedDio;
    final c = AppContainer(
      baseUrl: 'https://example.invalid',
      guestDeviceId: 'guest-aff',
      logHttpTraffic: false,
      authApiFactory: (dio) {
        passedDio = dio;
        return AuthApi(dio, apiPrefix: AppConfig.apiPrefix);
      },
    );
    expect(identical(passedDio, c.dio), isTrue);
  });

  test('AppContainer uses injected PromotionApi', () {
    final custom = PromotionApi(Dio(), apiPrefix: AppConfig.apiPrefix);
    final c = AppContainer(
      baseUrl: 'https://example.invalid',
      guestDeviceId: 'guest-promo',
      logHttpTraffic: false,
      promotionApi: custom,
    );
    expect(identical(c.promotion, custom), isTrue);
  });

  test('AppContainer uses injected FriendsApi', () {
    final custom = FriendsApi(Dio(), apiPrefix: AppConfig.apiPrefix);
    final c = AppContainer(
      baseUrl: 'https://example.invalid',
      guestDeviceId: 'guest-friends',
      logHttpTraffic: false,
      friendsApi: custom,
    );
    expect(identical(c.friends, custom), isTrue);
  });

  test('AppContainer friendsApiFactory receives session Dio', () {
    Dio? passedDio;
    final c = AppContainer(
      baseUrl: 'https://example.invalid',
      guestDeviceId: 'guest-fff',
      logHttpTraffic: false,
      friendsApiFactory: (dio) {
        passedDio = dio;
        return FriendsApi(dio, apiPrefix: AppConfig.apiPrefix);
      },
    );
    expect(identical(passedDio, c.dio), isTrue);
  });
}
