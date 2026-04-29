import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/auth_api.dart';
import 'package:liuban/data/models/registration_response.dart';
import 'package:liuban/data/models/verification_state_dto.dart';
import 'package:liuban/features/auth/registration_screen.dart';

/// 註冊成功取得 token 後，[fetchVerificationStatus] 拋非 API 異常（內層 catch 改以 [RegistrationResponse.accountPhase]）。
class _AuthRegisterOkFetchVerificationNonApiException extends AuthApi {
  _AuthRegisterOkFetchVerificationNonApiException(
    super.dio, {
    required super.apiPrefix,
  });

  @override
  Future<RegistrationResponse> registerWithVerificationDocument({
    required String customId,
    required String schoolName,
    required String studentId,
    required Uint8List documentBytes,
    String documentFilename = 'offer.jpg',
    RegistrationVerificationDocumentKind verificationDocumentKind =
        RegistrationVerificationDocumentKind.offerOrAdmissionProof,
  }) async {
    return const RegistrationResponse(
      accessToken: 'test_access',
      refreshToken: 'test_refresh',
      accountPhase: 'pending_verification',
    );
  }

  @override
  Future<VerificationStateDto> fetchVerificationStatus() async {
    throw StateError(
      'simulated fetchVerificationStatus non-LiubanApiException',
    );
  }
}

class _AuthRegisterNonApiException extends AuthApi {
  _AuthRegisterNonApiException(super.dio, {required super.apiPrefix});

  @override
  Future<RegistrationResponse> registerWithVerificationDocument({
    required String customId,
    required String schoolName,
    required String studentId,
    required Uint8List documentBytes,
    String documentFilename = 'offer.jpg',
    RegistrationVerificationDocumentKind verificationDocumentKind =
        RegistrationVerificationDocumentKind.offerOrAdmissionProof,
  }) async {
    throw StateError(
      'simulated registerWithVerificationDocument non-LiubanApiException',
    );
  }
}

/// 1×1 透明 PNG，[Image.memory] 可解碼；multipart 由測試 adapter 接受。
final Uint8List _kFakeOfferBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform(this.bytes);

  final Uint8List bytes;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile.fromData(bytes, name: 'offer.jpg', mimeType: 'image/png');
  }
}

class _ThrowingImagePickerPlatform extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    throw StateError('simulated image picker non-LiubanApiException');
  }
}

