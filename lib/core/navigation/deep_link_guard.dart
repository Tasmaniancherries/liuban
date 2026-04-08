const Set<String> _kAllowedDeepLinkExactPaths = {
  "/register",
  "/login",
  "/forgot-password",
  "/reset-password",
  "/settings",
  "/settings/blocked-users",
  "/account/password",
  "/friend-requests",
  "/add-friend",
  "/compose",
  "/support",
  "/feed",
  "/promotion",
  "/messages",
  "/profile",
};
const int _kMaxDeepLinkLocationChars = 4096;
const int _kMaxDeepLinkPathSegments = 8;
const int _kMaxDeepLinkPathSegmentChars = 256;
const int _kMaxDeepLinkQueryEntries = 32;
const int _kMaxDeepLinkQueryKeyChars = 128;
const int _kMaxDeepLinkQueryValueChars = 512;
const int _kMaxDeepLinkQueryPairs = 64;
const int _kMaxLogQueryKeyChars = 80;
const int _kMaxLogQueryValueChars = 120;
const int _kMaxLogPathChars = 240;
const int _kMaxLogHostChars = 120;
const int _kMaxLogQueryPairs = 40;
const int _kMaxRawFallbackLogQueryChars = 4096;
const int _kMaxRawFallbackParsedPairs = 256;
const String _kLogTruncationMetaKey = "__liuban_log_truncated_pairs__";

class _RawQueryPairForLog {
  const _RawQueryPairForLog({
    required this.decodedKey,
    required this.rawKey,
    required this.rawValue,
  });

  final String decodedKey;
  final String rawKey;
  final String rawValue;
}

const List<String> _kAllowedDeepLinkDynamicPrefixes = [
  "/dm/",
  "/post/",
  "/promotion/",
  "/compose/edit/",
];

bool _isAllowedDynamicRouteShape(List<String> segs) {
  if (segs.length == 2 && (segs[0] == "dm" || segs[0] == "post")) return true;
  if (segs.length == 2 && segs[0] == "promotion") return true;
  if (segs.length == 3 && segs[0] == "compose" && segs[1] == "edit") {
    return true;
  }
  return false;
}

String _normalizePathForGuard(String rawPath) {
  final slashNormalized = rawPath.replaceAll("\\", "/");
  final squashed = slashNormalized.replaceAll(RegExp("/+"), "/");
  if (squashed.isEmpty) return "/";
  if (squashed.length > 1 && squashed.endsWith("/")) {
    return squashed.substring(0, squashed.length - 1);
  }
  return squashed;
}

bool _isSensitiveQueryKey(String key) {
  final k = key.toLowerCase();
  if (k == "code") return true;
  if (k.contains("token")) return true;
  if (k.contains("password") || k.contains("passwd")) return true;
  if (k.contains("secret")) return true;
  if (k == "api_key" ||
      k == "apikey" ||
      k == "private_key" ||
      k == "access_key" ||
      k == "client_secret") {
    return true;
  }
  return false;
}

bool _hasControlChars(String s) {
  for (final unit in s.codeUnits) {
    if (unit <= 0x1F || unit == 0x7F) return true;
  }
  return false;
}

String _buildQueryString(Map<String, List<String>> paramsAll) {
  final pairs = <String>[];
  final keys = paramsAll.keys.toList()..sort();
  for (final k in keys) {
    final values = paramsAll[k] ?? const <String>[];
    for (final v in values) {
      pairs.add(
        "${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}",
      );
    }
  }
  return pairs.join("&");
}

String _truncateQueryValueForLog(String value) {
  if (value.length <= _kMaxLogQueryValueChars) return value;
  return "${value.substring(0, _kMaxLogQueryValueChars)}…(truncated ${value.length - _kMaxLogQueryValueChars} chars)";
}

String _truncateQueryKeyForLog(String key) {
  if (key.length <= _kMaxLogQueryKeyChars) return key;
  return "${key.substring(0, _kMaxLogQueryKeyChars)}…(truncated ${key.length - _kMaxLogQueryKeyChars} chars)";
}

String _truncatePathForLog(String path) {
  if (path.length <= _kMaxLogPathChars) return path;
  return "${path.substring(0, _kMaxLogPathChars)}…(truncated ${path.length - _kMaxLogPathChars} chars)";
}

