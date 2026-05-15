import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/support_api.dart';

class _SupportCaptureAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;
  Map<String, dynamic>? lastJsonBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (options.data is Map) {
      lastJsonBody = Map<String, dynamic>.from(options.data as Map);
    } else {
      lastJsonBody = null;
    }
    final headers = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    return ResponseBody.fromString('{}', 200, headers: headers);
  }
}

class _ThrowingSupportAdapter implements HttpClientAdapter {
  _ThrowingSupportAdapter(this._exceptionFactory);

  final DioException Function(RequestOptions options) _exceptionFactory;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw _exceptionFactory(options);
  }
}

void main() {
  late Dio dio;
  late _SupportCaptureAdapter adapter;
  late SupportApi api;

  setUp(() {
    adapter = _SupportCaptureAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.httpClientAdapter = adapter;
    api = SupportApi(dio, apiPrefix: '/v1');
  });

  test('sendMessage posts text-only body to support endpoint', () async {
    await api.sendMessage(text: 'hello');
    expect(adapter.lastOptions?.method, 'POST');
    expect(adapter.lastOptions?.uri.path, '/v1/support/messages');
    expect(adapter.lastJsonBody?['text'], 'hello');
  });

  test(
    'sendMessage includes guest_token and contact_hint when provided',
    () async {
      await api.sendMessage(
        text: 'help',
        guestToken: 'guest-1',
        contactHint: '@river',
      );
      expect(adapter.lastOptions?.uri.path, '/v1/support/messages');
      expect(adapter.lastJsonBody?['text'], 'help');
      expect(adapter.lastJsonBody?['guest_token'], 'guest-1');
      expect(adapter.lastJsonBody?['contact_hint'], '@river');
    },
  );

  test('sendMessage rejects oversized text before network', () async {
    final long = ''.padRight(LiubanInputLimits.chatMessageMaxLength + 1, 'x');
    await expectLater(
      () => api.sendMessage(text: long),
      throwsA(
        isA<LiubanApiException>()
            .having(
              (e) => e.message,
              'message',
              ApiDevSemantics.chatMessageTooLongMessage(
                LiubanInputLimits.chatMessageMaxLength,
              ),
            )
            .having(
              (e) => e.code,
              'code',
              LiubanInputLimits.messageTextTooLongCode,
            ),
      ),
    );
    expect(adapter.lastOptions, isNull);
  });

  test(
    'sendMessage maps DioException response message to LiubanApiException',
    () async {
      final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      errDio.httpClientAdapter = _ThrowingSupportAdapter(
        (options) => DioException.badResponse(
          statusCode: 400,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 400,
            data: {'message': '客服服務暫時不可用'},
          ),
        ),
      );
      final errApi = SupportApi(errDio, apiPrefix: '/v1');

      await expectLater(
        () => errApi.sendMessage(text: 'help'),
        throwsA(
          isA<LiubanApiException>().having(
            (e) => e.message,
            'message',
            '客服服務暫時不可用',
          ),
        ),
      );
    },
  );

  test('sendMessage keeps Dio timeout message in LiubanApiException', () async {
    final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    errDio.httpClientAdapter = _ThrowingSupportAdapter(
      (options) => DioException.connectionTimeout(
        requestOptions: options,
        timeout: const Duration(seconds: 2),
      ),
    );
    final errApi = SupportApi(errDio, apiPrefix: '/v1');

    await expectLater(
      () => errApi.sendMessage(text: 'help'),
      throwsA(
        isA<LiubanApiException>().having(
          (e) => e.message,
          'message',
          contains('took longer than'),
        ),
      ),
    );
  });
}
