import "package:flutter/foundation.dart";

/// 與 PRD 對齊：訪客／審核中／正式用戶（僅正式用戶可用本校、好友、發帖等）。
enum AccountPhase {
  /// 未登入或未通過審核：可瀏覽推廣、公開廣場、官方客服
  guest,

  /// 已提交資料，審核中（權限同訪客）
  pendingVerification,

  /// AI／人工審核通過
  verifiedStudent,
}

class AppSession extends ChangeNotifier {
  AppSession();

  AccountPhase _phase = AccountPhase.guest;

  AccountPhase get phase => _phase;

  bool get isGuestLike =>
      _phase == AccountPhase.guest ||
      _phase == AccountPhase.pendingVerification;

  bool get canUseSchoolAndFriends => _phase == AccountPhase.verifiedStudent;

  /// 開發用：之後改為登入／審核 API 回調
  void setPhase(AccountPhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    notifyListeners();
  }

  void signOut() => setPhase(AccountPhase.guest);
}
