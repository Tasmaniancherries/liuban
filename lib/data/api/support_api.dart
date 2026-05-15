import 'package:dio/dio.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/api_client_validation.dart';

/// 官方客服留言（訪客可呼叫）。
///
/// Body 欄位見 `docs/backend_domain_apis_contract.md`「客服」。
class SupportApi {
  SupportApi(this._dio, {required this.apiPrefix});

  final Dio _dio;
  final String apiPrefix;

  String _path(String relative) {
    if (relative.startsWith('/')) {
      return '$apiPrefix$relative';
    }
    return '$apiPrefix/$relative';
  }

  /// 訪客亦可呼叫；後端可用 guest_token 併線程。
  Future<void> sendMessage({
    required String text,
    String? guestToken,
    String? contactHint,
  }) async {
    assertTextWithinLimit(
      text: text,
      maxLength: LiubanInputLimits.chatMessageMaxLength,
      message: ApiDevSemantics.chatMessageTooLongMessage(
        LiubanInputLimits.chatMessageMaxLength,
      ),
      code: LiubanInputLimits.messageTextTooLongCode,
    );
    try {
      await _dio.post<dynamic>(
        _path('/support/messages'),
        data: <String, dynamic>{
          'text': text,
          'guest_token': ?guestToken,
          'contact_hint': ?contactHint,
        },
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }
}
