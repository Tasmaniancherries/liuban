import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/data/api/friends_api.dart';

class _FriendsCaptureAdapter implements HttpClientAdapter {
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

    final path = options.uri.path;
    final method = options.method;
    final jsonHeaders = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };

    if (path.endsWith('/friends/inbox') && method == 'GET') {
      return ResponseBody.fromString(
        '{"items":[{"peer_id":"p1","peer_custom_id":"c1","preview":"hi"}]}',
        200,
        headers: jsonHeaders,
      );
    }
    if (path.endsWith('/friends/requests/incoming') && method == 'GET') {
      return ResponseBody.fromString(
        '[{"id":"r1","from_custom_id":"alice"}]',
        200,
        headers: jsonHeaders,
      );
    }
    if (path.endsWith('/friends/requests/outgoing') && method == 'GET') {
      return ResponseBody.fromString(
        '[{"id":"o1","to_custom_id":"bob","status":"pending"}]',
        200,
        headers: jsonHeaders,
      );
    }
    if (path.contains('/friends/dm/') &&
        path.endsWith('/messages') &&
        method == 'GET') {
      return ResponseBody.fromString(
        '[{"id":"m1","body":"hello","is_mine":false}]',
        200,
        headers: jsonHeaders,
      );
    }
    if (path.endsWith('/friends/blocks') && method == 'GET') {
      return ResponseBody.fromString(
        '{"items":[{"user_id":"u1","custom_id":"@x"}]}',
        200,
        headers: jsonHeaders,
      );
    }

    // Other operations only need success status for request-shape assertions.
    return ResponseBody.fromString('{}', 200, headers: jsonHeaders);
  }
}

class _ThrowingFriendsAdapter implements HttpClientAdapter {
  _ThrowingFriendsAdapter(this._exceptionFactory);

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
  late _FriendsCaptureAdapter adapter;
  late FriendsApi api;

  setUp(() {
    adapter = _FriendsCaptureAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.httpClientAdapter = adapter;
    api = FriendsApi(dio, apiPrefix: '/v1');
  });

  test('listInbox maps items payload', () async {
    final list = await api.listInbox();
    expect(adapter.lastOptions?.uri.path, '/v1/friends/inbox');
    expect(list.single.peerId, 'p1');
    expect(list.single.peerCustomId, 'c1');
  });

  test('sendFriendRequest posts target_custom_id', () async {
    await api.sendFriendRequest(targetCustomId: 'river');
    expect(adapter.lastOptions?.method, 'POST');
    expect(adapter.lastOptions?.uri.path, '/v1/friends/requests');
    expect(adapter.lastJsonBody?['target_custom_id'], 'river');
  });

  test('list incoming/outgoing requests use expected endpoints', () async {
    final incoming = await api.listIncomingRequests();
    expect(adapter.lastOptions?.uri.path, '/v1/friends/requests/incoming');
    expect(incoming.single.id, 'r1');

    final outgoing = await api.listOutgoingRequests();
    expect(adapter.lastOptions?.uri.path, '/v1/friends/requests/outgoing');
    expect(outgoing.single.id, 'o1');
  });

  test('respondToFriendRequest encodes id and posts accept flag', () async {
    await api.respondToFriendRequest(requestId: 'rq 1/x', accept: true);
    expect(
      adapter.lastOptions?.uri.path,
      '/v1/friends/requests/rq%201%2Fx/respond',
    );
    expect(adapter.lastJsonBody?['accept'], isTrue);
  });

  test('list/send dm messages use encoded peer id path', () async {
    final list = await api.listDmMessages(peerId: 'u 1/x');
    expect(adapter.lastOptions?.uri.path, '/v1/friends/dm/u%201%2Fx/messages');
    expect(list.single.id, 'm1');

    await api.sendDmMessage(peerId: 'u 1/x', text: 'yo');
    expect(adapter.lastOptions?.uri.path, '/v1/friends/dm/u%201%2Fx/messages');
    expect(adapter.lastJsonBody?['text'], 'yo');
  });

