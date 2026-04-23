import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/promotion_api.dart';
import 'package:liuban/data/models/promotion_dto.dart';
import 'package:liuban/features/promotion/promotion_detail_screen.dart';

class _PromotionDetailAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/promotions/detail_wt')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'detail_wt',
          'title': '詳情頁 Widget 標題',
          'subtitle': '平台',
          'published_at': '2026-04-10',
          'body': '詳情頁正文區塊',
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

class _PromotionDetailFailAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/promotions/1')) {
      return ResponseBody.fromString(
        jsonEncode({'message': '推廣詳情 API 測試錯誤'}),
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

/// `GET …/promotions/{id}` 失敗且 [promotionById] 為 null（例如 id 不在 [kMockPromotions]）。
class _PromotionDetailFailNoLocalAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/promotions/999')) {
      return ResponseBody.fromString(
        jsonEncode({'message': '推廣詳情無本地備援 API 錯誤'}),
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

/// 模擬 [PromotionApi.getPromotion] 拋出非 [LiubanApiException]（generic [catch]）。
class _PromotionGetNonApiException extends PromotionApi {
  _PromotionGetNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<PromotionDto> getPromotion(String id) async {
    throw StateError('simulated getPromotion non-LiubanApiException');
  }
}

void main() {
  testWidgets('loads promotion body from GET …/promotions/{id}', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _PromotionDetailAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(
          home: PromotionDetailScreen(promotionId: 'detail_wt'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('推廣詳情'), findsOneWidget);
    expect(find.text('詳情頁 Widget 標題'), findsOneWidget);
    expect(find.text('詳情頁正文區塊'), findsOneWidget);
    expect(find.textContaining('平台'), findsWidgets);
  });

  testWidgets('GET failure shows empty state and API snackbar', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _PromotionDetailFailAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: PromotionDetailScreen(promotionId: '1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ApiDevSemantics.promotionDetailEmptyTitle), findsOneWidget);
    expect(find.text('推廣詳情 API 測試錯誤'), findsOneWidget);
  });

  testWidgets(
    'GET failure with no local mock shows empty title and API snackbar',
    (tester) async {
      final container = AppContainer(
        guestDeviceId: 'g',
        logHttpTraffic: false,
        baseUrl: 'https://example.invalid',
        sessionTokens: AuthSessionTokens(accessToken: 't'),
      );
      container.dio.httpClientAdapter = _PromotionDetailFailNoLocalAdapter();

      await tester.pumpWidget(
        AppContainerScope(
          container: container,
          child: const MaterialApp(
            home: PromotionDetailScreen(promotionId: '999'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ApiDevSemantics.promotionDetailEmptyTitle),
        findsOneWidget,
      );
      expect(find.text('推廣詳情無本地備援 API 錯誤'), findsOneWidget);
    },
  );

  testWidgets(
    'getPromotion non-API failure shows empty state and generic snackbar',
    (tester) async {
      final container = AppContainer(
        guestDeviceId: 'g',
        logHttpTraffic: false,
        baseUrl: 'https://example.invalid',
        sessionTokens: AuthSessionTokens(accessToken: 't'),
        promotionApi: _PromotionGetNonApiException(
          Dio(),
          apiPrefix: AppConfig.apiPrefix,
        ),
      );

      await tester.pumpWidget(
        AppContainerScope(
          container: container,
          child: const MaterialApp(
            home: PromotionDetailScreen(promotionId: '1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ApiDevSemantics.promotionDetailEmptyTitle),
        findsOneWidget,
      );
      expect(
        find.text(ApiDevSemantics.promotionDetailLoadFailedMessage),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'getPromotion non-API failure with no local mock shows empty title and generic snackbar',
    (tester) async {
      final container = AppContainer(
        guestDeviceId: 'g',
        logHttpTraffic: false,
        baseUrl: 'https://example.invalid',
        sessionTokens: AuthSessionTokens(accessToken: 't'),
        promotionApi: _PromotionGetNonApiException(
          Dio(),
          apiPrefix: AppConfig.apiPrefix,
        ),
      );

      await tester.pumpWidget(
        AppContainerScope(
          container: container,
          child: const MaterialApp(
            home: PromotionDetailScreen(promotionId: '999'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ApiDevSemantics.promotionDetailEmptyTitle),
        findsOneWidget,
      );
      expect(
        find.text(ApiDevSemantics.promotionDetailLoadFailedMessage),
        findsOneWidget,
      );
    },
  );
}
