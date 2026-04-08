import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:liuban/core/config/app_config.dart";
import "package:liuban/core/network/auth_session_tokens.dart";
import "package:liuban/core/network/token_refresh_interceptor.dart";

class DioClient {
  DioClient._();
  static const int _kMaxNetworkLogChars = 1500;

  static final RegExp _kBearerTokenRe = RegExp(
    r"((?:Authorization|Proxy-Authorization):\s*Bearer\s+)[^\s,]+",
    caseSensitive: false,
  );
  static final RegExp _kTokenAuthRe = RegExp(
    r"((?:Authorization|Proxy-Authorization):\s*Token\s+)[^\s,]+",
    caseSensitive: false,
  );
  static final RegExp _kBasicAuthRe = RegExp(
    r"((?:Authorization|Proxy-Authorization):\s*Basic\s+)[^\s,]+",
    caseSensitive: false,
  );
  static final RegExp _kDigestAuthRe = RegExp(
    r"((?:Authorization|Proxy-Authorization):\s*Digest\s+)[^\r\n]+",
    caseSensitive: false,
  );
  static final RegExp _kApiKeyHeaderRe = RegExp(
    r"((?:^|\s)(?:X-API-Key|Api-Key|X-Access-Key):\s*)([^\r\n]+)",
    caseSensitive: false,
  );
  static final RegExp _kTokenLikeHeaderRe = RegExp(
    r"((?:^|\s)(?:X-Auth-Token|X-Access-Token|X-Refresh-Token|X-CSRF-Token):\s*)([^\r\n]+)",
    caseSensitive: false,
  );
  static final RegExp _kGenericSensitiveHeaderRe = RegExp(
    r"((?:^|\s)(?:[A-Za-z0-9-]*(?:token|secret|password|api[-_]?key|access[-_]?key)[A-Za-z0-9-]*):\s*)([^\r\n]+)",
    caseSensitive: false,
  );
  static final RegExp _kUrlUserInfoRe = RegExp(
    r"((?:https?|wss?)://)[^/\s:@]+:[^/\s@]*@",
    caseSensitive: false,
  );
  static final RegExp _kJsonPasswordRe = RegExp(
    r'("password"\s*:\s*")[^"]*(")',
    caseSensitive: false,
  );
  static final RegExp _kJsonTokenRe = RegExp(
    r'("(?:access[_-]?token|refresh[_-]?token|id[_-]?token|token)"\s*:\s*")[^"]*(")',
    caseSensitive: false,
  );
  static final RegExp _kCookieHeaderRe = RegExp(
    r"((?:^|\s)(?:Cookie|Set-Cookie):\s*)([^\r\n]+)",
    caseSensitive: false,
  );
  static final RegExp _kUrlSensitiveQueryRe = RegExp(
    r"([?&])((?:[^=&]*token[^=&]*|code|password|passwd|secret|api[_-]?key|private[_-]?key|access[_-]?key|client[_-]?secret))=([^&#\s]*)",
    caseSensitive: false,
  );
  static final RegExp _kFormSensitivePairRe = RegExp(
    r"((?:^|[&\s])(?:[^=&\s]*token[^=&\s]*|code|password|passwd|secret|api[_-]?key|private[_-]?key|access[_-]?key|client[_-]?secret))=([^&\s]*)",
    caseSensitive: false,
  );

  @visibleForTesting
  static String sanitizeNetworkLogLine(String line) {
    var s = line;
    s = s.replaceAllMapped(_kBearerTokenRe, (m) => "${m[1]}***");
    s = s.replaceAllMapped(_kTokenAuthRe, (m) => "${m[1]}***");
    s = s.replaceAllMapped(_kBasicAuthRe, (m) => "${m[1]}***");
    s = s.replaceAllMapped(_kDigestAuthRe, (m) => "${m[1]}***");
    s = s.replaceAllMapped(_kApiKeyHeaderRe, (m) => "${m[1]}***");
    s = s.replaceAllMapped(_kTokenLikeHeaderRe, (m) => "${m[1]}***");
    s = s.replaceAllMapped(_kGenericSensitiveHeaderRe, (m) => "${m[1]}***");
    s = s.replaceAllMapped(_kUrlUserInfoRe, (m) => "${m[1]}***@");
    s = s.replaceAllMapped(_kCookieHeaderRe, (m) => "${m[1]}***");
    s = s.replaceAllMapped(_kJsonPasswordRe, (m) => '${m[1]}***${m[2]}');
    s = s.replaceAllMapped(_kJsonTokenRe, (m) => '${m[1]}***${m[2]}');
    s = s.replaceAllMapped(_kUrlSensitiveQueryRe, (m) => "${m[1]}${m[2]}=***");
    s = s.replaceAllMapped(_kFormSensitivePairRe, (m) => "${m[1]}=***");
    if (s.length > _kMaxNetworkLogChars) {
      return "${s.substring(0, _kMaxNetworkLogChars)}…(truncated ${s.length - _kMaxNetworkLogChars} chars)";
    }
    return s;
  }

  /// [sessionDio]：帶 Auth + Log + 401 自動 refresh；[plainDio]：僅用於 refresh 請求，避免攔截器循環。
  ///
  /// [logTraffic]：除錯時列印請求／回應；單元測試可傳 `false` 避免洗版。
  static Dio createSessionDio({
    required AuthSessionTokens sessionTokens,
    required Dio plainDio,
    String? baseUrl,
    bool logTraffic = true,
  }) {
    final root = baseUrl ?? AppConfig.apiBaseUrl;
    final dio = Dio(
      BaseOptions(
        baseUrl: root,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: <String, dynamic>{
          Headers.acceptHeader: Headers.jsonContentType,
        },
        responseType: ResponseType.json,
        listFormat: ListFormat.multiCompatible,
      ),
    );

    dio.interceptors.add(_AuthInterceptor(sessionTokens));

    if (kDebugMode && logTraffic) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(sanitizeNetworkLogLine(o.toString())),
        ),
      );
    }

    dio.interceptors.add(
      TokenRefreshInterceptor(
        tokens: sessionTokens,
        plainDio: plainDio,
        sessionDio: dio,
      ),
    );

    return dio;
  }

  /// 不掛攔截器，與 [createSessionDio] 相同 baseUrl／逾時。
  static Dio createPlainDio({String? baseUrl}) {
    final root = baseUrl ?? AppConfig.apiBaseUrl;
    return Dio(
      BaseOptions(
        baseUrl: root,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: <String, dynamic>{
          Headers.acceptHeader: Headers.jsonContentType,
        },
        responseType: ResponseType.json,
        listFormat: ListFormat.multiCompatible,
      ),
    );
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokens);

  final AuthSessionTokens _tokens;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final t = _tokens.accessToken;
    if (t != null && t.isNotEmpty) {
      options.headers["Authorization"] = "Bearer $t";
    }
    handler.next(options);
  }
}
