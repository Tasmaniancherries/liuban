import "package:liuban/core/session/app_session.dart";

/// 對齊 `GET …/auth/me/verification` 回傳之 `phase` 字串。
///
/// 約定表見 `docs/backend_auth_contract.md`；新增 `phase` 時請同步更新該檔與此處 [switch]。
AccountPhase accountPhaseFromVerificationApi(String phase) {
  switch (phase) {
    case "verified_student":
    case "verified":
      return AccountPhase.verifiedStudent;
    case "pending_verification":
    case "pending":
      return AccountPhase.pendingVerification;
    default:
      return AccountPhase.guest;
  }
}
