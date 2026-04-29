import 'package:dio/dio.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/network/dio_client.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/data/api/feed_api.dart';
import 'package:liuban/data/api/friends_api.dart';
import 'package:liuban/data/api/promotion_api.dart';
import 'package:liuban/data/api/support_api.dart';

/// 集中放置 [Dio]、token 与各域 API，供 UI 透過 [AppContainerScope] 取得。
class AppContainer {
  AppContainer({
    String? baseUrl,
    AuthSessionTokens? sessionTokens,
    required this.guestDeviceId,
    bool logHttpTraffic = true,
    AuthApi? authApi,
    AuthApi Function(Dio dio)? authApiFactory,
    FeedApi? feedApi,
    FriendsApi? friendsApi,
    FriendsApi Function(Dio dio)? friendsApiFactory,
    PromotionApi? promotionApi,
    SupportApi? supportApi,
  }) : sessionTokens = sessionTokens ?? AuthSessionTokens() {
    final root = baseUrl ?? AppConfig.apiBaseUrl;
    plainDio = DioClient.createPlainDio(baseUrl: root);
    dio = DioClient.createSessionDio(
      sessionTokens: this.sessionTokens,
      plainDio: plainDio,
      baseUrl: root,
      logTraffic: logHttpTraffic,
    );
    assert(
      authApi == null || authApiFactory == null,
      'Provide at most one of authApi and authApiFactory',
    );
    assert(
      friendsApi == null || friendsApiFactory == null,
      'Provide at most one of friendsApi and friendsApiFactory',
    );
    auth = authApiFactory != null
        ? authApiFactory(dio)
        : (authApi ?? AuthApi(dio, apiPrefix: AppConfig.apiPrefix));
    feed = feedApi ?? FeedApi(dio, apiPrefix: AppConfig.apiPrefix);
    friends = friendsApiFactory != null
        ? friendsApiFactory(dio)
        : (friendsApi ?? FriendsApi(dio, apiPrefix: AppConfig.apiPrefix));
    promotion =
        promotionApi ?? PromotionApi(dio, apiPrefix: AppConfig.apiPrefix);
    support = supportApi ?? SupportApi(dio, apiPrefix: AppConfig.apiPrefix);
  }

  final AuthSessionTokens sessionTokens;

  /// 訪客或未登入時傳給客服 API，便於對話串與頻率限制。
  final String guestDeviceId;

  late final Dio plainDio;
  late final Dio dio;
  late final AuthApi auth;
  late final FeedApi feed;
  late final FriendsApi friends;
  late final PromotionApi promotion;
  late final SupportApi support;
}
