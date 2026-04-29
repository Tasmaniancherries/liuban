import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/feed_api.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/features/feed/compose_post_screen.dart';

class _FeedCreatePostNonApiException extends FeedApi {
  _FeedCreatePostNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<FeedPostDto> createPost({
    required String body,
    required String audienceApiValue,
    required bool hideSchool,
  }) async {
    throw StateError('simulated createPost non-LiubanApiException');
  }
}

class _FeedGetPostNonApiException extends FeedApi {
  _FeedGetPostNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<FeedPostDto> getPost(String id) async {
    throw StateError('simulated getPost non-LiubanApiException');
  }
}

class _CreatePostAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' && p.endsWith('/feed/posts')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'new1',
          'author_id': 'me',
          'author_display': '我',
          'body': '測試發佈',
          'audience': 'public',
        }),
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

Finder _composePublishButton() {
  return find.descendant(
    of: find.byType(ComposePostScreen),
    matching: find.text('發佈'),
  );
}

void _bindTallSurface(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  testWidgets('body input is clamped to max length', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _CreatePostAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ComposePostScreen()),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'a' * 2001);
    await tester.pump();
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text.length, 2000);
  });

  testWidgets('empty body shows validation snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _CreatePostAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ComposePostScreen()),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();

    await tester.tap(_composePublishButton());
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.composePostBodyEmptyMessage),
      findsOneWidget,
    );
  });

  testWidgets('submit creates post and pops with summary', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _CreatePostAdapter();

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/compose'),
                child: const Text('OPEN_COMPOSE'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/compose',
          builder: (context, state) => const ComposePostScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPEN_COMPOSE'));
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();

    await tester.enterText(find.byType(TextField), '測試發佈內文');
    await tester.pump();

    await tester.tap(_composePublishButton());
    await tester.pumpAndSettle();

    expect(find.text('OPEN_COMPOSE'), findsOneWidget);
    expect(find.text('發佈動態'), findsNothing);
  });

  testWidgets('submit non-API error shows generic snackbar', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      feedApi: _FeedCreatePostNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: ComposePostScreen()),
      ),
    );
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'generic 失敗測試內文');
    await tester.pump();

    await tester.tap(_composePublishButton());
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.composePostSubmitGenericFailureMessage),
      findsOneWidget,
    );
  });

  testWidgets('edit bootstrap non-API error shows snackbar and pops', (
    tester,
  ) async {
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

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/compose-edit'),
                child: const Text('OPEN_EDIT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/compose-edit',
          builder: (context, state) =>
              const ComposePostScreen(editingPostId: 'edit-1'),
        ),
      ],
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPEN_EDIT'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.feedPostDetailLoadFailedTitle),
      findsOneWidget,
    );
    expect(find.text('OPEN_EDIT'), findsOneWidget);
  });
}
