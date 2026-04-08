import "dart:async";
import "dart:convert";

import "package:app_links/app_links.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:go_router/go_router.dart";
import "package:liuban/app/router.dart";
import "package:liuban/app/theme.dart";
import "package:liuban/core/locale/app_locale_scope.dart";
import "package:liuban/core/locale/liuban_supported_locales.dart";
import "package:liuban/core/network/auth_session_tokens.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/navigation/share_deep_link.dart";
import "package:liuban/core/navigation/deep_link_guard.dart";
import "package:liuban/core/session/app_session.dart";
import "package:liuban/core/theme/theme_mode_scope.dart";
import "package:liuban/core/ui/app_scroll_behavior.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";

@visibleForTesting
bool looksLikeSchemeRelativeAuthority(String authority) {
  final lower = authority.toLowerCase();
  return authority.contains(".") ||
      authority.contains(":") ||
      authority.contains("@") ||
      lower == "localhost";
}

@visibleForTesting
bool isValidComparableAuthorityHost(String host) {
  var normalized = host.trim().toLowerCase();
  while (normalized.endsWith(".")) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  if (normalized.startsWith("[") && normalized.endsWith("]")) {
    normalized = normalized.substring(1, normalized.length - 1);
  }
  if (normalized.isEmpty || normalized.length > 253) return false;
  if (isLikelyIpv6LiteralHost(normalized)) return true;
  for (final unit in normalized.codeUnits) {
    if (unit <= 0x1F || unit == 0x7F) return false;
  }
  if (normalized.contains("%") || normalized.contains(RegExp(r"\s"))) {
    return false;
  }
  if (!RegExp(r"^[a-z0-9.-]+$").hasMatch(normalized)) return false;
  final labels = normalized.split(".");
  if (labels.any((l) => l.isEmpty)) return false;
  for (final l in labels) {
    if (l.length > 63) return false;
    if (l.startsWith("-") || l.endsWith("-")) return false;
  }
  return true;
}

String _ensureComparableAppPath(String normalized) {
  if (normalized.isEmpty) return "/";
  if (normalized.startsWith("/")) return normalized;
  if (normalized.startsWith("?")) return "/$normalized";
  if (normalized.startsWith("#")) return "/";
  return "/$normalized";
}

@visibleForTesting
String normalizeAppLocationForDeepLinkCompare(String locOrUri) {
  final raw = locOrUri.trim();
  if (raw.isEmpty) return "/";
  if (raw.startsWith("?")) return routeDedupKey("/$raw");
  if (raw.startsWith("#")) return "/";
  if (raw.startsWith("//")) {
    final slashAfterAuthority = raw.indexOf("/", 2);
    final authority = slashAfterAuthority >= 0
        ? raw.substring(2, slashAfterAuthority)
        : raw.substring(2);
    final looksLikeAuthority = looksLikeSchemeRelativeAuthority(authority);
    if (looksLikeAuthority) {
      try {
        final parsed = Uri.parse("https:$raw");
        if (!isValidComparableAuthorityHost(parsed.host)) {
          return _ensureComparableAppPath(routeDedupKey(raw));
        }
        final path = parsed.path.isEmpty ? "/" : parsed.path;
        final query = parsed.hasQuery ? "?${parsed.query}" : "";
        return _ensureComparableAppPath(routeDedupKey("$path$query"));
      } catch (_) {
        return _ensureComparableAppPath(routeDedupKey(raw));
      }
    }
    return _ensureComparableAppPath(routeDedupKey(raw));
  }
  if (raw.startsWith("/")) return routeDedupKey(raw);
  try {
    final uri = Uri.parse(raw);
    if (uri.hasScheme || uri.hasAuthority) {
      final path = uri.path.isEmpty ? "/" : uri.path;
      final query = uri.hasQuery ? "?${uri.query}" : "";
      return _ensureComparableAppPath(routeDedupKey("$path$query"));
    }
    return _ensureComparableAppPath(routeDedupKey(raw));
  } catch (_) {
    return _ensureComparableAppPath(routeDedupKey(raw));
  }
}

