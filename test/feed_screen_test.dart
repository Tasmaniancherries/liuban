import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/data/api/feed_api.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/data/models/user_profile_dto.dart';
import 'package:liuban/features/feed/feed_screen.dart';

/// 模擬 [AuthApi.fetchMe] 拋出非 [LiubanApiException]，對應 [FeedScreen] 內載入本人 id 的 generic [catch]。
class _AuthFetchMeNonApiException extends AuthApi {
  _AuthFetchMeNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<UserProfileDto> fetchMe() async {
    throw StateError('simulated fetchMe non-LiubanApiException');
  }
}

/// 模擬 [FeedApi.listPublicFeed] 拋出非 [LiubanApiException]（例如未預期錯誤），
/// 對應公開列表第一頁載入的 generic [catch]（見 [FeedScreen] 內部實作）。
class _FeedPublicListNonApiException extends FeedApi {
  _FeedPublicListNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<List<FeedPostDto>> listPublicFeed({
    int page = 1,
    int pageSize = 20,
  }) async {
    throw StateError('simulated non-LiubanApiException');
  }
}

/// 第一頁成功（20 筆）、第二頁拋出非 [LiubanApiException]，對應「載入更多」的 generic [catch]。
class _FeedPublicLoadMoreNonApiException extends FeedApi {
  _FeedPublicLoadMoreNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<List<FeedPostDto>> listPublicFeed({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (page == 1) {
      return List<FeedPostDto>.generate(
        20,
        (i) => FeedPostDto(
          id: 'lm1_$i',
          authorId: 'u',
          authorDisplay: '作者',
          body: '第1頁 $i',
          audience: 'public',
        ),
      );
    }
    throw StateError('simulated load more non-LiubanApiException');
  }
}

class _FeedPublicAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/feed/public')) {
      return ResponseBody.fromString(
        jsonEncode([
          {
            'id': 'p1',
            'author_id': 'u1',
            'author_display': '測試作者',
            'body': '公開動態測試內文',
            'audience': 'public',
          },
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'unexpected'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

/// 第一頁 GET 失敗（顯示錯誤 SnackBar，不使用 mock 列表）。
class _FeedPublicFirstPageErrorAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/feed/public')) {
      return ResponseBody.fromString(
        jsonEncode({'message': '廣場列表測試錯誤'}),
        502,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'unexpected'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

/// 第一頁 20 筆以啟用「載入更多」；第二頁失敗。
class _FeedPublicLoadMoreErrorAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/feed/public')) {
      final page =
          int.tryParse(options.uri.queryParameters['page'] ?? '1') ?? 1;
      if (page == 1) {
        final posts = List<Map<String, dynamic>>.generate(
          20,
          (i) => {
            'id': 'page1_$i',
            'author_id': 'u1',
            'author_display': '作者',
            'body': '第1頁 $i',
            'audience': 'public',
          },
        );
        return ResponseBody.fromString(
          jsonEncode(posts),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      if (page == 2) {
        return ResponseBody.fromString(
          jsonEncode({'message': '載入更多測試錯誤'}),
          503,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
    }
    return ResponseBody.fromString(
      jsonEncode({'message': 'unexpected'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  testWidgets('shows app bar and loads public feed from API', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _FeedPublicAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: AppSession(),
          child: const MaterialApp(home: FeedScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('留伴 · 廣場'), findsOneWidget);
    expect(find.text('公開'), findsOneWidget);
    expect(find.text('本校'), findsOneWidget);
    expect(find.text('好友'), findsOneWidget);
    expect(find.text('公開動態測試內文'), findsOneWidget);
  });

  testWidgets('first page API error shows snackbar and empty feed', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _FeedPublicFirstPageErrorAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: AppSession(),
          child: const MaterialApp(home: FeedScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('廣場列表測試錯誤'), findsOneWidget);
    expect(find.text('暫無動態'), findsOneWidget);
  });

  testWidgets('first page non-API error shows generic failure snackbar', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
      feedApi: _FeedPublicListNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: AppSession(),
          child: const MaterialApp(home: FeedScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.feedInitialLoadFailedMessage),
      findsOneWidget,
    );
    expect(find.text('暫無動態'), findsOneWidget);
  });

  testWidgets('load more API error shows snackbar', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _FeedPublicLoadMoreErrorAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: AppSession(),
          child: const MaterialApp(home: FeedScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final verticalScrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axis == Axis.vertical,
    );
    await tester.drag(verticalScrollable.first, const Offset(0, -8000));
    await tester.pumpAndSettle();

    expect(find.text('載入更多'), findsOneWidget);
    await tester.tap(find.text('載入更多'));
    await tester.pumpAndSettle();

    expect(find.text('載入更多測試錯誤'), findsOneWidget);
  });

  testWidgets('load more non-API error shows generic snackbar', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
      feedApi: _FeedPublicLoadMoreNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: AppSession(),
          child: const MaterialApp(home: FeedScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final verticalScrollable = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axis == Axis.vertical,
    );
    await tester.drag(verticalScrollable.first, const Offset(0, -8000));
    await tester.pumpAndSettle();

    expect(find.text('載入更多'), findsOneWidget);
    await tester.tap(find.text('載入更多'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.feedLoadMoreFailedMessage),
      findsOneWidget,
    );
  });

  testWidgets('fetchMe non-API error shows generic snackbar', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

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
    container.dio.httpClientAdapter = _FeedPublicAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: AppSession(),
          child: const MaterialApp(home: FeedScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.feedStreamFetchMeFailedMessage),
      findsOneWidget,
    );
    expect(find.text('公開動態測試內文'), findsOneWidget);
  });
}