class _RegisterHttpAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final p = options.uri.path;
    if (options.method == 'POST' && p.endsWith('/auth/register')) {
      return ResponseBody.fromString(
        jsonEncode({
          'access_token': 'test_access',
          'refresh_token': 'test_refresh',
          'phase': 'pending_verification',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.method == 'GET' && p.endsWith('/auth/me/verification')) {
      return ResponseBody.fromString(
        jsonEncode({'phase': 'pending_verification'}),
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

Finder _registrationList() {
  return find.descendant(
    of: find.byType(RegistrationScreen),
    matching: find.byType(ListView),
  );
}

void _bindTallSurface(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
}

/// 註冊表單較長，略向下捲讓底部按鈕進入可點擊區。
Future<void> _revealRegistrationActions(WidgetTester tester) async {
  await tester.drag(_registrationList(), const Offset(0, -900));
  await tester.pumpAndSettle();
}

Finder _submitButtonText() {
  return find.descendant(
    of: find.byType(RegistrationScreen),
    matching: find.text('提交審核'),
  );
}

Future<void> _pumpRegistrationStack(WidgetTester tester) async {
  final session = AppSession();
  final tokens = AuthSessionTokens();
  final container = AppContainer(
    guestDeviceId: 'g',
    logHttpTraffic: false,
    baseUrl: 'https://example.invalid',
    sessionTokens: tokens,
  );
  container.dio.httpClientAdapter = _RegisterHttpAdapter();

  final router = GoRouter(
    initialLocation: '/entry',
    routes: [
      GoRoute(
        path: '/entry',
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => context.push('/register'),
              child: const Text('OPEN_REGISTER'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    AppContainerScope(
      container: container,
      child: AppSessionScope(
        notifier: session,
        child: MaterialApp.router(
          theme: LiubanTheme.light(),
          routerConfig: router,
        ),
      ),
    ),
  );
}

void main() {
  late ImagePickerPlatform originalPicker;

  setUp(() {
    originalPicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(_kFakeOfferBytes);
  });

  tearDown(() {
    ImagePickerPlatform.instance = originalPicker;
  });

  testWidgets('submit with empty fields shows validation snackbar', (
    tester,
  ) async {
    await _pumpRegistrationStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_REGISTER'));
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealRegistrationActions(tester);

    await tester.tap(_submitButtonText());
    await tester.pumpAndSettle();

    expect(find.text('請填寫完整資料'), findsOneWidget);
  });

  testWidgets('submit with text but no document shows document snackbar', (
    tester,
  ) async {
    await _pumpRegistrationStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_REGISTER'));
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealRegistrationActions(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'liuban_user');
    await tester.enterText(fields.at(1), '香港大學');
    await tester.enterText(fields.at(2), 'h1234567');
    await tester.pump();

    await tester.tap(_submitButtonText());
    await tester.pumpAndSettle();

    expect(find.text('請上傳 Offer 或錄取證明圖片'), findsOneWidget);
  });

  testWidgets('too long custom id shows validation snackbar', (tester) async {
    await _pumpRegistrationStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_REGISTER'));
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealRegistrationActions(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'a' * 33);
    await tester.enterText(fields.at(1), '香港大學');
    await tester.enterText(fields.at(2), 'h1234567');
    await tester.pump();

    await tester.tap(_submitButtonText());
    await tester.pumpAndSettle();

    expect(find.text('自訂 ID 長度不可超過 32 字元'), findsOneWidget);
  });

  testWidgets('too long school name shows validation snackbar', (tester) async {
    await _pumpRegistrationStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_REGISTER'));
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealRegistrationActions(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'liuban_user');
    await tester.enterText(fields.at(1), 'a' * 81);
    await tester.enterText(fields.at(2), 'h1234567');
    await tester.pump();

    await tester.tap(_submitButtonText());
    await tester.pumpAndSettle();

    expect(find.text('學校名稱長度不可超過 80 字元'), findsOneWidget);
  });

  testWidgets('too long student id shows validation snackbar', (tester) async {
    await _pumpRegistrationStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_REGISTER'));
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealRegistrationActions(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'liuban_user');
    await tester.enterText(fields.at(1), '香港大學');
    await tester.enterText(fields.at(2), 's' * 33);
    await tester.pump();

    await tester.tap(_submitButtonText());
    await tester.pumpAndSettle();

    expect(find.text('學號長度不可超過 32 字元'), findsOneWidget);
  });

  testWidgets('pick verification image non-API error shows snackbar', (
    tester,
  ) async {
    ImagePickerPlatform.instance = _ThrowingImagePickerPlatform();
    await _pumpRegistrationStack(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN_REGISTER'));
    await tester.pumpAndSettle();
    _bindTallSurface(tester);
    await tester.pump();
    await _revealRegistrationActions(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(RegistrationScreen),
        matching: find.text('上傳 Offer／錄取證明'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.registrationPickImageFailedMessage),
      findsOneWidget,
    );
  });

  testWidgets('submit with document calls API and pops with success snackbar', (
    tester,
  ) async {
    final session = AppSession();
    final tokens = AuthSessionTokens();
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
    );
    container.dio.httpClientAdapter = _RegisterHttpAdapter();

    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegistrationScreen(),
        ),
      ],
    );

    _bindTallSurface(tester);
    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: session,
          child: MaterialApp.router(
            theme: LiubanTheme.light(),
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _revealRegistrationActions(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'new_peer');
    await tester.enterText(fields.at(1), '香港中文大學');
    await tester.enterText(fields.at(2), 'sid999');
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(RegistrationScreen),
        matching: find.text('上傳 Offer／錄取證明'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);

    await tester.tap(_submitButtonText());
    await tester.pumpAndSettle();

    expect(find.text('已提交，審核中。通過前仍為訪客權限。'), findsOneWidget);
    expect(session.phase, AccountPhase.pendingVerification);
    expect(tokens.accessToken, 'test_access');
  });

  testWidgets(
    'submit uses accountPhase when fetchVerificationStatus throws after token',
    (tester) async {
      final session = AppSession();
      final tokens = AuthSessionTokens();
      final container = AppContainer(
        guestDeviceId: 'g',
        logHttpTraffic: false,
        baseUrl: 'https://example.invalid',
        sessionTokens: tokens,
        authApi: _AuthRegisterOkFetchVerificationNonApiException(
          Dio(),
          apiPrefix: AppConfig.apiPrefix,
        ),
      );

      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegistrationScreen(),
          ),
        ],
      );

      _bindTallSurface(tester);
      await tester.pumpWidget(
        AppContainerScope(
          container: container,
          child: AppSessionScope(
            notifier: session,
            child: MaterialApp.router(
              theme: LiubanTheme.light(),
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _revealRegistrationActions(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'new_peer');
      await tester.enterText(fields.at(1), '香港中文大學');
      await tester.enterText(fields.at(2), 'sid999');
      await tester.pump();

      await tester.tap(
        find.descendant(
          of: find.byType(RegistrationScreen),
          matching: find.text('上傳 Offer／錄取證明'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_submitButtonText());
      await tester.pumpAndSettle();

      expect(find.text('已提交，審核中。通過前仍為訪客權限。'), findsOneWidget);
      expect(session.phase, AccountPhase.pendingVerification);
      expect(tokens.accessToken, 'test_access');
    },
  );

  testWidgets('submit non-API error shows generic snackbar', (tester) async {
    final session = AppSession();
    final tokens = AuthSessionTokens();
    final container = AppContainer(
      guestDeviceId: 'g',
      logHttpTraffic: false,
      baseUrl: 'https://example.invalid',
      sessionTokens: tokens,
      authApi: _AuthRegisterNonApiException(
        Dio(),
        apiPrefix: AppConfig.apiPrefix,
      ),
    );

    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegistrationScreen(),
        ),
      ],
    );

    _bindTallSurface(tester);
    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: AppSessionScope(
          notifier: session,
          child: MaterialApp.router(
            theme: LiubanTheme.light(),
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _revealRegistrationActions(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'new_peer');
    await tester.enterText(fields.at(1), '香港中文大學');
    await tester.enterText(fields.at(2), 'sid999');
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(RegistrationScreen),
        matching: find.text('上傳 Offer／錄取證明'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_submitButtonText());
    await tester.pumpAndSettle();

    expect(
      find.text(ApiDevSemantics.authSubmitGenericFailureMessage),
      findsOneWidget,
    );
  });
}
