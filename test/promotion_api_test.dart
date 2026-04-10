import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/data/api/promotion_api.dart';

class _PromotionCaptureAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    final path = options.uri.path;
    final headers = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (path.endsWith('/promotions')) {
      return ResponseBody.fromString(
        jsonEncode([
          {
            'id': 'pm1',
            'title': 'T',
            'subtitle': 'S',
            'published_at': '2026-01-01',
            'body': 'B',
          },
        ]),
        200,
        headers: headers,
      );
    }
    if (path.contains('/promotions/')) {
      return ResponseBody.fromString(
        '{"id":"p1","title":"T1","subtitle":"S1","published_at":"2026-01-02","body":"B1"}',
        200,
        headers: headers,
      );
    }
    return ResponseBody.fromString('{}', 404, headers: headers);
  }
}

void main() {
  late Dio dio;
  late _PromotionCaptureAdapter adapter;
  late PromotionApi api;

  setUp(() {
    adapter = _PromotionCaptureAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.httpClientAdapter = adapter;
    api = PromotionApi(dio, apiPrefix: '/v1');
  });

  test('listPromotions hits /v1/promotions and maps list', () async {
    final list = await api.listPromotions();
    expect(adapter.lastOptions?.uri.path, '/v1/promotions');
    expect(list.single.id, 'pm1');
    expect(list.single.title, 'T');
  });

  test('getPromotion encodes id in path and maps dto', () async {
    final dto = await api.getPromotion('p 1/x');
    expect(adapter.lastOptions?.uri.path, '/v1/promotions/p%201%2Fx');
    expect(dto.id, 'p1');
    expect(dto.body, 'B1');
  });
}
