import "package:liuban/data/models/json_utils.dart";

/// `GET …/auth/me/verification` 回傳之帳戶審核狀態。
///
/// `phase` 約定與 App 對應見 `docs/backend_auth_contract.md`；別名：`account_phase`。
class VerificationStateDto {
  const VerificationStateDto({
    required this.phase,
    this.message,
  });

  /// 例如：guest | pending_verification | verified_student
  final String phase;
  final String? message;

  factory VerificationStateDto.fromJson(Map<String, dynamic> json) {
    return VerificationStateDto(
      phase: json["phase"] as String? ??
          json["account_phase"] as String? ??
          "guest",
      message: json["message"] as String?,
    );
  }

  factory VerificationStateDto.fromResponse(dynamic data) =>
      VerificationStateDto.fromJson(asJsonMap(data));
}
