import "package:liuban/core/config/app_config.dart";
import "package:liuban/core/navigation/post_login_redirect.dart";

/// 將設定字串正規成 [Uri]（與 [AppConfig.shareLinkOrigin] 相同規則）。
Uri parseShareLinkOrigin(String raw) {
  var o = raw.trim();
  while (o.endsWith("/")) {
    o = o.substring(0, o.length - 1);
  }
  while (o.endsWith(".")) {
    o = o.substring(0, o.length - 1);
  }
  if (o.isEmpty) return Uri();
  try {
    final parsed = Uri.parse(o);
    if (parsed.hasScheme) {
      final scheme = parsed.scheme.toLowerCase();
      if (scheme != "http" && scheme != "https") return Uri();
      if (!_isValidOriginUriShape(parsed)) return Uri();
      if (!_isValidOriginHost(parsed.host)) return Uri();
      return parsed;
    }
    final withScheme = Uri.parse("https://$o");
    if (!_isValidOriginUriShape(withScheme)) return Uri();
    if (!_isValidOriginHost(withScheme.host)) return Uri();
    return withScheme;
  } catch (_) {
    // Invalid config should not crash deep-link handling.
    return Uri();
  }
}

bool _isValidOriginUriShape(Uri uri) {
  if (uri.host.isEmpty) return false;
  if (uri.userInfo.isNotEmpty) return false;
  if (uri.query.isNotEmpty || uri.fragment.isNotEmpty) return false;
  if (uri.path.isNotEmpty && uri.path != "/") return false;
  return true;
}

bool _isValidOriginHost(String host) {
  if (host.isEmpty) return false;
  if (isLikelyIpv6LiteralHost(host.toLowerCase())) return true;
  if (host.length > 253) return false;
  for (final unit in host.codeUnits) {
    if (unit <= 0x1F || unit == 0x7F) return false;
  }
  if (host.contains("%") || host.contains(RegExp(r"\s"))) return false;
  if (!RegExp(r"^[A-Za-z0-9.-]+$").hasMatch(host)) return false;
  final labels = host.split(".");
  if (labels.any((l) => l.isEmpty)) return false;
  for (final l in labels) {
    if (l.length > 63) return false;
    if (l.startsWith("-") || l.endsWith("-")) return false;
  }
  return true;
}

/// 是否像不含方括號的 IPv6 literal（小寫 hex，已壓縮或非壓縮形式），供 origin／deep link 主機比對共用。
bool isLikelyIpv6LiteralHost(String host) {
  if (!host.contains(":")) return false;
  if (!RegExp(r"^[0-9a-f:]+$").hasMatch(host)) return false;
  if (host.contains(":::")) return false;
  final colonCount = ":".allMatches(host).length;
  if (colonCount < 2) return false;
  final firstDouble = host.indexOf("::");
  if (firstDouble >= 0 && host.indexOf("::", firstDouble + 2) >= 0) {
    return false;
  }
  final hasCompression = host.contains("::");
  final parts = host.split(":");
  if (!hasCompression && parts.length != 8) return false;
  if (parts.length > 8) return false;
  for (final p in parts) {
    if (p.isEmpty) {
      if (!hasCompression) return false;
      continue;
    }
    if (p.length > 4) return false;
  }
  return true;
}

/// 將語義相同的 IPv6 literal 展開成 8 個 16-bit 值，供 [_hostsMatch] 比對。
List<int>? _ipv6HextetsForHostMatch(String host) {
  final h = host.trim().toLowerCase();
  if (!isLikelyIpv6LiteralHost(h)) return null;
  final compressIdx = h.indexOf("::");
  late final List<String> leftRaw;
  late final List<String> rightRaw;
  if (compressIdx >= 0) {
    leftRaw = h.substring(0, compressIdx).split(":");
    rightRaw = h.substring(compressIdx + 2).split(":");
  } else {
    leftRaw = h.split(":");
    rightRaw = const <String>[];
  }
  final left = leftRaw.where((s) => s.isNotEmpty).toList();
  final right = rightRaw.where((s) => s.isNotEmpty).toList();
  if (compressIdx < 0) {
    if (left.length != 8) return null;
    try {
      return left.map((s) {
        if (s.length > 4) throw const FormatException();
        return int.parse(s, radix: 16);
      }).toList();
    } catch (_) {
      return null;
    }
  }
  final middle = 8 - left.length - right.length;
  if (middle < 0) return null;
  final out = <int>[];
  try {
    for (final s in left) {
      if (s.length > 4) return null;
      out.add(int.parse(s, radix: 16));
    }
    for (var i = 0; i < middle; i++) {
      out.add(0);
    }
    for (final s in right) {
      if (s.length > 4) return null;
      out.add(int.parse(s, radix: 16));
    }
  } catch (_) {
    return null;
  }
  return out.length == 8 ? out : null;
}