String _truncateHostForLog(String host) {
  if (host.length <= _kMaxLogHostChars) return host;
  return "${host.substring(0, _kMaxLogHostChars)}…(truncated ${host.length - _kMaxLogHostChars} chars)";
}

String _normalizeLogPath(String path) {
  final trimmed = path.trim();
  final slashNormalized = trimmed.replaceAll("\\", "/");
  var squashed = slashNormalized.replaceAll(RegExp("/+"), "/");
  if (squashed.isEmpty) return "/";
  if (squashed.length > 1 && squashed.endsWith("/")) {
    squashed = squashed.substring(0, squashed.length - 1);
  }
  if (squashed.startsWith("/")) return squashed;
  return "/$squashed";
}

String _nextAvailableLogMetaKey(Iterable<String> existingKeys) {
  final set = existingKeys.toSet();
  var key = _kLogTruncationMetaKey;
  var idx = 1;
  while (set.contains(key)) {
    key = "${_kLogTruncationMetaKey}_$idx";
    idx++;
  }
  return key;
}

String _nextAvailableLogKey(String baseKey, Iterable<String> existingKeys) {
  final set = existingKeys.toSet();
  if (!set.contains(baseKey)) return baseKey;
  var idx = 1;
  while (set.contains("${baseKey}_$idx")) {
    idx++;
  }
  return "${baseKey}_$idx";
}

Map<String, List<String>> _buildRedactedLogQueryParams(Uri uri) {
  final redactedAll = <String, List<String>>{};
  final resolvedLogKeysBySourceKey = <String, String>{};
  var loggedPairs = 0;
  var droppedPairs = 0;
  if (uri.queryParametersAll.isNotEmpty) {
    final entries = uri.queryParametersAll.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      final k = entry.key;
      final values = [...entry.value]..sort();
      final logKey = resolvedLogKeysBySourceKey.putIfAbsent(
        k,
        () =>
            _nextAvailableLogKey(_truncateQueryKeyForLog(k), redactedAll.keys),
      );
      if (values.isEmpty) {
        if (loggedPairs < _kMaxLogQueryPairs) {
          redactedAll
              .putIfAbsent(logKey, () => <String>[])
              .add(_isSensitiveQueryKey(k) ? "***" : "");
          loggedPairs++;
        } else {
          droppedPairs++;
        }
        continue;
      }
      for (final v in values) {
        if (loggedPairs < _kMaxLogQueryPairs) {
          redactedAll
              .putIfAbsent(logKey, () => <String>[])
              .add(
                _isSensitiveQueryKey(k) ? "***" : _truncateQueryValueForLog(v),
              );
          loggedPairs++;
        } else {
          droppedPairs++;
        }
      }
    }
  }
  if (droppedPairs > 0) {
    final metaKey = _nextAvailableLogMetaKey(redactedAll.keys);
    redactedAll[metaKey] = ["truncated $droppedPairs pairs"];
  }
  return redactedAll;
}

