import 'package:dio/dio.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/data/models/json_utils.dart';
import 'package:liuban/data/models/token_pair_dto.dart';

/// 與後端約定：**JSON** `POST .../auth/refresh`，body `{"refresh_token": "..."}`。
///
/// Bearer、TokenPair、401 與 plain Dio 刷新流程見 `docs/backend_auth_contract.md`。
/// 收到 401（且非登入／註冊／刷新路徑）時換發 access，並以 [QueuedInterceptor] 併發排隊重試原請求。
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor({
    required AuthSessionTokens tokens,
    required Dio plainDio,
    required Dio sessionDio,
  }) : _tokens = tokens,
       _plainDio = plainDio,
       _sessionDio = sessionDio;

  final AuthSessionTokens _tokens;
  final Dio _plainDio;
  final Dio _sessionDio;

  String get _refreshPath {
    final p = AppConfig.apiPrefix;
    if (p.startsWith('/')) {
      return '$p/auth/refresh';
    }
    return '/$p/auth/refresh';
  }

  bool _isAuthExemptPath(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh');
  }

  Future<TokenPairDto> _callRefresh(String refreshToken) async {
    final res = await _plainDio.post<dynamic>(
      _refreshPath,
      data: <String, dynamic>{'refresh_token': refreshToken},
    );
    return TokenPairDto.fromJson(asJsonMap(res.data));
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    if (_isAuthExemptPath(path)) {
      return handler.next(err);
    }

    if (err.requestOptions.extra['_refreshRetried'] == true) {
      _tokens.clear();
      return handler.next(err);
    }

    final refresh = _tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      _tokens.clear();
      return handler.next(err);
    }

    try {
      final pair = await _callRefresh(refresh);
      _tokens.applyPair(
        access: pair.accessToken,
        refresh: pair.refreshToken ?? refresh,
      );

      final ro = err.requestOptions;
      ro.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
      ro.extra['_refreshRetried'] = true;

      final clone = await _sessionDio.fetch<dynamic>(ro);
      handler.resolve(clone);
    } catch (e) {
      _tokens.clear();
      if (e is DioException) {
        return handler.next(e);
      }
      return handler.next(
        DioException(requestOptions: err.requestOptions, error: e),
      );
    }
  }
}
