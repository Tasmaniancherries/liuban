import "package:flutter/material.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/network/auth_session_tokens.dart";
import "package:liuban/core/session/app_session.dart";
import "package:liuban/core/session/verification_phase_mapper.dart";

/// 若本地已有 access token，向後端拉審核狀態並同步 [AppSession]（失敗則不覆寫）。
///
/// 亦會在 token 由「空」變為「有」（例如登入成功）時再同步一次。
class SessionHydrator extends StatefulWidget {
  const SessionHydrator(
      {super.key, required this.session, required this.child});

  final AppSession session;
  final Widget child;

  @override
  State<SessionHydrator> createState() => _SessionHydratorState();
}

class _SessionHydratorState extends State<SessionHydrator> {
  AuthSessionTokens? _tokens;
  String? _lastAccess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachAndHydrate());
  }

  void _attachAndHydrate() {
    if (!mounted) return;
    final container = AppContainerScope.of(context);
    _tokens = container.sessionTokens;
    _lastAccess = _tokens!.accessToken;
    _tokens!.addListener(_onTokensChanged);
    unawaitedDebug("SessionHydrator._hydrate", _hydrate());
  }

  void _onTokensChanged() {
    final t = _tokens?.accessToken;
    final prev = _lastAccess;
    _lastAccess = t;
    final wasEmpty = prev == null || prev.isEmpty;
    final nowHas = t != null && t.isNotEmpty;
    final hadAuth = prev != null && prev.isNotEmpty;
    if (hadAuth && !nowHas) {
      widget.session.signOut();
    }
    if (wasEmpty && nowHas) {
      unawaitedDebug("SessionHydrator._hydrate", _hydrate());
    }
  }

  Future<void> _hydrate() async {
    if (!mounted) return;
    final container = AppContainerScope.of(context);
    final token = container.sessionTokens.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final st = await container.auth.fetchVerificationStatus();
      if (!mounted) return;
      widget.session.setPhase(accountPhaseFromVerificationApi(st.phase));
    } catch (_) {
      // Token 仍可能有效；審核端點尚未就緒時不打擾使用者
    }
  }

  @override
  void dispose() {
    _tokens?.removeListener(_onTokensChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
