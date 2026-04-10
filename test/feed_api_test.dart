import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/data/api/feed_api.dart';

class _FeedCaptureAdapter implements HttpClientAdapter {
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

    final p = options.uri.path;
    final q = options.uri.queryParameters;
    final jsonHeaders = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };

    if (p.endsWith('/feed/public')) {
      return ResponseBody.fromString(
        jsonEncode([
          {'id': 'pub1', 'author_id': 'u', 'author_display': 'A', 'body': 'b'},
        ]),
        200,
        headers: jsonHeaders,
      );
    }
    if (p.endsWith('/feed/school')) {
      return ResponseBody.fromString(
        jsonEncode([
          {'id': 'sch1', 'author_id': 'u', 'author_display': 'S', 'body': 'b'},
        ]),
        200,
        headers: jsonHeaders,
      );
    }
    if (p.endsWith('/feed/friends')) {
      return ResponseBody.fromString(
        jsonEncode([
          {'id': 'fr1', 'author_id': 'u', 'author_display': 'F', 'body': 'b'},
        ]),
        200,
        headers: jsonHeaders,
      );
    }
    if (p.contains('/feed/posts/') && options.method == 'GET') {
      return ResponseBody.fromString(
        '{"id":"p1","author_id":"u","author_display":"A","body":"detail"}',
        200,
        headers: jsonHeaders,
      );
    }
    if (p.endsWith('/feed/posts') && options.method == 'POST') {
      // Return empty object to exercise local fallback in createPost.
      return ResponseBody.fromString('{}', 200, headers: jsonHeaders);
    }
    if (p.contains('/feed/posts/') && options.method == 'PATCH') {
      // Return empty object to exercise local fallback in updatePost.
      return ResponseBody.fromString('{}', 200, headers: jsonHeaders);
    }
    if (p.endsWith('/report') && options.method == 'POST') {
      return ResponseBody.fromString('{}', 200, headers: jsonHeaders);
    }
    if (p.contains('/feed/posts/') && options.method == 'DELETE') {
      return ResponseBody.fromString('{}', 200, headers: jsonHeaders);
    }

    return ResponseBody.fromString(
      jsonEncode({'path': p, 'query': q}),
      404,
      headers: jsonHeaders,
    );
  }
}

void main() {
  late Dio dio;
  late _FeedCaptureAdapter adapter;
  late FeedApi api;

  setUp(() {
    adapter = _FeedCaptureAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.httpClientAdapter = adapter;
    api = FeedApi(dio, apiPrefix: '/v1');
  });

  test('list*Feed use expected paths and pagination query', () async {
    final pub = await api.listPublicFeed(page: 2, pageSize: 9);
    expect(adapter.lastOptions?.uri.path, '/v1/feed/public');
    expect(adapter.lastOptions?.uri.queryParameters['page'], '2');
    expect(adapter.lastOptions?.uri.queryParameters['page_size'], '9');
    expect(pub.single.id, 'pub1');

    final school = await api.listSchoolFeed(page: 3, pageSize: 7);
    expect(adapter.lastOptions?.uri.path, '/v1/feed/school');
    expect(adapter.lastOptions?.uri.queryParameters['page'], '3');
    expect(adapter.lastOptions?.uri.queryParameters['page_size'], '7');
    expect(school.single.id, 'sch1');

    final friends = await api.listFriendsFeed(page: 4, pageSize: 5);
    expect(adapter.lastOptions?.uri.path, '/v1/feed/friends');
    expect(adapter.lastOptions?.uri.queryParameters['page'], '4');
    expect(adapter.lastOptions?.uri.queryParameters['page_size'], '5');
    expect(friends.single.id, 'fr1');
  });

  test('getPost encodes post id in path', () async {
    final dto = await api.getPost('a b/1');
    expect(adapter.lastOptions?.uri.path, '/v1/feed/posts/a%20b%2F1');
    expect(dto.id, 'p1');
    expect(dto.body, 'detail');
  });

  test('createPost posts payload and falls back on empty response', () async {
    final dto = await api.createPost(
      body: 'hello',
      audienceApiValue: 'public',
      hideSchool: true,
    );
    expect(adapter.lastOptions?.uri.path, '/v1/feed/posts');
    expect(adapter.lastJsonBody?['body'], 'hello');
    expect(adapter.lastJsonBody?['audience'], 'public');
    expect(adapter.lastJsonBody?['hide_school'], isTrue);
    expect(dto.id, 'local');
    expect(dto.body, 'hello');
    expect(dto.hideSchool, isTrue);
  });

  test(
    'updatePost patches encoded id and falls back on empty response',
    () async {
      final dto = await api.updatePost(
        postId: 'p 1',
        body: 'new',
        audienceApiValue: 'friends',
        hideSchool: false,
      );
      expect(adapter.lastOptions?.method, 'PATCH');
      expect(adapter.lastOptions?.uri.path, '/v1/feed/posts/p%201');
      expect(adapter.lastJsonBody?['body'], 'new');
      expect(adapter.lastJsonBody?['audience'], 'friends');
      expect(adapter.lastJsonBody?['hide_school'], isFalse);
      expect(dto.id, 'p 1');
      expect(dto.body, 'new');
    },
  );

  test('reportPost includes reason only when provided', () async {
    await api.reportPost(postId: 'p 1', reason: 'spam');
    expect(adapter.lastOptions?.uri.path, '/v1/feed/posts/p%201/report');
    expect(adapter.lastJsonBody?['reason'], 'spam');

    await api.reportPost(postId: 'p 2');
    expect(adapter.lastOptions?.uri.path, '/v1/feed/posts/p%202/report');
    expect(adapter.lastJsonBody, isEmpty);
  });

  test('deletePost encodes id and uses DELETE method', () async {
    await api.deletePost('p 9');
    expect(adapter.lastOptions?.method, 'DELETE');
    expect(adapter.lastOptions?.uri.path, '/v1/feed/posts/p%209');
  });
}
