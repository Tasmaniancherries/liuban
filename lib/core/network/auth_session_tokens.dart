import "package:flutter/foundation.dart";

/// Access / Refresh 雙令牌；[bearer] 等同 [accessToken]，相容舊程式碼。
class AuthSessionTokens extends ChangeNotifier {
  AuthSessionTokens({String? accessToken, String? refreshToken})
    : _access = accessToken,
      _refresh = refreshToken;

  String? _access;
  String? _refresh;

  String? get accessToken => _access;

  String? get refreshToken => _refresh;

  set accessToken(String? v) {
    if (_access == v) return;
    _access = v;
    notifyListeners();
  }

  set refreshToken(String? v) {
    if (_refresh == v) return;
    _refresh = v;
    notifyListeners();
  }

  /// 舊用法：等同寫入 access token。
  String? get bearer => _access;

  set bearer(String? token) => accessToken = token;

  void applyPair({required String access, String? refresh}) {
    _access = access;
    if (refresh != null && refresh.isNotEmpty) {
      _refresh = refresh;
    }
    notifyListeners();
  }

  void clear() {
    _access = null;
    _refresh = null;
    notifyListeners();
  }
}
