import "package:liuban/data/models/json_utils.dart";

/// 登入或 refresh 回傳之 token 對。
///
/// 欄位與 Bearer 標頭慣例見 `docs/backend_auth_contract.md`（Token 回應體、HTTP 標頭、刷新流程）。
/// 自管後端建議統一回：`access_token`、可選 `refresh_token`（亦相容 `accessToken` / `token`）。
class TokenPairDto {
  const TokenPairDto({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;

  factory TokenPairDto.fromJson(Map<String, dynamic> json) {
    final access =
        json["access_token"] as String? ??
        json["accessToken"] as String? ??
        json["token"] as String?;
    if (access == null || access.isEmpty) {
      throw const FormatException("缺少 access_token");
    }
    return TokenPairDto(
      accessToken: access,
      refreshToken:
          json["refresh_token"] as String? ?? json["refreshToken"] as String?,
    );
  }

  factory TokenPairDto.fromResponse(dynamic data) =>
      TokenPairDto.fromJson(asJsonMap(data));
}
