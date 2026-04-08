import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/network/dio_client.dart';

/// Returns JSON `{"authorization": <Authorization header or null>}` for GET `/v1/me`.
class _EchoAuthAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final jsonHeaders = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (path.endsWith('/me') && options.method == 'GET') {
      final auth = options.headers['Authorization']?.toString();
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'authorization': auth}),
        200,
        headers: jsonHeaders,
      );
    }
    return ResponseBody.fromString('{}', 404, headers: jsonHeaders);
  }
}

void main() {
  const mockBase = 'https://mock.local';

  group('DioClient.createSessionDio', () {
    test('adds Bearer from AuthSessionTokens', () async {
      final tokens = AuthSessionTokens(accessToken: 'secret_access');
      final adapter = _EchoAuthAdapter();
      final plain = DioClient.createPlainDio(baseUrl: mockBase);
      plain.httpClientAdapter = adapter;

      final session = DioClient.createSessionDio(
        sessionTokens: tokens,
        plainDio: plain,
        baseUrl: mockBase,
        logTraffic: false,
      );
      session.httpClientAdapter = adapter;

      final res = await session.get<Map<String, dynamic>>('/v1/me');
      expect(res.data?['authorization'], 'Bearer secret_access');
    });

    test('omits Authorization when access token is empty', () async {
      final tokens = AuthSessionTokens();
      final adapter = _EchoAuthAdapter();
      final plain = DioClient.createPlainDio(baseUrl: mockBase);
      plain.httpClientAdapter = adapter;

      final session = DioClient.createSessionDio(
        sessionTokens: tokens,
        plainDio: plain,
        baseUrl: mockBase,
        logTraffic: false,
      );
      session.httpClientAdapter = adapter;

      final res = await session.get<Map<String, dynamic>>('/v1/me');
      expect(res.data?.containsKey('authorization'), isTrue);
      expect(res.data?['authorization'], isNull);
    });
  });

  group('DioClient.createPlainDio', () {
    test('does not inject Authorization header', () async {
      final adapter = _EchoAuthAdapter();
      final plain = DioClient.createPlainDio(baseUrl: mockBase);
      plain.httpClientAdapter = adapter;

      final res = await plain.get<Map<String, dynamic>>('/v1/me');
      expect(res.data?['authorization'], isNull);
    });
  });
}
