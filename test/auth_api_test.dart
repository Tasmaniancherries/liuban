import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/data/api/auth_api.dart';

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;
  Object? lastData;
  Map<String, dynamic>? lastJsonBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    lastData = options.data;

    // JSON requests in this API are sent as maps; keep a normalized body view.
    final data = options.data;
    final contentType = options.contentType?.toLowerCase() ?? '';
    if (data is Map) {
      lastJsonBody = Map<String, dynamic>.from(data);
    } else if (requestStream != null && contentType.contains('application/json')) {
      final bytes = await requestStream.fold<BytesBuilder>(
        BytesBuilder(),
        (b, chunk) => b..add(chunk),
      );
      final text = utf8.decode(bytes.takeBytes(), allowMalformed: true);
      if (text.isNotEmpty) {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          lastJsonBody = Map<String, dynamic>.from(decoded);
        }
      }
    }

    final path = options.uri.path;
    final jsonHeaders = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (path.endsWith('/auth/login')) {
      return ResponseBody.fromString(
        '{"access_token":"acc","refresh_token":"ref"}',
        200,
        headers: jsonHeaders,
      );
    }
    return ResponseBody.fromString('{}', 200, headers: jsonHeaders);
  }
}

void main() {
  late Dio dio;
  late _CaptureAdapter adapter;
  late AuthApi api;

  setUp(() {
    adapter = _CaptureAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.httpClientAdapter = adapter;
    api = AuthApi(dio, apiPrefix: '/v1');
  });

  test('login posts to /v1/auth/login with account/password body', () async {
    final pair = await api.login(account: 'u', password: 'p');
    expect(adapter.lastOptions?.method, 'POST');
    expect(adapter.lastOptions?.uri.path, '/v1/auth/login');
    expect(adapter.lastJsonBody?['account'], 'u');
    expect(adapter.lastJsonBody?['password'], 'p');
    expect(pair.accessToken, 'acc');
    expect(pair.refreshToken, 'ref');
  });

  test(
    'requestPasswordResetEmail trims email and hits request endpoint',
    () async {
      await api.requestPasswordResetEmail(email: '  a@b.com  ');
      expect(adapter.lastOptions?.uri.path, '/v1/auth/password/reset/request');
      expect(adapter.lastJsonBody?['email'], 'a@b.com');
    },
  );

  test('completePasswordResetWithToken posts token and new_password', () async {
    await api.completePasswordResetWithToken(token: 't', newPassword: 'np');
    expect(adapter.lastOptions?.uri.path, '/v1/auth/password/reset/complete');
    expect(adapter.lastJsonBody?['token'], 't');
    expect(adapter.lastJsonBody?['new_password'], 'np');
  });

  test(
    'registerWithVerificationDocument uses offer field by default',
    () async {
      await api.registerWithVerificationDocument(
        customId: 'cid',
        schoolName: 'HKU',
        studentId: 's1',
        documentBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(adapter.lastOptions?.uri.path, '/v1/auth/register');
      final form = adapter.lastData as FormData;
      final fields = Map<String, String>.fromEntries(form.fields);
      final fileKeys = form.files.map((e) => e.key).toList();
      expect(fields['verification_document_kind'], 'offer');
      expect(fileKeys, contains('offer'));
      expect(fileKeys, isNot(contains('student_id_card')));
    },
  );

  test(
    'registerWithVerificationDocument supports student_id_card field',
    () async {
      await api.registerWithVerificationDocument(
        customId: 'cid',
        schoolName: 'CUHK',
        studentId: 's2',
        verificationDocumentKind:
            RegistrationVerificationDocumentKind.studentIdCard,
        documentBytes: Uint8List.fromList([9, 8, 7]),
        documentFilename: 'sid.png',
      );
      final form = adapter.lastData as FormData;
      final fields = Map<String, String>.fromEntries(form.fields);
      final fileKeys = form.files.map((e) => e.key).toList();
      expect(fields['verification_document_kind'], 'student_id_card');
      expect(fileKeys, contains('student_id_card'));
      expect(fileKeys, isNot(contains('offer')));
    },
  );
}