String _redactRawQueryForLog(String rawQuery) {
  if (rawQuery.isEmpty) return "";
  var input = rawQuery;
  var truncatedInput = false;
  if (input.length > _kMaxRawFallbackLogQueryChars) {
    input = input.substring(0, _kMaxRawFallbackLogQueryChars);
    truncatedInput = true;
  }
  final pairItems = <_RawQueryPairForLog>[];
  var skippedByPairCap = 0;
  var start = 0;
  while (start <= input.length) {
    final amp = input.indexOf("&", start);
    final end = amp >= 0 ? amp : input.length;
    final pair = input.substring(start, end);
    if (pair.isNotEmpty) {
      if (pairItems.length >= _kMaxRawFallbackParsedPairs) {
        skippedByPairCap++;
      } else {
        final eq = pair.indexOf("=");
        final rawKey = eq >= 0 ? pair.substring(0, eq) : pair;
        final rawValue = eq >= 0 ? pair.substring(eq + 1) : "";
        String decodedKey;
        try {
          decodedKey = Uri.decodeQueryComponent(rawKey);
        } catch (_) {
          decodedKey = rawKey;
        }
        pairItems.add(
          _RawQueryPairForLog(
            decodedKey: decodedKey,
            rawKey: rawKey,
            rawValue: rawValue,
          ),
        );
      }
    }
    if (amp < 0) break;
    start = end + 1;
  }
  pairItems.sort((a, b) {
    final byKey = a.decodedKey.compareTo(b.decodedKey);
    if (byKey != 0) return byKey;
    final byValue = a.rawValue.compareTo(b.rawValue);
    if (byValue != 0) return byValue;
    return a.rawKey.compareTo(b.rawKey);
  });
  final out = <String>[];
  final existingKeys = <String>{};
  final resolvedLogKeysBySourceKey = <String, String>{};
  var redactedPairs = 0;
  for (final item in pairItems) {
    if (redactedPairs >= _kMaxLogQueryPairs) break;
    final decodedKey = item.decodedKey;
    final rawValue = item.rawValue;
    final logKey = resolvedLogKeysBySourceKey.putIfAbsent(
      decodedKey,
      () => _nextAvailableLogKey(
        _truncateQueryKeyForLog(decodedKey),
        existingKeys,
      ),
    );
    existingKeys.add(logKey);
    final value = _isSensitiveQueryKey(decodedKey)
        ? "***"
        : _truncateQueryValueForLog(rawValue);
    out.add(
      "${Uri.encodeQueryComponent(logKey)}=${Uri.encodeQueryComponent(value)}",
    );
    redactedPairs++;
  }
  var dropped = pairItems.length - redactedPairs;
  dropped += skippedByPairCap;
  if (truncatedInput) dropped++;
  if (dropped > 0) {
    final metaKey = _nextAvailableLogMetaKey(existingKeys);
    out.add(
      "${Uri.encodeQueryComponent(metaKey)}="
      "${Uri.encodeQueryComponent("truncated $dropped pairs")}",
    );
  }
  return out.join("&");
}

/// 將 app 內 location 正規化成可比較字串，用於 deep link 去重與同頁判斷。
///
/// - 會 trim 前後空白
/// - 會壓縮重複斜線、移除尾端斜線（根路徑除外）
/// - 會移除 fragment
/// - 會排序 query key/value（含重複 key）
String routeDedupKey(String loc) {
  var raw = loc.trim();
  if (raw.isEmpty) return "/";
  if (raw.startsWith("//")) {
    raw = "/${raw.replaceFirst(RegExp("^/+"), "")}";
  }
  try {
    final uri = Uri.parse(raw);
    final qp = <String, List<String>>{};
    final keys = uri.queryParametersAll.keys.toList()..sort();
    for (final k in keys) {
      final values = [...(uri.queryParametersAll[k] ?? const <String>[])]
        ..sort();
      qp[k] = values;
    }
    final rawPath = uri.path.isEmpty ? "/" : uri.path;
    final normalizedPath = _normalizePathForGuard(rawPath);
    final schemePrefix = uri.scheme.isEmpty ? "" : "${uri.scheme}:";
    final authority = uri.hasAuthority ? "//${uri.authority}" : "";
    final querySuffix = qp.isEmpty ? "" : "?${_buildQueryString(qp)}";
    return "$schemePrefix$authority$normalizedPath$querySuffix";
  } catch (_) {
    return raw;
  }
}

