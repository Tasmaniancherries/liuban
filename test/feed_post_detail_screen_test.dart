import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/features/feed/feed_post_detail_screen.dart';

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

Widget _buildHarness(Widget child) {
  final container = AppContainer(
    guestDeviceId: 'test-device',
    logHttpTraffic: false,
    baseUrl: 'https://example.invalid',
    sessionTokens: AuthSessionTokens(),
  );
  container.dio.httpClientAdapter = _AlwaysErrorAdapter();
  return AppContainerScope(
    container: container,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('shows fallback post content when detail API fails', (
    tester,
  ) async {
    const fallback = FeedPostDto(
      id: 'p1',
      authorId: 'u1',
      authorDisplay: '示例作者',
      body: 'fallback body',
      audience: 'public',
    );
    await tester.pumpWidget(
      _buildHarness(
        const FeedPostDetailScreen(postId: 'p1', fallback: fallback),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('fallback body'), findsOneWidget);
    expect(
      find.text(ApiDevSemantics.feedPostDetailFallbackBanner),
      findsOneWidget,
    );
    expect(find.text('post api fail'), findsOneWidget);
  });

  testWidgets('shows load failed state when no fallback is available', (
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
}