@visibleForTesting
bool isSameAppLocationForDeepLink({
  required String currentLocation,
  required String targetLocation,
}) =>
    normalizeAppLocationForDeepLinkCompare(currentLocation) ==
    normalizeAppLocationForDeepLinkCompare(targetLocation);

@visibleForTesting
bool isWithinDeepLinkDedupWindow({
  required int nowMs,
  required int lastMs,
  required int windowMs,
}) {
  if (windowMs <= 0) return false;
  if (lastMs <= 0) return false;
  if (nowMs >= lastMs) return nowMs - lastMs < windowMs;
  // Small clock rollback: still treat as within dedup window.
  return lastMs - nowMs < windowMs;
}

@visibleForTesting
String buildDeepLinkDedupSignature(String uriText, {int maxChars = 1024}) {
  final normalized = routeDedupKey(uriText);
  if (maxChars <= 0) return "";
  if (normalized.length <= maxChars) return normalized;
  if (maxChars <= 16) return normalized.substring(0, maxChars);
  const digestChars = 8;
  const fixedOverhead = 4; // ... + #
  final digest = stableFnv1a32(
    normalized,
  ).toRadixString(16).padLeft(digestChars, "0");
  final budget = maxChars - fixedOverhead - digestChars;
  final head = budget ~/ 2;
  final tail = budget - head;
  return "${normalized.substring(0, head)}...${normalized.substring(normalized.length - tail)}#$digest";
}