/// 判斷 location 是否屬於可導向的 app 內路由白名單。
///
/// 注意：此函式只接受「app 內相對路徑」；
/// 含 scheme/authority（例如 `https://...`、`liuban://...`）會直接拒絕。
bool isAllowedDeepLinkLocation(String loc) {
  final trimmed = loc.trim();
  if (trimmed.length > _kMaxDeepLinkLocationChars) return false;
  if (trimmed.endsWith("/") && !trimmed.startsWith("//")) return false;
  final rawPathPart = trimmed.split("#").first.split("?").first;
  if (RegExp(r"^/(dm|post|promotion|compose/edit)//").hasMatch(rawPathPart)) {
    return false;
  }
  String decodedRawPathPart;
  try {
    decodedRawPathPart = Uri.decodeFull(_normalizePathForGuard(rawPathPart));
  } catch (_) {
    return false;
  }
  if (_hasControlChars(decodedRawPathPart)) return false;
  final rawSegments = decodedRawPathPart.split("/");
  if (rawSegments.any((s) => s == "." || s == "..")) return false;
  final nonEmptyRawSegments = rawSegments.where((s) => s.isNotEmpty).toList();
  if (nonEmptyRawSegments.length > _kMaxDeepLinkPathSegments) return false;
  if (nonEmptyRawSegments.any(
    (s) => s.length > _kMaxDeepLinkPathSegmentChars,
  )) {
    return false;
  }

  final normalized = routeDedupKey(trimmed);
  Uri parsed;
  try {
    parsed = Uri.parse(normalized);
    if (parsed.hasScheme || parsed.hasAuthority) return false;
  } catch (_) {
    return false;
  }
  var totalQueryPairs = 0;
  for (final entry in parsed.queryParametersAll.entries) {
    if (entry.key.length > _kMaxDeepLinkQueryKeyChars) return false;
    if (entry.value.length > _kMaxDeepLinkQueryEntries) return false;
    totalQueryPairs += entry.value.length;
    if (totalQueryPairs > _kMaxDeepLinkQueryPairs) return false;
    if (_hasControlChars(entry.key)) return false;
    for (final value in entry.value) {
      if (value.length > _kMaxDeepLinkQueryValueChars) return false;
      if (_hasControlChars(value)) return false;
    }
  }
  if (parsed.queryParametersAll.length > _kMaxDeepLinkQueryEntries) {
    return false;
  }
  final normalizedPath = _normalizePathForGuard(parsed.path);

  String decodedPath;
  try {
    decodedPath = Uri.decodeFull(normalizedPath);
  } catch (_) {
    return false;
  }
  if (_hasControlChars(decodedPath)) return false;
  final decodedSegments = decodedPath.split("/");
  if (decodedSegments.any((s) => s == "." || s == "..")) return false;
  final nonEmptyDecodedSegments = decodedSegments
      .where((s) => s.isNotEmpty)
      .toList();
  if (nonEmptyDecodedSegments.length > _kMaxDeepLinkPathSegments) return false;
  if (nonEmptyDecodedSegments.any(
    (s) => s.length > _kMaxDeepLinkPathSegmentChars,
  )) {
    return false;
  }

  if (_kAllowedDeepLinkExactPaths.contains(normalizedPath)) return true;
  if (_kAllowedDeepLinkDynamicPrefixes.any(normalizedPath.startsWith)) {
    final segs = normalizedPath.split("/").where((s) => s.isNotEmpty).toList();
    if (_isAllowedDynamicRouteShape(segs)) return true;
  }
  return false;
}

/// 產生可安全記錄到 debug log 的 URI 字串。
///
/// - 敏感 query key（token/code 等）會遮蔽為 `***`
/// - 會移除 fragment
/// - 會清空 `userInfo`（`user:pass@`）
String safeUriForLog(Uri uri) {
  final redactedAll = _buildRedactedLogQueryParams(uri);
  final schemePrefix = uri.scheme.isEmpty ? "" : "${uri.scheme}:";
  final logHost = _truncateHostForLog(uri.host);
  final authority = logHost.isEmpty
      ? ""
      : "//${uri.hasPort ? "$logHost:${uri.port}" : logHost}";
  final query = redactedAll.isEmpty ? "" : "?${_buildQueryString(redactedAll)}";
  final normalizedPath = uri.hasAuthority
      ? _normalizeLogPath(uri.path)
      : (uri.path.isEmpty ? "" : uri.path);
  return "$schemePrefix$authority${_truncatePathForLog(normalizedPath)}$query";
}

/// 產生可安全記錄到 debug log 的 app location 字串。
///
/// - 會遮蔽敏感 query key（token/password/secret...）
/// - 會移除 fragment
/// - 對非敏感但超長 query value 會截斷，避免 log 過長
String safeLocationForLog(String loc) {
  final raw = loc.trim();
  if (raw.isEmpty) return raw;
  try {
    final uri = Uri.parse(raw);
    final redactedAll = _buildRedactedLogQueryParams(uri);
    final query = redactedAll.isEmpty
        ? ""
        : "?${_buildQueryString(redactedAll)}";
    final normalizedPath = _normalizeLogPath(uri.path);
    return "${_truncatePathForLog(normalizedPath)}$query";
  } catch (_) {
    final withoutFragment = raw.split("#").first;
    final q = withoutFragment.indexOf("?");
    if (q < 0) return _truncatePathForLog(_normalizeLogPath(withoutFragment));
    final pathPart = withoutFragment.substring(0, q);
    final path = _truncatePathForLog(_normalizeLogPath(pathPart));
    final query = withoutFragment.substring(q + 1);
    final redacted = _redactRawQueryForLog(query);
    return redacted.isEmpty ? path : "$path?$redacted";
  }
}
