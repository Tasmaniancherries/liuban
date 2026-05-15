import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/data/api/api_client_validation.dart';
import 'package:liuban/data/models/json_utils.dart';
import 'package:liuban/data/models/registration_response.dart';
import 'package:liuban/data/models/token_pair_dto.dart';
import 'package:liuban/data/models/user_profile_dto.dart';
import 'package:liuban/data/models/verification_state_dto.dart';

/// 註冊時上傳的審核檔案類型（對應 [AuthApi.registerWithVerificationDocument] 的 multipart 與後端審核）。
enum RegistrationVerificationDocumentKind {
  /// Offer 或正式錄取證明（欄位 `offer`）。
  offerOrAdmissionProof,

  /// 學生證（含可辨識之學籍資訊；欄位 `student_id_card`）。
  studentIdCard,
}

/// 留伴自管後端：**JSON REST**（非 OAuth2 `application/x-www-form-urlencoded`）。
///
/// **後端契約（路徑、multipart 欄位、`phase` 等）**以專案內
/// `docs/backend_auth_contract.md` 為準；廣場／好友／推廣／客服見
/// `docs/backend_domain_apis_contract.md`。實作與其不一致時應先更新文檔再改程式。
///
/// **登入** [login]：`POST {apiPrefix}/auth/login`
/// `Content-Type: application/json`，body：`{"account","password"}`
/// 回應 JSON（至少）：`access_token`；建議一併回 `refresh_token`。
///
/// **刷新令牌** 由 [TokenRefreshInterceptor] 呼叫：
/// `POST {apiPrefix}/auth/refresh`，body：`{"refresh_token":"<現有 refresh>"}`
/// 回應與登入相同欄位慣例（見 [TokenPairDto]）。
///
/// **當前用戶** [fetchMe]：`GET {apiPrefix}/auth/me`
///
/// **郵箱重設密碼**（未登入）：
/// - [requestPasswordResetEmail]：`POST {apiPrefix}/auth/password/reset/request`，body：`email`
/// - [completePasswordResetWithToken]：`POST {apiPrefix}/auth/password/reset/complete`，body：`token`、`new_password`
/// 路徑與欄位名可依後端調整；信件內連結建議導向 App：`/reset-password?token=...`。
class AuthApi {
  AuthApi(this._dio, {required this.apiPrefix});

  final Dio _dio;
  final String apiPrefix;

  String _path(String relative) {
    if (relative.startsWith('/')) {
      return '$apiPrefix$relative';
    }
    return '$apiPrefix/$relative';
  }

