import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/data/models/user_profile_dto.dart';
import 'package:liuban/data/models/verification_state_dto.dart';
import 'package:liuban/features/profile/profile_screen.dart';

class _AuthFetchVerificationNonApiException extends AuthApi {
  _AuthFetchVerificationNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<VerificationStateDto> fetchVerificationStatus() async {
    throw StateError(
      'simulated fetchVerificationStatus non-LiubanApiException',
    );
  }
}

class _AuthFetchVerificationApiException extends AuthApi {
  _AuthFetchVerificationApiException(super.dio, {required super.apiPrefix});

  @override
  Future<VerificationStateDto> fetchVerificationStatus() async {
    throw LiubanApiException(message: '同步審核失敗（API）');
  }
}

class _AuthFetchVerificationSuccess extends AuthApi {
  _AuthFetchVerificationSuccess(super.dio, {required super.apiPrefix});

  @override
  Future<VerificationStateDto> fetchVerificationStatus() async {
    return const VerificationStateDto(phase: 'verified_student');
  }
}

class _AuthFetchMeApiException extends AuthApi {
  _AuthFetchMeApiException(super.dio, {required super.apiPrefix});

  @override
  Future<UserProfileDto> fetchMe() async {
    throw LiubanApiException(message: '個人檔案暫時不可用');
  }
}

class _AuthFetchMeNonApiException extends AuthApi {
  _AuthFetchMeNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<UserProfileDto> fetchMe() async {
    throw StateError('simulated fetchMe non-LiubanApiException');
  }
}

class _AuthMeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'GET' && p.endsWith('/auth/me')) {
      return ResponseBody.fromString(
        jsonEncode({
          'id': 'u1',
          'custom_id': 'alice_test',
          'display_name': 'Alice',
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

void main() {
  testWidgets('guest shows 訪客瀏覽 without calling API', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _AuthMeAdapter();

    await tester.pumpWidget(
      AppSessionScope(
        notifier: AppSession(),
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('訪客瀏覽'), findsOneWidget);
    expect(find.text('@alice_test'), findsNothing);
  });

  testWidgets('loads @custom_id from GET …/auth/me when logged in', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 'tok'),
    );
    container.dio.httpClientAdapter = _AuthMeAdapter();

    await tester.pumpWidget(
      AppSessionScope(
        notifier: AppSession(),
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('@alice_test'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('sync verification non-API error shows generic snackbar', (
    tester,
  ) async {
    final adapter = _AuthMeAdapter();
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 'tok'),
      authApiFactory: (dio) {
        dio.httpClientAdapter = adapter;
        return _AuthFetchVerificationNonApiException(
          dio,
          apiPrefix: AppConfig.apiPrefix,
        );
      },
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: AppSession(),
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('同步審核狀態'));
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.verificationSyncGenericFailureMessage),
      findsOneWidget,
    );
  });

  testWidgets('sync verification API error shows API snackbar', (tester) async {
    final adapter = _AuthMeAdapter();
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 'tok'),
      authApiFactory: (dio) {
        dio.httpClientAdapter = adapter;
        return _AuthFetchVerificationApiException(
          dio,
          apiPrefix: AppConfig.apiPrefix,
        );
      },
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: AppSession(),
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('同步審核狀態'));
    await tester.pumpAndSettle();

    expect(find.text('同步審核失敗（API）'), findsOneWidget);
  });

  testWidgets(
    'sync verification success updates phase and shows success snackbar',
    (tester) async {
      final adapter = _AuthMeAdapter();
      final container = AppContainer(
        guestDeviceId: 'd',
        logHttpTraffic: false,
        baseUrl: 'https://example.invalid',
        sessionTokens: AuthSessionTokens(accessToken: 'tok'),
        authApiFactory: (dio) {
          dio.httpClientAdapter = adapter;
          return _AuthFetchVerificationSuccess(
            dio,
            apiPrefix: AppConfig.apiPrefix,
          );
        },
      );
      final session = AppSession()..setPhase(AccountPhase.pendingVerification);

      await tester.pumpWidget(
        AppSessionScope(
          notifier: session,
          child: AppContainerScope(
            container: container,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('同步審核狀態'));
      await tester.pumpAndSettle();

      expect(session.phase, AccountPhase.verifiedStudent);
      expect(find.text('已同步'), findsOneWidget);
    },
  );

  testWidgets('fetchMe API error shows API snackbar and keeps unloaded state', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 'tok'),
      authApi: _AuthFetchMeApiException(Dio(), apiPrefix: AppConfig.apiPrefix),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: AppSession(),
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('個人檔案暫時不可用'), findsOneWidget);
    expect(find.textContaining('@⋯'), findsOneWidget);
  });

  testWidgets('fetchMe non-API error shows generic failure snackbar', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 'tok'),
      authApi: _AuthFetchMeNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    await tester.pumpWidget(
      AppSessionScope(
        notifier: AppSession(),
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.profileMeLoadFailedMessage),
      findsOneWidget,
    );
    expect(find.textContaining('@⋯'), findsOneWidget);
  });

  testWidgets('guest sign-out button is disabled', (tester) async {
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(),
    );
    container.dio.httpClientAdapter = _AuthMeAdapter();
    final session = AppSession();

    await tester.pumpWidget(
      AppSessionScope(
        notifier: session,
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '退出登入（預覽）'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('logged-in sign-out clears token and resets to guest', (
    tester,
  ) async {
    final container = AppContainer(
      guestDeviceId: 'd',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: AuthSessionTokens(accessToken: 'tok'),
    );
    container.dio.httpClientAdapter = _AuthMeAdapter();
    final session = AppSession()..setPhase(AccountPhase.verifiedStudent);

    await tester.pumpWidget(
      AppSessionScope(
        notifier: session,
        child: AppContainerScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final signOutText = find.textContaining('退出登入');
    await tester.scrollUntilVisible(
      signOutText,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(signOutText);
    await tester.pumpAndSettle();

    expect(container.sessionTokens.accessToken, isNull);
    expect(session.phase, AccountPhase.guest);
    expect(find.text('訪客瀏覽'), findsOneWidget);
  });
}