  test('block/list/unblock users use expected paths and payload', () async {
    await api.blockUser(userId: 'u1');
    expect(adapter.lastOptions?.uri.path, '/v1/friends/blocks');
    expect(adapter.lastJsonBody?['user_id'], 'u1');

    final blocked = await api.listBlockedUsers();
    expect(adapter.lastOptions?.uri.path, '/v1/friends/blocks');
    expect(blocked.single.userId, 'u1');

    await api.unblockUser(userId: 'u1');
    expect(adapter.lastOptions?.uri.path, '/v1/friends/blocks/remove');
    expect(adapter.lastJsonBody?['user_id'], 'u1');
  });

  test(
    'listBlockedUsers returns empty when payload shape is invalid',
    () async {
      dio.httpClientAdapter = _BrokenBlocksAdapter();
      api = FriendsApi(dio, apiPrefix: '/v1');
      final list = await api.listBlockedUsers();
      expect(list, isEmpty);
    },
  );

  test('sendFriendRequest maps DioException to LiubanApiException', () async {
    final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    errDio.httpClientAdapter = _ThrowingFriendsAdapter(
      (options) => DioException.badResponse(
        statusCode: 409,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 409,
          data: {'message': '你們已經是好友'},
        ),
      ),
    );
    final errApi = FriendsApi(errDio, apiPrefix: '/v1');

    await expectLater(
      () => errApi.sendFriendRequest(targetCustomId: 'river'),
      throwsA(
        isA<LiubanApiException>().having(
          (e) => e.message,
          'message',
          '你們已經是好友',
        ),
      ),
    );
  });

  test(
    'listIncomingRequests maps DioException to LiubanApiException',
    () async {
      final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      errDio.httpClientAdapter = _ThrowingFriendsAdapter(
        (options) => DioException.badResponse(
          statusCode: 500,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 500,
            data: {'message': '暫時無法讀取好友申請'},
          ),
        ),
      );
      final errApi = FriendsApi(errDio, apiPrefix: '/v1');

      await expectLater(
        errApi.listIncomingRequests,
        throwsA(
          isA<LiubanApiException>().having(
            (e) => e.message,
            'message',
            '暫時無法讀取好友申請',
          ),
        ),
      );
    },
  );

  test('listDmMessages maps DioException to LiubanApiException', () async {
    final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    errDio.httpClientAdapter = _ThrowingFriendsAdapter(
      (options) => DioException.badResponse(
        statusCode: 503,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 503,
          data: {'message': '私訊服務暫時不可用'},
        ),
      ),
    );
    final errApi = FriendsApi(errDio, apiPrefix: '/v1');

    await expectLater(
      () => errApi.listDmMessages(peerId: 'u1'),
      throwsA(
        isA<LiubanApiException>().having(
          (e) => e.message,
          'message',
          '私訊服務暫時不可用',
        ),
      ),
    );
  });

  test('unblockUser maps DioException to LiubanApiException', () async {
    final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    errDio.httpClientAdapter = _ThrowingFriendsAdapter(
      (options) => DioException.badResponse(
        statusCode: 403,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 403,
          data: {'message': '你沒有權限解除此屏蔽'},
        ),
      ),
    );
    final errApi = FriendsApi(errDio, apiPrefix: '/v1');

    await expectLater(
      () => errApi.unblockUser(userId: 'u1'),
      throwsA(
        isA<LiubanApiException>().having(
          (e) => e.message,
          'message',
          '你沒有權限解除此屏蔽',
        ),
      ),
    );
  });

  test('listInbox maps DioException to LiubanApiException', () async {
    final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    errDio.httpClientAdapter = _ThrowingFriendsAdapter(
      (options) => DioException.badResponse(
        statusCode: 503,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 503,
          data: {'message': '收件匣暫時不可用'},
        ),
      ),
    );
    final errApi = FriendsApi(errDio, apiPrefix: '/v1');

    await expectLater(
      errApi.listInbox,
      throwsA(
        isA<LiubanApiException>().having(
          (e) => e.message,
          'message',
          '收件匣暫時不可用',
        ),
      ),
    );
  });

  test(
    'respondToFriendRequest maps DioException to LiubanApiException',
    () async {
      final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      errDio.httpClientAdapter = _ThrowingFriendsAdapter(
        (options) => DioException.badResponse(
          statusCode: 404,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 404,
            data: {'message': '找不到此好友申請'},
          ),
        ),
      );
      final errApi = FriendsApi(errDio, apiPrefix: '/v1');

      await expectLater(
        () => errApi.respondToFriendRequest(requestId: 'r1', accept: true),
        throwsA(
          isA<LiubanApiException>().having(
            (e) => e.message,
            'message',
            '找不到此好友申請',
          ),
        ),
      );
    },
  );

  test(
    'listOutgoingRequests maps DioException to LiubanApiException',
    () async {
      final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      errDio.httpClientAdapter = _ThrowingFriendsAdapter(
        (options) => DioException.badResponse(
          statusCode: 500,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 500,
            data: {'message': '暫時無法讀取發送紀錄'},
          ),
        ),
      );
      final errApi = FriendsApi(errDio, apiPrefix: '/v1');

      await expectLater(
        errApi.listOutgoingRequests,
        throwsA(
          isA<LiubanApiException>().having(
            (e) => e.message,
            'message',
            '暫時無法讀取發送紀錄',
          ),
        ),
      );
    },
  );

  test('sendDmMessage maps DioException to LiubanApiException', () async {
    final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    errDio.httpClientAdapter = _ThrowingFriendsAdapter(
      (options) => DioException.badResponse(
        statusCode: 429,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 429,
          data: {'message': '傳送過於頻繁，請稍後再試'},
        ),
      ),
    );
    final errApi = FriendsApi(errDio, apiPrefix: '/v1');

    await expectLater(
      () => errApi.sendDmMessage(peerId: 'u1', text: 'hi'),
      throwsA(
        isA<LiubanApiException>().having(
          (e) => e.message,
          'message',
          '傳送過於頻繁，請稍後再試',
        ),
      ),
    );
  });

  test('blockUser maps DioException to LiubanApiException', () async {
    final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    errDio.httpClientAdapter = _ThrowingFriendsAdapter(
      (options) => DioException.badResponse(
        statusCode: 403,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 403,
          data: {'message': '你沒有權限屏蔽此用戶'},
        ),
      ),
    );
    final errApi = FriendsApi(errDio, apiPrefix: '/v1');

    await expectLater(
      () => errApi.blockUser(userId: 'u1'),
      throwsA(
        isA<LiubanApiException>().having(
          (e) => e.message,
          'message',
          '你沒有權限屏蔽此用戶',
        ),
      ),
    );
  });

  test('listBlockedUsers maps DioException to LiubanApiException', () async {
    final errDio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    errDio.httpClientAdapter = _ThrowingFriendsAdapter(
      (options) => DioException.badResponse(
        statusCode: 500,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 500,
          data: {'message': '暫時無法讀取屏蔽名單'},
        ),
      ),
    );
    final errApi = FriendsApi(errDio, apiPrefix: '/v1');

    await expectLater(
      errApi.listBlockedUsers,
      throwsA(
        isA<LiubanApiException>().having(
          (e) => e.message,
          'message',
          '暫時無法讀取屏蔽名單',
        ),
      ),
    );
  });
}

class _BrokenBlocksAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final jsonHeaders = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (options.uri.path.endsWith('/friends/blocks')) {
      return ResponseBody.fromString('{"oops":1}', 200, headers: jsonHeaders);
    }
    return ResponseBody.fromString('{}', 200, headers: jsonHeaders);
  }
}
