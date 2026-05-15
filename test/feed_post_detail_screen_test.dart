import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/data/api/feed_api.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/data/models/user_profile_dto.dart';
import 'package:liuban/features/feed/feed_post_detail_screen.dart';

class _AuthFetchMeNonApiException extends AuthApi {
  _AuthFetchMeNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<UserProfileDto> fetchMe() async {
    throw StateError('simulated fetchMe non-LiubanApiException');
  }
}

class _FeedGetPostNonApiException extends FeedApi {
  _FeedGetPostNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<FeedPostDto> getPost(String id) async {
    throw StateError('simulated getPost non-LiubanApiException');
  }
}

class _AlwaysErrorAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = jsonEncode({'message': 'post api fail'});
    return ResponseBody.fromString(
      body,
      500,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _DetailMenuAdapter implements HttpClientAdapter {
  _DetailMenuAdapter({required this.postAuthorId, required this.meUserId});

  final String postAuthorId;
  final String meUserId;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/auth/me')) {
      return ResponseBody.fromString(
        jsonEncode({'id': meUserId, 'custom_id': 'me'}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.path.contains('/feed/posts/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'post-1',
          'author_id': postAuthorId,
          'author_display': '作者',
          'body': 'detail body',
          'audience': 'public',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _FailThenSuccessPostAdapter implements HttpClientAdapter {
  var _postCalls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/feed/posts/')) {
      _postCalls += 1;
      if (_postCalls == 1) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'post api fail'}),
          500,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'post-1',
          'author_id': 'u1',
          'author_display': '作者',
          'body': 'reloaded body',
          'audience': 'public',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _SuccessDetailAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/feed/posts/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'ok-1',
          'author_id': 'u9',
          'author_display': '作者',
          'body': '純 API 載入單篇成功',
          'audience': 'public',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _FetchMeApiErrorAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/auth/me')) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'fetch me api fail'}),
        500,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.path.contains('/feed/posts/')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'post-1',
          'author_id': 'u1',
          'author_display': '作者',
          'body': 'detail body',
          'audience': 'public',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

Widget _buildHarness(
  Widget child, {
  HttpClientAdapter? adapter,
  String? accessToken,
}) {
  final container = AppContainer(
    guestDeviceId: 'test-device',
    logHttpTraffic: false,
    baseUrl: 'https://example.invalid',
    sessionTokens: AuthSessionTokens(accessToken: accessToken),
  );
  container.dio.httpClientAdapter = adapter ?? _AlwaysErrorAdapter();
  return AppContainerScope(
    container: container,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('loads detail from API', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        const FeedPostDetailScreen(postId: 'ok-1'),
        adapter: _SuccessDetailAdapter(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('純 API 載入單篇成功'), findsOneWidget);
  });

  testWidgets('shows load failed state when detail API fails', (tester) async {
    await tester.pumpWidget(
      _buildHarness(const FeedPostDetailScreen(postId: 'p1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.feedPostDetailLoadFailedTitle),
      findsOneWidget,
    );
    expect(find.text('post api fail'), findsOneWidget);
  });

  testWidgets('shows load failed state when post is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(const FeedPostDetailScreen(postId: 'missing-post')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.feedPostDetailLoadFailedTitle),
      findsOneWidget,
    );
    expect(find.text('返回'), findsOneWidget);
  });

  testWidgets('shows report and block for non-owned post', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        const FeedPostDetailScreen(postId: 'post-1'),
        adapter: _DetailMenuAdapter(postAuthorId: 'author-a', meUserId: 'me-1'),
        accessToken: 'token',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    expect(find.text('分享連結'), findsOneWidget);
    expect(find.text('檢舉'), findsOneWidget);
    expect(find.text('屏蔽此用戶'), findsOneWidget);
    expect(find.text('編輯'), findsNothing);
    expect(find.text('刪除'), findsNothing);
  });

  testWidgets('shows edit and delete for owned post', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        const FeedPostDetailScreen(postId: 'post-1'),
        adapter: _DetailMenuAdapter(postAuthorId: 'me-1', meUserId: 'me-1'),
        accessToken: 'token',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();

    expect(find.text('分享連結'), findsOneWidget);
    expect(find.text('編輯'), findsOneWidget);
    expect(find.text('刪除'), findsOneWidget);
    expect(find.text('檢舉'), findsNothing);
    expect(find.text('屏蔽此用戶'), findsNothing);
  });

  testWidgets('pull-to-refresh retries from error state and shows content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        const FeedPostDetailScreen(postId: 'post-1'),
        adapter: _FailThenSuccessPostAdapter(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.feedPostDetailLoadFailedTitle),
      findsOneWidget,
    );

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('reloaded body'), findsOneWidget);
    expect(
      find.text(ApiDevSemantics.feedPostDetailLoadFailedTitle),
      findsNothing,
    );
  });

  testWidgets(
    'shows fetchMe API error message when auth/me returns API error',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          const FeedPostDetailScreen(postId: 'post-1'),
          adapter: _FetchMeApiErrorAdapter(),
          accessToken: 'token',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('fetch me api fail'), findsOneWidget);
    },
  );

  testWidgets(
    'shows fetchMe generic snackbar when auth/me throws non-API error',
    (tester) async {
      final container = AppContainer(
        guestDeviceId: 'g',
        logHttpTraffic: false,
        baseUrl: 'https://example.invalid',
        sessionTokens: AuthSessionTokens(accessToken: 't'),
        authApi: _AuthFetchMeNonApiException(
          Dio(),
          apiPrefix: AppConfig.apiPrefix,
        ),
      );
      container.dio.httpClientAdapter = _SuccessDetailAdapter();

      await tester.pumpWidget(
        AppContainerScope(
          container: container,
          child: const MaterialApp(home: FeedPostDetailScreen(postId: 'ok-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ApiDevSemantics.feedPostDetailFetchMeFailedMessage),
        findsOneWidget,
      );
      expect(find.text('純 API 載入單篇成功'), findsOneWidget);
    },
  );

  testWidgets(
    'shows load failed generic snackbar when getPost throws non-API error',
    (tester) async {
      final container = AppContainer(
        guestDeviceId: 'g',
        logHttpTraffic: false,
        baseUrl: 'https://example.invalid',
        sessionTokens: AuthSessionTokens(accessToken: 't'),
        feedApi: _FeedGetPostNonApiException(
          Dio(),
          apiPrefix: AppConfig.apiPrefix,
        ),
      );

      await tester.pumpWidget(
        AppContainerScope(
          container: container,
          child: const MaterialApp(home: FeedPostDetailScreen(postId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ApiDevSemantics.feedPostDetailLoadFailedTitle),
        findsWidgets,
      );
    },
  );
}
