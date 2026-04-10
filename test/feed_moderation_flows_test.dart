import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/features/feed/feed_report_flow.dart';

class _BlockUserAdapter implements HttpClientAdapter {
  _BlockUserAdapter({required this.statusCode, this.errorMessage});

  final int statusCode;
  final String? errorMessage;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' &&
        p.endsWith('/friends/blocks') &&
        !p.contains('/remove')) {
      if (statusCode >= 400) {
        return ResponseBody.fromString(
          jsonEncode({'message': errorMessage ?? 'block error'}),
          statusCode,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      return ResponseBody.fromString(
        '{}',
        statusCode,
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

class _DeletePostAdapter implements HttpClientAdapter {
  _DeletePostAdapter({required this.statusCode, this.errorMessage});

  final int statusCode;
  final String? errorMessage;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'DELETE' && p.contains('/feed/posts/')) {
      if (statusCode >= 400) {
        return ResponseBody.fromString(
          jsonEncode({'message': errorMessage ?? 'delete error'}),
          statusCode,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      return ResponseBody.fromString(
        '{}',
        statusCode,
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

Widget _blockHarness(HttpClientAdapter adapter) {
  final container = AppContainer(
    guestDeviceId: 'test-device',
    logHttpTraffic: false,
    baseUrl: 'https://example.invalid',
    sessionTokens: AuthSessionTokens(accessToken: 't'),
  );
  container.dio.httpClientAdapter = adapter;
  return AppContainerScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => runBlockUserFlow(context, userId: 'peer-1'),
              child: const Text('block'),
            );
          },
        ),
      ),
    ),
  );
}

Widget _deleteHarness(HttpClientAdapter adapter) {
  final container = AppContainer(
    guestDeviceId: 'test-device',
    logHttpTraffic: false,
    baseUrl: 'https://example.invalid',
    sessionTokens: AuthSessionTokens(accessToken: 't'),
  );
  container.dio.httpClientAdapter = adapter;
  return AppContainerScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => runDeleteOwnPostFlow(context, postId: 'post-1'),
              child: const Text('delete'),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  group('runBlockUserFlow', () {
    testWidgets('confirm submits block and shows success snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _blockHarness(_BlockUserAdapter(statusCode: 200)),
      );
      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('屏蔽'));
      await tester.pumpAndSettle();
      expect(find.text('已提交屏蔽，內容將依後端策略更新'), findsOneWidget);
    });

    testWidgets('cancel does not call block or show success snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _blockHarness(_BlockUserAdapter(statusCode: 200)),
      );
      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('已提交屏蔽，內容將依後端策略更新'), findsNothing);
    });

    testWidgets('API error shows message in snackbar', (tester) async {
      await tester.pumpWidget(
        _blockHarness(
          _BlockUserAdapter(statusCode: 403, errorMessage: 'cannot block'),
        ),
      );
      await tester.tap(find.text('block'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('屏蔽'));
      await tester.pumpAndSettle();
      expect(find.text('cannot block'), findsOneWidget);
    });
  });

  group('runDeleteOwnPostFlow', () {
    testWidgets('confirm deletes and shows success snackbar', (tester) async {
      await tester.pumpWidget(
        _deleteHarness(_DeletePostAdapter(statusCode: 200)),
      );
      await tester.tap(find.text('delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('刪除'));
      await tester.pumpAndSettle();
      expect(find.text('已刪除'), findsOneWidget);
    });

    testWidgets('cancel does not delete or show success snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _deleteHarness(_DeletePostAdapter(statusCode: 200)),
      );
      await tester.tap(find.text('delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('已刪除'), findsNothing);
    });

    testWidgets('API error shows message in snackbar', (tester) async {
      await tester.pumpWidget(
        _deleteHarness(
          _DeletePostAdapter(statusCode: 409, errorMessage: 'cannot delete'),
        ),
      );
      await tester.tap(find.text('delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('刪除'));
      await tester.pumpAndSettle();
      expect(find.text('cannot delete'), findsOneWidget);
    });
  });
}
