import "package:dio/dio.dart";
import "package:liuban/core/config/app_config.dart";
import "package:liuban/core/network/auth_session_tokens.dart";
import "package:liuban/core/network/dio_client.dart";
import "package:liuban/data/api/auth_api.dart";
import "package:liuban/data/api/feed_api.dart";
import "package:liuban/data/api/friends_api.dart";
import "package:liuban/data/api/promotion_api.dart";
import "package:liuban/data/api/support_api.dart";

/// 集中放置 [Dio]、token 与各域 API，供 UI 透過 [AppContainerScope] 取得。
class AppContainer {
  AppContainer({
    String? baseUrl,
    AuthSessionTokens? sessionTokens,
    required this.guestDeviceId,
    bool logHttpTraffic = true,
  }) : sessionTokens = sessionTokens ?? AuthSessionTokens() {
    final root = baseUrl ?? AppConfig.apiBaseUrl;
    plainDio = DioClient.createPlainDio(baseUrl: root);
    dio = DioClient.createSessionDio(
      sessionTokens: this.sessionTokens,
      plainDio: plainDio,
      baseUrl: root,
      logTraffic: logHttpTraffic,
    );
    auth = AuthApi(dio, apiPrefix: AppConfig.apiPrefix);
    feed = FeedApi(dio, apiPrefix: AppConfig.apiPrefix);
    friends = FriendsApi(dio, apiPrefix: AppConfig.apiPrefix);
    promotion = PromotionApi(dio, apiPrefix: AppConfig.apiPrefix);
    support = SupportApi(dio, apiPrefix: AppConfig.apiPrefix);
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
