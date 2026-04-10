import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