@visibleForTesting
int stableFnv1a32(String input) {
  var hash = 0x811C9DC5;
  for (final b in utf8.encode(input)) {
    hash ^= b;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

class LiubanApp extends StatefulWidget {
  const LiubanApp({
    super.key,
    required this.session,
    required this.sessionTokens,
  });

  final AppSession session;
  final AuthSessionTokens sessionTokens;

  @override
  State<LiubanApp> createState() => _LiubanAppState();
}

class _LiubanAppState extends State<LiubanApp> {
  /// AppLinks 在某些平台會短時間內重複送同一事件，於此時間窗內去重。
  static const Duration _deepLinkDedupWindow = Duration(milliseconds: 1500);
  static const int _maxIncomingDeepLinkUriChars = 8192;
  static const int _maxIncomingDeepLinkLocationChars = 4096;
  static const int _maxDeepLinkDedupSignatureChars = 1024;
  static const String _deepLinkSourceInitial = "initial";
  static const String _deepLinkSourceStream = "stream";

  late final GoRouter _router = buildRouter(
    widget.session,
    sessionTokens: widget.sessionTokens,
  );
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _appLinkSub;
  String? _lastHandledDeepLinkSignature;
  int _lastHandledDeepLinkMs = 0;
  String? _lastRoutedDeepLinkLocation;
  int _lastRoutedDeepLinkMs = 0;

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;
  int get _dedupWindowMs => _deepLinkDedupWindow.inMilliseconds;
  bool _withinDedupWindow(int nowMs, int lastMs) {
    return isWithinDeepLinkDedupWindow(
      nowMs: nowMs,
      lastMs: lastMs,
      windowMs: _dedupWindowMs,
    );
  }

  String _truncateForLog(String s, {int maxChars = 800}) {
    if (s.length <= maxChars) return s;
    return "${s.substring(0, maxChars)}…(truncated ${s.length - maxChars} chars)";
  }

  String _sanitizeForLog(String s) {
    final b = StringBuffer();
    for (final unit in s.codeUnits) {
      if (unit == 0x0A) {
        b.write(r"\n");
        continue;
      }
      if (unit == 0x0D) {
        b.write(r"\r");
        continue;
      }
      if (unit == 0x09) {
        b.write(r"\t");
        continue;
      }
      if (unit <= 0x1F || unit == 0x7F) {
        b.write("\\x${unit.toRadixString(16).padLeft(2, "0")}");
        continue;
      }
      b.writeCharCode(unit);
    }
    return b.toString();
  }

  void _debugDeepLinkLazy(String Function() messageBuilder) {
    if (!kDebugMode) return;
    try {
      final truncated = _truncateForLog(messageBuilder());
      debugPrint("LiubanApp: ${_sanitizeForLog(truncated)}");
    } catch (e, st) {
      final fallback = _truncateForLog("debug log builder failed: $e\n$st");
      debugPrint("LiubanApp: ${_sanitizeForLog(fallback)}");
    }
  }

  /// 深連結無法開啟時的簡短提示（SnackBar，會由 [SnackBarTheme] 以浮動樣式顯示）。
  void _notifyDeepLinkRejected(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      liubanSnackBarWithSemanticsHint(
        message,
        semanticsHint: ApiDevSemantics.deepLinkNavigationRejectedHint,
      ),
    );
  }

  void _pruneDeepLinkDedupState(int nowMs) {
    if (_lastHandledDeepLinkSignature != null &&
        (!_withinDedupWindow(nowMs, _lastHandledDeepLinkMs))) {
      _lastHandledDeepLinkSignature = null;
      _lastHandledDeepLinkMs = 0;
    }
    if (_lastRoutedDeepLinkLocation != null &&
        (!_withinDedupWindow(nowMs, _lastRoutedDeepLinkMs))) {
      _lastRoutedDeepLinkLocation = null;
      _lastRoutedDeepLinkMs = 0;
    }
  }

  bool _isDuplicateDeepLink(String sig, int nowMs) {
    final duplicate =
        _lastHandledDeepLinkSignature == sig &&
        _withinDedupWindow(nowMs, _lastHandledDeepLinkMs);
    if (!duplicate) {
      _lastHandledDeepLinkSignature = sig;
      _lastHandledDeepLinkMs = nowMs;
    }
    return duplicate;
  }

  bool _isDuplicateRouteLocation(String dedupKey, int nowMs) {
    final duplicate =
        _lastRoutedDeepLinkLocation == dedupKey &&
        _withinDedupWindow(nowMs, _lastRoutedDeepLinkMs);
    if (!duplicate) {
      _lastRoutedDeepLinkLocation = dedupKey;
      _lastRoutedDeepLinkMs = nowMs;
    }
    return duplicate;
  }

  bool _isAlreadyAtLocation(String locDedupKey) {
    try {
      final currentUri = _router.routeInformationProvider.value.uri;
      return isSameAppLocationForDeepLink(
        currentLocation: currentUri.toString(),
        targetLocation: locDedupKey,
      );
    } catch (_) {
      return false;
    }
  }

  bool _safeGo(
    String loc, {
    required String source,
    required String locDedupKey,
    required String deepLinkSig,
  }) {
    try {
      _router.go(loc);
      return true;
    } catch (e, st) {
      // Roll back route dedup state on navigation failure so next deep-link event
      // can retry immediately instead of being blocked by dedup window.
      if (_lastRoutedDeepLinkLocation == locDedupKey) {
        _lastRoutedDeepLinkLocation = null;
        _lastRoutedDeepLinkMs = 0;
      }
      if (_lastHandledDeepLinkSignature == deepLinkSig) {
        _lastHandledDeepLinkSignature = null;
        _lastHandledDeepLinkMs = 0;
      }
      _debugDeepLinkLazy(
        () =>
            "[$source] router.go failed for ${safeLocationForLog(loc)}\n$e\n$st",
      );
      _notifyDeepLinkRejected(ApiDevSemantics.deepLinkUserMessageOpenFailed);
      return false;
    }
  }

  void _goFromDeepLink(
    Uri uri, {
    required bool postFrame,
    required String source,
  }) {
    final uriText = uri.toString();
    if (uriText.length > _maxIncomingDeepLinkUriChars) {
      _debugDeepLinkLazy(
        () =>
            "[$source] ignore oversized deep link uri (${uriText.length} chars)",
      );
      _notifyDeepLinkRejected(ApiDevSemantics.deepLinkUserMessageLinkTooLong);
      return;
    }
    final deepLinkSig = buildDeepLinkDedupSignature(
      uriText,
      maxChars: _maxDeepLinkDedupSignatureChars,
    );
    final nowMs = _nowMs();
    _pruneDeepLinkDedupState(nowMs);
    if (_isDuplicateDeepLink(deepLinkSig, nowMs)) {
      _debugDeepLinkLazy(
        () => "[$source] ignore duplicate deep link uri: ${safeUriForLog(uri)}",
      );
      return;
    }
    final loc = shareUriToAppLocation(uri);
    if (loc == null) {
      _debugDeepLinkLazy(
        () => "[$source] ignore unmapped deep link: ${safeUriForLog(uri)}",
      );
      _notifyDeepLinkRejected(ApiDevSemantics.deepLinkUserMessageUnrecognized);
      return;
    }
    if (loc.length > _maxIncomingDeepLinkLocationChars) {
      _debugDeepLinkLazy(
        () =>
            "[$source] ignore oversized deep link location (${loc.length} chars)",
      );
      _notifyDeepLinkRejected(ApiDevSemantics.deepLinkUserMessageLinkTooLong);
      return;
    }
    String? safeLoc;
    String getSafeLocForLog() => safeLoc ??= safeLocationForLog(loc);
    if (!isAllowedDeepLinkLocation(loc)) {
      _debugDeepLinkLazy(
        () =>
            "[$source] ignore disallowed deep link location: ${getSafeLocForLog()}",
      );
      _notifyDeepLinkRejected(
        ApiDevSemantics.deepLinkUserMessageDisallowedInApp,
      );
      return;
    }
    if (!mounted) return;
    final locDedupKey = routeDedupKey(loc);
    if (_isAlreadyAtLocation(locDedupKey)) {
      _debugDeepLinkLazy(
        () =>
            "[$source] ignore deep link to current location: ${getSafeLocForLog()}",
      );
      return;
    }
    if (_isDuplicateRouteLocation(locDedupKey, nowMs)) {
      _debugDeepLinkLazy(
        () =>
            "[$source] ignore duplicate deep link location: ${getSafeLocForLog()}",
      );
      return;
    }
    if (postFrame) {
      _debugDeepLinkLazy(
        () => "[$source] deep link route (post-frame) -> ${getSafeLocForLog()}",
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _safeGo(
          loc,
          source: source,
          locDedupKey: locDedupKey,
          deepLinkSig: deepLinkSig,
        );
      });
      return;
    }
    _debugDeepLinkLazy(
      () => "[$source] deep link route -> ${getSafeLocForLog()}",
    );
    _safeGo(
      loc,
      source: source,
      locDedupKey: locDedupKey,
      deepLinkSig: deepLinkSig,
    );
  }

  @override
  void initState() {
    super.initState();
    _appLinkSub = _appLinks.uriLinkStream.listen(
      _onIncomingLink,
      onError: (Object e, StackTrace st) {
        _debugDeepLinkLazy(() => "uriLinkStream error: $e\n$st");
      },
    );
    unawaitedDebug(
      "LiubanApp._consumeInitialAppLink",
      _consumeInitialAppLink(),
    );
  }

  Future<void> _consumeInitialAppLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null || !mounted) return;
      _goFromDeepLink(uri, postFrame: true, source: _deepLinkSourceInitial);
    } catch (e, st) {
      _debugDeepLinkLazy(() => "initial app link failed: $e\n$st");
    }
  }

  void _onIncomingLink(Uri uri) {
    try {
      if (!mounted) return;
      _goFromDeepLink(uri, postFrame: false, source: _deepLinkSourceStream);
    } catch (e, st) {
      _debugDeepLinkLazy(
        () => "incoming link failed: ${safeUriForLog(uri)}\n$e\n$st",
      );
    }
  }

  @override
  void dispose() {
    _appLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeModeScope.of(context);
    final localeCtrl = AppLocaleScope.of(context);
    return ListenableBuilder(
      listenable: themeCtrl,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: localeCtrl,
          builder: (context, _) {
            return MaterialApp.router(
              restorationScopeId: "liuban",
              scrollBehavior: const LiubanScrollBehavior(),
              title: "留伴",
              theme: LiubanTheme.light(),
              darkTheme: LiubanTheme.dark(),
              themeMode: themeCtrl.mode,
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
              locale: localeCtrl.resolvedLocale,
              supportedLocales: kLiubanSupportedLocales,
              localeResolutionCallback: resolveLiubanLocale,
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: mq.textScaler.clamp(
                      minScaleFactor: 0.85,
                      maxScaleFactor: 2.0,
                    ),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          },
        );
      },
    );
  }
}