  /// 註冊並上傳審核用圖片（`multipart/form-data`），見 [documentBytes]／[documentFilename]。
  ///
  /// - [verificationDocumentKind] 為 [RegistrationVerificationDocumentKind.offerOrAdmissionProof]
  ///   時上傳欄位 **`offer`**（與舊版後端一致）。
  /// - 為 [RegistrationVerificationDocumentKind.studentIdCard] 時上傳 **`student_id_card`**，
  ///   並附上 **`verification_document_kind`**=`student_id_card` 供後端分支。
  /// 若 JSON 回應含 token，由呼叫端寫入 [AuthSessionTokens]。
  Future<RegistrationResponse> registerWithVerificationDocument({
    required String customId,
    required String schoolName,
    required String studentId,
    required Uint8List documentBytes,
    String documentFilename = 'offer.jpg',
    RegistrationVerificationDocumentKind verificationDocumentKind =
        RegistrationVerificationDocumentKind.offerOrAdmissionProof,
  }) async {
    assertTextWithinLimit(
      text: customId,
      maxLength: LiubanInputLimits.customIdMaxLength,
      message: ApiDevSemantics.inputTooLongMessage(
        '自訂 ID ',
        LiubanInputLimits.customIdMaxLength,
      ),
      code: LiubanInputLimits.inputTooLongCode,
    );
    assertTextWithinLimit(
      text: schoolName,
      maxLength: LiubanInputLimits.schoolNameMaxLength,
      message: ApiDevSemantics.inputTooLongMessage(
        '學校名稱',
        LiubanInputLimits.schoolNameMaxLength,
      ),
      code: LiubanInputLimits.inputTooLongCode,
    );
    assertTextWithinLimit(
      text: studentId,
      maxLength: LiubanInputLimits.studentIdMaxLength,
      message: ApiDevSemantics.inputTooLongMessage(
        '學號',
        LiubanInputLimits.studentIdMaxLength,
      ),
      code: LiubanInputLimits.inputTooLongCode,
    );
    try {
      final file = MultipartFile.fromBytes(
        documentBytes,
        filename: documentFilename,
      );
      final kindStr = switch (verificationDocumentKind) {
        RegistrationVerificationDocumentKind.offerOrAdmissionProof => 'offer',
        RegistrationVerificationDocumentKind.studentIdCard => 'student_id_card',
      };
      final map = <String, dynamic>{
        'custom_id': customId,
        'school_name': schoolName,
        'student_id': studentId,
        'verification_document_kind': kindStr,
      };
      switch (verificationDocumentKind) {
        case RegistrationVerificationDocumentKind.offerOrAdmissionProof:
          map['offer'] = file;
        case RegistrationVerificationDocumentKind.studentIdCard:
          map['student_id_card'] = file;
      }
      final form = FormData.fromMap(map);
      final res = await _dio.post<dynamic>(_path('/auth/register'), data: form);
      final data = res.data;
      if (data == null || (data is Map && data.isEmpty)) {
        return const RegistrationResponse(accountPhase: 'pending_verification');
      }
      return RegistrationResponse.fromResponse(data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<VerificationStateDto> fetchVerificationStatus() async {
    try {
      final res = await _dio.get<dynamic>(_path('/auth/me/verification'));
      return VerificationStateDto.fromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<UserProfileDto> fetchMe() async {
    try {
      final res = await _dio.get<dynamic>(_path('/auth/me'));
      return UserProfileDto.fromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 已有帳號登入（欄位名 `account` / `password` 可依後端調整）。
  Future<TokenPairDto> login({
    required String account,
    required String password,
  }) async {
    assertTextWithinLimit(
      text: account,
      maxLength: LiubanInputLimits.loginAccountMaxLength,
      message: ApiDevSemantics.inputTooLongMessage(
        '帳號',
        LiubanInputLimits.loginAccountMaxLength,
      ),
      code: LiubanInputLimits.inputTooLongCode,
    );
    assertTextWithinLimit(
      text: password,
      maxLength: LiubanInputLimits.passwordMaxLength,
      message: ApiDevSemantics.inputTooLongMessage(
        '密碼',
        LiubanInputLimits.passwordMaxLength,
      ),
      code: LiubanInputLimits.inputTooLongCode,
    );
    try {
      final res = await _dio.post<dynamic>(
        _path('/auth/login'),
        data: <String, dynamic>{'account': account, 'password': password},
      );
      return TokenPairDto.fromJson(asJsonMap(res.data));
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 修改密碼（已登入）。預設：`POST {apiPrefix}/auth/password`
  /// body：`current_password`、`new_password`（欄位名可依後端調整）。
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    for (final entry in <(String, String)>[
      ('目前密碼', currentPassword),
      ('新密碼', newPassword),
    ]) {
      assertTextWithinLimit(
        text: entry.$2,
        maxLength: LiubanInputLimits.passwordMaxLength,
        message: ApiDevSemantics.inputTooLongMessage(
          entry.$1,
          LiubanInputLimits.passwordMaxLength,
        ),
        code: LiubanInputLimits.inputTooLongCode,
      );
    }
    try {
      await _dio.post<dynamic>(
        _path('/auth/password'),
        data: <String, dynamic>{
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 寄送重設密碼信；常見 REST 合約為一律回成功狀態，避免枚舉已註冊信箱。
  Future<void> requestPasswordResetEmail({required String email}) async {
    assertTextWithinLimit(
      text: email,
      maxLength: LiubanInputLimits.emailMaxLength,
      message: ApiDevSemantics.inputTooLongMessage(
        '郵箱',
        LiubanInputLimits.emailMaxLength,
      ),
      code: LiubanInputLimits.inputTooLongCode,
    );
    try {
      await _dio.post<dynamic>(
        _path('/auth/password/reset/request'),
        data: <String, dynamic>{'email': email.trim()},
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 以郵件連結內之 `token` 完成重設並提交新密碼。
  Future<void> completePasswordResetWithToken({
    required String token,
    required String newPassword,
  }) async {
    assertTextWithinLimit(
      text: token,
      maxLength: LiubanInputLimits.resetTokenMaxLength,
      message: ApiDevSemantics.inputTooLongMessage(
        '重設憑證',
        LiubanInputLimits.resetTokenMaxLength,
      ),
      code: LiubanInputLimits.inputTooLongCode,
    );
    assertTextWithinLimit(
      text: newPassword,
      maxLength: LiubanInputLimits.passwordMaxLength,
      message: ApiDevSemantics.inputTooLongMessage(
        '新密碼',
        LiubanInputLimits.passwordMaxLength,
      ),
      code: LiubanInputLimits.inputTooLongCode,
    );
    try {
      await _dio.post<dynamic>(
        _path('/auth/password/reset/complete'),
        data: <String, dynamic>{'token': token, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }
}
