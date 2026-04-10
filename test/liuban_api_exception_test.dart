import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/api_exception.dart';

RequestOptions _ro({String path = '/t'}) => RequestOptions(path: path);

void main() {
  group('LiubanApiException.fromDio', () {
    test('uses message from JSON map', () {
      final e = DioException(
        requestOptions: _ro(),
        response: Response(
          requestOptions: _ro(),
          statusCode: 422,
          data: <String, dynamic>{'message': 'validation failed'},
        ),
        type: DioExceptionType.badResponse,
      );
      final x = LiubanApiException.fromDio(e);
      expect(x.message, 'validation failed');
      expect(x.statusCode, 422);
      expect(x.code, isNull);
    });

    test('uses detail when message missing', () {
      final e = DioException(
        requestOptions: _ro(),
        response: Response(
          requestOptions: _ro(),
          statusCode: 400,
          data: <String, dynamic>{'detail': 'bad request'},
        ),
        type: DioExceptionType.badResponse,
      );
      final x = LiubanApiException.fromDio(e);
      expect(x.message, 'bad request');
    });

    test('uses code field from JSON map', () {
      final e = DioException(
        requestOptions: _ro(),
        response: Response(
          requestOptions: _ro(),
          statusCode: 400,
          data: <String, dynamic>{'message': 'oops', 'code': 'E123'},
        ),
        type: DioExceptionType.badResponse,
      );
      final x = LiubanApiException.fromDio(e);
      expect(x.code, 'E123');
      expect(x.message, 'oops');
    });

    test('uses string body', () {
      final e = DioException(
        requestOptions: _ro(),
        response: Response(
          requestOptions: _ro(),
          statusCode: 500,
          data: 'plain error',
        ),
        type: DioExceptionType.badResponse,
      );
      final x = LiubanApiException.fromDio(e);
      expect(x.message, 'plain error');
    });

    test('connection timeout maps to Chinese copy', () {
      final e = DioException(
        requestOptions: _ro(),
        type: DioExceptionType.connectionTimeout,
      );
      final x = LiubanApiException.fromDio(e);
      expect(x.message, '連線逾時');
      expect(x.statusCode, isNull);
    });

    test('cancel maps to Chinese copy', () {
      final e = DioException(
        requestOptions: _ro(),
        type: DioExceptionType.cancel,
      );
      expect(LiubanApiException.fromDio(e).message, '已取消');
    });

    test('fallback mapping covers other DioException types', () {
      final sendTimeout = LiubanApiException.fromDio(
        DioException(requestOptions: _ro(), type: DioExceptionType.sendTimeout),
      );
      final receiveTimeout = LiubanApiException.fromDio(
        DioException(
          requestOptions: _ro(),
          type: DioExceptionType.receiveTimeout,
        ),
      );
      final badCertificate = LiubanApiException.fromDio(
        DioException(
          requestOptions: _ro(),
          type: DioExceptionType.badCertificate,
        ),
      );
      final badResponse = LiubanApiException.fromDio(
        DioException(requestOptions: _ro(), type: DioExceptionType.badResponse),
      );
      final connectionError = LiubanApiException.fromDio(
        DioException(
          requestOptions: _ro(),
          type: DioExceptionType.connectionError,
        ),
      );
      final unknown = LiubanApiException.fromDio(
        DioException(requestOptions: _ro()),
      );

      expect(sendTimeout.message, '送出逾時');
      expect(receiveTimeout.message, '讀取逾時');
      expect(badCertificate.message, '憑證錯誤');
      expect(badResponse.message, '伺服器回應錯誤');
      expect(connectionError.message, '網路連線失敗');
      expect(unknown.message, '未知錯誤');
    });

    test('dio exception message is used when server body is absent', () {
      final e = DioException(
        requestOptions: _ro(),
        message: 'socket closed',
      );
      expect(LiubanApiException.fromDio(e).message, 'socket closed');
    });

    test('raw keeps original DioException instance', () {
      final e = DioException(
        requestOptions: _ro(),
        type: DioExceptionType.connectionError,
      );
      final x = LiubanApiException.fromDio(e);
      expect(identical(x.raw, e), isTrue);
    });

    test('toString includes status and code', () {
      final x = LiubanApiException(message: 'm', statusCode: 403, code: 'C');
      expect(x.toString(), 'LiubanApiException(403, C): m');
    });
  });
}
