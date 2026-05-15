import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/feed_api.dart';
import 'package:liuban/features/feed/feed_report_flow.dart';

class _FeedReportReasonTooLong extends FeedApi {
  _FeedReportReasonTooLong(super.dio, {required super.apiPrefix});

  @override
  Future<void> reportPost({required String postId, String? reason}) async {
    throw LiubanApiException(
      message: ApiDevSemantics.feedReportReasonTooLongMessage(
        LiubanInputLimits.feedReportReasonMaxTotalLength,
      ),
      code: LiubanInputLimits.reportReasonTooLongCode,
    );
  }
}

class _FeedReportPostNonApiException extends FeedApi {
  _FeedReportPostNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<void> reportPost({required String postId, String? reason}) async {
    throw StateError('simulated reportPost non-LiubanApiException');
  }
}

class _ReportPostAdapter implements HttpClientAdapter {
  _ReportPostAdapter({required this.statusCode, this.errorMessage});

  final int statusCode;
  final String? errorMessage;
  String? lastReportReason;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' && p.endsWith('/report')) {
      final data = options.data;
      if (data is Map) {
        final r = data['reason'];
        lastReportReason = r is String ? r : r?.toString();
      } else {
        lastReportReason = null;
      }
      if (statusCode >= 400) {
        final body = jsonEncode({'message': errorMessage ?? 'error'});
        return ResponseBody.fromString(
          body,
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

Widget _harness(HttpClientAdapter adapter) {
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
              onPressed: () => runFeedReportFlow(context, postId: 'post-1'),
              child: const Text('run'),
            );
          },
        ),
      ),
    ),
  );
}

Widget _harnessWithFeedApi(FeedApi feedApi) {
  final container = AppContainer(
    guestDeviceId: 'test-device',
    logHttpTraffic: false,
    baseUrl: 'https://example.invalid',
    sessionTokens: AuthSessionTokens(accessToken: 't'),
    feedApi: feedApi,
  );
  return AppContainerScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => runFeedReportFlow(context, postId: 'post-1'),
              child: const Text('run'),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('selecting reason and submitting shows success snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(_ReportPostAdapter(statusCode: 200)));
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('垃圾或廣告'));
    await tester.pumpAndSettle();
    expect(find.text('已收到檢舉，感謝回饋'), findsOneWidget);
  });

  testWidgets('cancel closes dialog without reporting', (tester) async {
    await tester.pumpWidget(_harness(_ReportPostAdapter(statusCode: 200)));
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('已收到檢舉，感謝回饋'), findsNothing);
  });

  testWidgets('API error shows backend message in snackbar', (tester) async {
    await tester.pumpWidget(
      _harness(
        _ReportPostAdapter(
          statusCode: 422,
          errorMessage: 'cannot report this post',
        ),
      ),
    );
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('其他'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('送出檢舉'));
    await tester.pumpAndSettle();
    expect(find.text('cannot report this post'), findsOneWidget);
  });

  testWidgets('other without detail sends reason other', (tester) async {
    final adapter = _ReportPostAdapter(statusCode: 200);
    await tester.pumpWidget(_harness(adapter));
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('其他'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('送出檢舉'));
    await tester.pumpAndSettle();
    expect(adapter.lastReportReason, 'other');
    expect(find.text('已收到檢舉，感謝回饋'), findsOneWidget);
  });

  testWidgets('other with detail sends composed reason', (tester) async {
    final adapter = _ReportPostAdapter(statusCode: 200);
    await tester.pumpWidget(_harness(adapter));
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('其他'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '詳細說明');
    await tester.pump();
    await tester.tap(find.text('送出檢舉'));
    await tester.pumpAndSettle();
    expect(adapter.lastReportReason, 'other — 詳細說明');
  });

  testWidgets('back from other step returns to reason list', (tester) async {
    await tester.pumpWidget(_harness(_ReportPostAdapter(statusCode: 200)));
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('其他'));
    await tester.pumpAndSettle();
    expect(find.text('可簡述詳情（選填）'), findsOneWidget);
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(find.text('垃圾或廣告'), findsOneWidget);
    expect(find.text('送出檢舉'), findsNothing);
  });

  testWidgets('report reason too long shows dedicated snackbar hint path', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harnessWithFeedApi(
        _FeedReportReasonTooLong(Dio(), apiPrefix: AppConfig.apiPrefix),
      ),
    );
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('垃圾或廣告'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        ApiDevSemantics.feedReportReasonTooLongMessage(
          LiubanInputLimits.feedReportReasonMaxTotalLength,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('non-API error shows generic moderation snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harnessWithFeedApi(
        _FeedReportPostNonApiException(Dio(), apiPrefix: AppConfig.apiPrefix),
      ),
    );
    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('騷擾或仇恨'));
    await tester.pumpAndSettle();
    expect(
      find.text(ApiDevSemantics.feedModerationGenericFailureMessage),
      findsOneWidget,
    );
  });
}