Uri _shareOriginUri() => parseShareLinkOrigin(AppConfig.shareLinkOrigin);
const int _kMaxResetTokenChars = 2048;
const int _kMaxLoginRedirectChars = 2048;
const int _kMaxPathParamChars = 256;
const int _kMaxDmCustomChars = 128;
const int _kMaxShareUriChars = 8192;
const int _kMaxShareQueryEntries = 32;
const int _kMaxShareQueryPairs = 64;
const int _kMaxShareQueryKeyChars = 128;
const int _kMaxShareQueryValueChars = 512;
const int _kMaxSharePathSegments = 8;
const int _kMaxSharePathSegmentChars = 256;

bool _isRouteManagedLongQueryKey(String key) =>
    _normalizedQueryKey(key) == "token" ||
    _normalizedQueryKey(key) == "redirect";

String _normalizedQueryKey(String key) => key.trim().toLowerCase();

String? _firstQueryValueIgnoreCase(Uri uri, String key) {
  final target = _normalizedQueryKey(key);
  var sawMatchingKey = false;
  for (final entry in uri.queryParametersAll.entries) {
    if (_normalizedQueryKey(entry.key) != target) continue;
    sawMatchingKey = true;
    if (entry.value.isEmpty) continue;
    for (final v in entry.value) {
      final trimmed = v.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
  }
  return sawMatchingKey ? "" : null;
}

List<String> _nonEmptyPathSegments(Uri uri) =>
    uri.pathSegments.where((s) => s.isNotEmpty).toList();

bool _segEq(String value, String expected) =>
    !_hasControlChars(value) && value.trim().toLowerCase() == expected;

bool _hasControlChars(String s) {
  for (final unit in s.codeUnits) {
    if (unit <= 0x1F || unit == 0x7F) return true;
  }
  return false;
}

bool _hostsMatch(String incoming, String expected) {
  if (expected.isEmpty) return false;
  String normalizeHostForMatch(String host) {
    var h = host.trim().toLowerCase();
    while (h.endsWith(".")) {
      h = h.substring(0, h.length - 1);
    }
    return h;
  }

  final a = normalizeHostForMatch(incoming);
  final b = normalizeHostForMatch(expected);
  if (a.isEmpty || b.isEmpty) return false;
  final a6 = _ipv6HextetsForHostMatch(a);
  final b6 = _ipv6HextetsForHostMatch(b);
  if (a6 != null && b6 != null) {
    for (var i = 0; i < 8; i++) {
      if (a6[i] != b6[i]) return false;
    }
    return true;
  }
  if (a == b) return true;
  if (a == "www.$b") return true;
  if (b == "www.$a") return true;
  return false;
}

String _normalizeLiubanHost(String host) {
  var h = host.trim().toLowerCase();
  while (h.endsWith(".")) {
    h = h.substring(0, h.length - 1);
  }
  if (h.contains("%") || h.contains(RegExp(r"\s")) || _hasControlChars(h)) {
    return "";
  }
  if (!RegExp(r"^[a-z0-9.-]+$").hasMatch(h)) return "";
  if (h.length > 253) return "";
  final labels = h.split(".");
  if (labels.any((l) => l.isEmpty)) return "";
  for (final l in labels) {
    if (l.length > 63) return "";
    if (l.startsWith("-") || l.endsWith("-")) return "";
  }
  return h;
}

bool _isDefaultPortForScheme(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (!uri.hasPort) return true;
  if (scheme == "http" && uri.port == 80) return true;
  if (scheme == "https" && uri.port == 443) return true;
  return false;
}

int? _normalizedPort(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (uri.hasPort) return uri.port;
  if (scheme == "http") return 80;
  if (scheme == "https") return 443;
  return null;
}

bool _portsMatch(Uri incoming, Uri expected) {
  if (expected.hasPort) {
    return _normalizedPort(incoming) == _normalizedPort(expected);
  }
  return _isDefaultPortForScheme(incoming);
}

String? _encodePathParam(String rawIdSegment) {
  String decoded;
  try {
    decoded = Uri.decodeComponent(rawIdSegment);
  } catch (_) {
    return null;
  }
  if (_hasControlChars(decoded)) return null;
  final normalized = decoded.trim();
  if (normalized.isEmpty || normalized.length > _kMaxPathParamChars) {
    return null;
  }
  return Uri.encodeComponent(normalized);
}

String? _postDetailLocation(String rawIdSegment) {
  final enc = _encodePathParam(rawIdSegment);
  if (enc == null) return null;
  return "/post/$enc";
}

String? _promotionDetailLocation(String rawIdSegment) {
  final enc = _encodePathParam(rawIdSegment);
  if (enc == null) return null;
  return "/promotion/$enc";
}

String _passwordResetLocation(String? token) {
  final t = token?.trim();
  if (t == null || t.isEmpty) return "/reset-password";
  if (t.length > _kMaxResetTokenChars) return "/reset-password";
  return "/reset-password?token=${Uri.encodeQueryComponent(t)}";
}

String? _dmChatLocation(String rawPeerIdSegment, String? customQuery) {
  final encPeer = _encodePathParam(rawPeerIdSegment);
  if (encPeer == null) return null;
  final custom = customQuery?.trim();
  if (custom != null &&
      custom.isNotEmpty &&
      custom.length <= _kMaxDmCustomChars) {
    return "/dm/$encPeer?custom=${Uri.encodeQueryComponent(custom)}";
  }
  return "/dm/$encPeer";
}

String _loginLocation(Uri uri) {
  final raw = _firstQueryValueIgnoreCase(uri, "redirect");
  if (raw == null || raw.isEmpty) return "/login";
  if (raw.length > _kMaxLoginRedirectChars) return "/login";
  final safe = sanitizePostLoginRedirect(raw);
  if (safe != null && safe.isNotEmpty) {
    return "/login?redirect=${Uri.encodeQueryComponent(safe)}";
  }
  return "/login";
}

String? _singleSegmentMarketingPath(String leaf, Uri uri) {
  if (_hasControlChars(leaf)) return null;
  switch (leaf.trim().toLowerCase()) {
    case "register":
      return "/register";
    case "login":
      return _loginLocation(uri);
    case "settings":
      return "/settings";
    case "forgot-password":
      return "/forgot-password";
    case "add-friend":
      return "/add-friend";
    case "friend-requests":
      return "/friend-requests";
    case "compose":
      return "/compose";
    case "support":
      return "/support";
    case "feed":
      return "/feed";
    case "promotion":
      return "/promotion";
    case "messages":
      return "/messages";
    case "profile":
      return "/profile";
  }
  return null;
}

String? _accountPasswordPath(List<String> segs) {
  if (segs.length == 2 &&
      _segEq(segs[0], "account") &&
      _segEq(segs[1], "password")) {
    return "/account/password";
  }
  return null;
}

String? _settingsBlockedUsersPath(List<String> segs) {
  if (segs.length == 2 &&
      _segEq(segs[0], "settings") &&
      _segEq(segs[1], "blocked-users")) {
    return "/settings/blocked-users";
  }
  return null;
}

String? _composeEditPath(List<String> segs) {
  if (segs.length == 3 &&
      _segEq(segs[0], "compose") &&
      _segEq(segs[1], "edit")) {
    final enc = _encodePathParam(segs[2]);
    if (enc == null) return null;
    return "/compose/edit/$enc";
  }
  return null;
}

String? _liubanComposeLocation(Uri uri) {
  final h = _normalizeLiubanHost(uri.host);
  if (h != "compose") return null;
  final ps = _nonEmptyPathSegments(uri);
  if (ps.length == 2 && _segEq(ps[0], "edit")) {
    final enc = _encodePathParam(ps[1]);
    if (enc == null) return null;
    return "/compose/edit/$enc";
  }
  if (ps.isEmpty) return "/compose";
  return null;
}

String? _liubanAccountPassword(Uri uri) {
  if (_normalizeLiubanHost(uri.host) != "account") return null;
  final ps = _nonEmptyPathSegments(uri);
  if (ps.length == 1 && _segEq(ps[0], "password")) return "/account/password";
  return null;
}

/// 將分享／系統開啟的 URL 對應到 [GoRouter] location。
///
/// **https**（host 對齊 [AppConfig.shareLinkOrigin]，可選 `www.`）：
/// - `/post/{id}` → 動態詳情
/// - `/promotion/{id}` → 推廣詳情
/// - `/dm/{peerId}?custom=` → 好友私聊（`custom` 為頭像旁顯示之 @ ID，可省）
/// - `/reset-password?token=` → 郵件重設密碼
/// - `/register`、`/login?redirect=`、`/settings`、`/forgot-password`、
///   `/add-friend`、`/friend-requests`、`/compose`、`/compose/edit/{postId}`、
///   `/settings/blocked-users`、`/support`、`/account/password`、
///   主導航 `/feed`、`/promotion`（列表）、`/messages`、`/profile`
///
/// **liuban:** 自訂 scheme：`liuban://post/{id}`、`liuban://promotion/{id}`、
/// `liuban://dm/{peerId}?custom=`、`liuban://reset-password?token=`、
/// `liuban://register`、`liuban://compose`、`liuban://compose/edit/{id}`、
/// `liuban://support`、`liuban://account/password` 等
///
/// [shareLinkOriginOverride]：僅供測試或特殊對照；一般應為 `null`，改用
/// `--dart-define=SHARE_LINK_ORIGIN=…`。
String? shareUriToAppLocation(
  Uri uri, {
  String? shareLinkOriginOverride,
}) {
  try {
    if (uri.toString().length > _kMaxShareUriChars) return null;
    if (uri.queryParametersAll.length > _kMaxShareQueryEntries) return null;
    var totalPairs = 0;
    for (final entry in uri.queryParametersAll.entries) {
      if (entry.key.length > _kMaxShareQueryKeyChars) return null;
      if (_hasControlChars(entry.key)) return null;
      final values = entry.value;
      totalPairs += values.length;
      if (totalPairs > _kMaxShareQueryPairs) return null;
      final routeManaged = _isRouteManagedLongQueryKey(entry.key);
      for (final v in values) {
        if (_hasControlChars(v)) return null;
        if (routeManaged) continue;
        if (v.length > _kMaxShareQueryValueChars) return null;
      }
    }

    final segsAll = _nonEmptyPathSegments(uri);
    if (segsAll.length > _kMaxSharePathSegments) return null;
    for (final seg in segsAll) {
      if (seg.length > _kMaxSharePathSegmentChars) return null;
      if (_hasControlChars(seg)) return null;
    }

    final scheme = uri.scheme.toLowerCase();
    final expectedOrigin = (shareLinkOriginOverride != null
        ? parseShareLinkOrigin(shareLinkOriginOverride)
        : _shareOriginUri());
    final expectedHost = expectedOrigin.host;

    if (scheme == "http" || scheme == "https") {
      if (uri.userInfo.isNotEmpty) return null;
      if (!_hostsMatch(uri.host, expectedHost)) return null;
      if (!_portsMatch(uri, expectedOrigin)) return null;
      final segs = segsAll;
      if (segs.length == 1 && _segEq(segs[0], "reset-password")) {
        return _passwordResetLocation(_firstQueryValueIgnoreCase(uri, "token"));
      }
      if (segs.length == 1) {
        final m = _singleSegmentMarketingPath(segs[0], uri);
        if (m != null) return m;
      }
      if (segs.length == 2 && _segEq(segs[0], "post")) {
        return _postDetailLocation(segs[1]);
      }
      if (segs.length == 2 && _segEq(segs[0], "promotion")) {
        return _promotionDetailLocation(segs[1]);
      }
      if (segs.length == 2 && _segEq(segs[0], "dm")) {
        return _dmChatLocation(
          segs[1],
          _firstQueryValueIgnoreCase(uri, "custom"),
        );
      }
      final blocked = _settingsBlockedUsersPath(segs);
      if (blocked != null) return blocked;
      final composeEdit = _composeEditPath(segs);
      if (composeEdit != null) return composeEdit;
      final acctPw = _accountPasswordPath(segs);
      if (acctPw != null) return acctPw;
      return null;
    }

    if (scheme == "liuban") {
      if (uri.hasPort) return null;
      if (uri.userInfo.isNotEmpty) return null;
      final h = _normalizeLiubanHost(uri.host);
      final liubanPathSegs = segsAll;
      if (h == "reset-password") {
        return _passwordResetLocation(_firstQueryValueIgnoreCase(uri, "token"));
      }
      if (h == "dm" && liubanPathSegs.length == 1) {
        return _dmChatLocation(
          liubanPathSegs.first,
          _firstQueryValueIgnoreCase(uri, "custom"),
        );
      }
      if (h == "post" && liubanPathSegs.length == 1) {
        return _postDetailLocation(liubanPathSegs.first);
      }
      if (h == "promotion" && liubanPathSegs.length == 1) {
        return _promotionDetailLocation(liubanPathSegs.first);
      }
      final composeLoc = _liubanComposeLocation(uri);
      if (composeLoc != null) return composeLoc;
      final acctLiuban = _liubanAccountPassword(uri);
      if (acctLiuban != null) return acctLiuban;
      if (liubanPathSegs.isNotEmpty) return null;
      final marketing = _singleSegmentMarketingPath(h, uri);
      if (marketing != null) return marketing;
    }

    return null;
  } catch (_) {
    return null;
  }
}
