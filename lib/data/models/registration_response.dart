import "package:liuban/data/models/json_utils.dart";

/// `POST …/auth/register` 之 JSON 回傳（`multipart` 請求見 [AuthApi.registerWithVerificationDocument]）。
///
/// 契約表欄位見 `docs/backend_auth_contract.md`「註冊回應」。別名：`token`、`phase`。
class RegistrationResponse {
  const RegistrationResponse({
    this.accessToken,
    this.refreshToken,
    required this.accountPhase,
  });

  final String? accessToken;
  final String? refreshToken;
  final String accountPhase;

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      accessToken: json["access_token"] as String? ?? json["token"] as String?,
      refreshToken: json["refresh_token"] as String?,
      accountPhase: json["account_phase"] as String? ??
          json["phase"] as String? ??
          "pending_verification",
    );
  }

  factory RegistrationResponse.fromResponse(dynamic data) =>
      RegistrationResponse.fromJson(asJsonMap(data));
}
