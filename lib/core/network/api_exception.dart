import "package:dio/dio.dart";

/// 統一由 [LiubanApiException.fromDio] 從 [DioException] 轉換。
class LiubanApiException implements Exception {
  LiubanApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.raw,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Object? raw;

  @override
  String toString() => "LiubanApiException($statusCode, $code): $message";

  static LiubanApiException fromDio(DioException e) {
    final res = e.response;
    final status = res?.statusCode;
    final data = res?.data;

    String? serverMsg;
    String? code;

    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      serverMsg = m["message"]?.toString() ?? m["detail"]?.toString();
      code = m["code"]?.toString();
    } else if (data is String && data.isNotEmpty) {
      serverMsg = data;
    }

    final msg = serverMsg ??
        e.message ??
        switch (e.type) {
          DioExceptionType.connectionTimeout => "連線逾時",
          DioExceptionType.sendTimeout => "送出逾時",
          DioExceptionType.receiveTimeout => "讀取逾時",
          DioExceptionType.badCertificate => "憑證錯誤",
          DioExceptionType.badResponse => "伺服器回應錯誤",
          DioExceptionType.cancel => "已取消",
          DioExceptionType.connectionError => "網路連線失敗",
          DioExceptionType.unknown => "未知錯誤",
        };

    return LiubanApiException(
      message: msg,
      statusCode: status,
      code: code,
      raw: e,
    );
  }
}
