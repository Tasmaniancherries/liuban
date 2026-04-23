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
import 'package:liuban/features/promotion/promotion_list_screen.dart';

class _PromotionListNonApiException extends PromotionApi {
  _PromotionListNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<List<PromotionDto>> listPromotions() async {
    throw StateError('simulated listPromotions non-LiubanApiException');
  }
}

class _PromotionsListAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/promotions')) {
      return ResponseBody.fromString(
        jsonEncode([
          {
            'id': 'promo_wt_1',
            'title': 'Widget 測試推廣標題',
            'subtitle': '合作方',
            'published_at': '2026-04-01',
            'body': '正文',
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

void main() {
  testWidgets('loads promotions from GET …/promotions', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
    );
    container.dio.httpClientAdapter = _PromotionsListAdapter();

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: PromotionListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('推廣'), findsOneWidget);
    expect(find.text('Widget 測試推廣標題'), findsOneWidget);
    expect(find.text('合作方 · 2026-04-01'), findsOneWidget);
  });

  testWidgets('list non-API error shows empty state and generic snackbar', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 't'),
      promotionApi: _PromotionListNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: const MaterialApp(home: PromotionListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暫無推廣內容'), findsOneWidget);
    expect(
      find.text(ApiDevSemantics.promotionListLoadFailedMessage),
      findsOneWidget,
    );
  });
}
