import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/session/verification_phase_mapper.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/core/ui/scroll_constants.dart';
import 'package:liuban/data/models/education_entry_dto.dart';
import 'package:liuban/data/models/user_profile_dto.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfileDto? _me;
  bool _loadingMe = false;
  String? _lastToken;
  bool _meFromFallback = false;

  Future<bool>? _loadMeInFlight;

  /// 成功載入個人檔回傳 `true`；失敗或改用占位時回傳 `false`（並已安排 SnackBar）。
  Future<bool> _loadMe() {
    if (_loadMeInFlight != null) return _loadMeInFlight!;
    _loadMeInFlight = _performLoadMe().whenComplete(() {
      _loadMeInFlight = null;
    });
    return _loadMeInFlight!;
  }

  Future<bool> _performLoadMe() async {
    setState(() => _loadingMe = true);
    try {
      final me = await AppContainerScope.of(context).auth.fetchMe();
      if (!mounted) return false;
      setState(() {
        _me = me;
        _meFromFallback = false;
      });
      return true;
    } on LiubanApiException catch (e, st) {
      if (kDebugMode) {
        debugPrint('ProfileScreen: fetchMe failed: $e\n$st');
      }
      if (mounted) {
        setState(() {
          _me = UserProfileDto.previewFallback();
          _meFromFallback = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            liubanSnackBarWithSemanticsHint(
              e.message,
              semanticsHint: ApiDevSemantics.authMeLoadApiErrorSnackHint,
            ),
          );
        });
      }
      return false;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ProfileScreen: fetchMe failed: $e\n$st');
      }
      if (mounted) {
        setState(() {
          _me = UserProfileDto.previewFallback();
          _meFromFallback = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            liubanSnackBarWithSemanticsHint(
              ApiDevSemantics.profileMeLoadErrorFallbackMessage,
              semanticsHint:
                  ApiDevSemantics.profileMeLoadErrorFallbackSnackHint,
            ),
          );
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _loadingMe = false);
    }
  }

  Future<void> _syncVerificationStatus(AppSession session) async {
    final container = AppContainerScope.of(context);
    try {
      final st = await container.auth.fetchVerificationStatus();
      session.setPhase(accountPhaseFromVerificationApi(st.phase));
      final profileOk = await _loadMe();
      if (!mounted) return;
      if (profileOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          liubanSnackBarWithSemanticsHint(
            '已同步',
            semanticsHint: ApiDevSemantics.verificationSyncSuccessSnackHint,
          ),
        );
      }
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.verificationSyncApiErrorSnackHint,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.verificationSyncGenericFailureMessage,
          semanticsHint:
              ApiDevSemantics.verificationSyncGenericFailureSnackHint,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = AppContainerScope.of(context).sessionTokens.accessToken;
    if (token == null || token.isEmpty) {
      if (_me != null || _meFromFallback) {
        setState(() {
          _me = null;
          _meFromFallback = false;
        });
      }
      _lastToken = null;
      return;
    }
    if (token != _lastToken) {
      _lastToken = token;
      unawaitedDebugFuture('ProfileScreen._loadMe', _loadMe());
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    final hasToken =
        AppContainerScope.of(context).sessionTokens.accessToken != null;

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final titleName = !hasToken
            ? '訪客瀏覽'
            : _loadingMe && (_me == null || _me!.customId.isEmpty)
            ? '載入中⋯'
            : "@${_me?.customId.isNotEmpty == true ? _me!.customId : "⋯"}";

        return Scaffold(
          appBar: AppBar(
            title: const Text('我的', semanticsLabel: '我的與個人檔案'),
            actions: [
              Semantics(
                hint: '開啟設定頁',
                child: IconButton(
                  tooltip: '設定',
                  onPressed: () => unawaitedDebugFuture(
                    'ProfileScreen.appBar.pushSettings',
                    context.push('/settings'),
                  ),
                  icon: const Icon(
                    Icons.settings_outlined,
                    semanticLabel: '設定',
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              if (!hasToken) return;
              await _loadMe();
            },
            child: ListView(
              cacheExtent: kLiubanListCacheExtent,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Tooltip(
                  message: '前往設定',
                  child: Semantics(
                    button: true,
                    label: '前往設定',
                    hint: '開啟設定頁（密碼、客服、關於）',
                    excludeSemantics: true,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.settings_outlined,
                        semanticLabel: '設定',
                      ),
                      title: const Text('設定'),
                      subtitle: const SelectionArea(child: Text('密碼、客服、關於留伴')),
                      trailing: const Icon(
                        Icons.chevron_right,
                        semanticLabel: '前往詳情',
                      ),
                      onTap: () => unawaitedDebugFuture(
                        'ProfileScreen.settingsTile.pushSettings',
                        context.push('/settings'),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32),
                if (hasToken && _meFromFallback)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      container: true,
                      label: ApiDevSemantics.profileMeMockDataBannerVisibleText,
                      hint:
                          ApiDevSemantics.profileMeMockDataBannerSemanticsHint,
                      excludeSemantics: true,
                      child: SelectionArea(
                        child: Text(
                          ApiDevSemantics.profileMeMockDataBannerVisibleText,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      child: Text(
                        session.phase == AccountPhase.verifiedStudent
                            ? '留'
                            : '?',
                        semanticsLabel:
                            session.phase == AccountPhase.verifiedStudent
                            ? '已認證，留伴預設頭像'
                            : '頭像占位',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              label: titleName,
                              hint: '目前顯示名稱或載入狀態',
                              excludeSemantics: true,
                              child: Text(
                                titleName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_me?.displayName != null &&
                                _me!.displayName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _me!.displayName!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            if (session.phase ==
                                AccountPhase.verifiedStudent) ...[
                              if (_me != null && _me!.educations.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final e in _me!.educations)
                                      _schoolChipFromDto(context, e),
                                  ],
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _schoolChip(context, '港大', alumni: true),
                                    _schoolChip(context, '中大', alumni: false),
                                  ],
                                ),
                            ] else
                              Text(
                                session.phase ==
                                        AccountPhase.pendingVerification
                                    ? '審核通過後顯示學籍標籤'
                                    : '登入並通過審核後顯示',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (kDebugMode) ...[
                  Semantics(
                    header: true,
                    label: '帳戶狀態（開發預覽）',
                    hint: '僅除錯組建可用於模擬審核階段',
                    excludeSemantics: true,
                    child: SelectionArea(
                      child: Text(
                        '帳戶狀態（開發預覽）',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Semantics(
                        button: true,
                        selected: session.phase == AccountPhase.guest,
                        label: '切換為訪客狀態，訪客',
                        hint: '僅開發預覽：模擬訪客階段',
                        excludeSemantics: true,
                        child: ChoiceChip(
                          tooltip: '切換為訪客狀態',
                          label: const Text('訪客'),
                          selected: session.phase == AccountPhase.guest,
                          onSelected: (_) =>
                              session.setPhase(AccountPhase.guest),
                        ),
                      ),
                      Semantics(
                        button: true,
                        selected:
                            session.phase == AccountPhase.pendingVerification,
                        label: '切換為審核中狀態，審核中',
                        hint: '僅開發預覽：模擬審核中階段',
                        excludeSemantics: true,
                        child: ChoiceChip(
                          tooltip: '切換為審核中狀態',
                          label: const Text('審核中'),
                          selected:
                              session.phase == AccountPhase.pendingVerification,
                          onSelected: (_) => session.setPhase(
                            AccountPhase.pendingVerification,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        selected: session.phase == AccountPhase.verifiedStudent,
                        label: '切換為已認證狀態，已認證',
                        hint: '僅開發預覽：模擬已認證階段',
                        excludeSemantics: true,
                        child: ChoiceChip(
                          tooltip: '切換為已認證狀態',
                          label: const Text('已認證'),
                          selected:
                              session.phase == AccountPhase.verifiedStudent,
                          onSelected: (_) =>
                              session.setPhase(AccountPhase.verifiedStudent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    container: true,
                    label: ApiDevSemantics.profilePhasePreviewDisclaimer,
                    hint: '僅開發預覽用說明文字',
                    excludeSemantics: true,
                    child: SelectionArea(
                      child: Text(
                        ApiDevSemantics.profilePhasePreviewDisclaimer,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (hasToken) ...[
                  Tooltip(
                    message: '同步目前審核狀態',
                    child: Semantics(
                      button: true,
                      label: '同步目前審核狀態',
                      hint: 'GET 審核狀態與個人檔；詳見副標 Api 說明',
                      excludeSemantics: true,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.sync,
                          semanticLabel: '同步審核狀態',
                        ),
                        title: const Text('同步審核狀態'),
                        subtitle: SelectionArea(
                          child: Text(ApiDevSemantics.verificationSyncSubtitle),
                        ),
                        onTap: () => unawaitedDebug(
                          'ProfileScreen._syncVerificationStatus',
                          _syncVerificationStatus(session),
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: '重新載入個人檔案',
                    child: Semantics(
                      button: true,
                      label: '重新載入個人檔案',
                      hint: '向伺服器重新取得個人資料',
                      excludeSemantics: true,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.person_search,
                          semanticLabel: '重新載入個人檔案',
                        ),
                        title: const Text('重新載入個人檔案'),
                        subtitle: SelectionArea(
                          child: Text(ApiDevSemantics.profileMeGet),
                        ),
                        onTap: () => unawaitedDebugFuture(
                          'ProfileScreen._loadMe',
                          _loadMe(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Tooltip(
                  message: '前往註冊或提交身分審核',
                  child: Semantics(
                    button: true,
                    label: '前往註冊或提交身分審核',
                    hint: '開啟註冊表單；可上傳 Offer、錄取證明或學生證',
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: () => unawaitedDebugFuture(
                        'ProfileScreen.guest.pushRegister',
                        context.push('/register'),
                      ),
                      child: const Text('前往註冊／審核'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message: '登入',
                  child: Semantics(
                    button: true,
                    label: '登入，已有帳號',
                    hint: '開啟登入畫面',
                    excludeSemantics: true,
                    child: FilledButton.tonal(
                      onPressed: () => unawaitedDebugFuture(
                        'ProfileScreen.guest.pushLogin',
                        context.push('/login'),
                      ),
                      child: const Text('已有帳號 · 登入'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message: '清除登入狀態並回到訪客',
                  child: Semantics(
                    button: true,
                    enabled: hasToken || session.phase != AccountPhase.guest,
                    label: '清除登入狀態並回到訪客',
                    hint: '清除權限並以訪客身分瀏覽',
                    excludeSemantics: true,
                    child: OutlinedButton(
                      onPressed:
                          !hasToken && session.phase == AccountPhase.guest
                          ? null
                          : () {
                              AppContainerScope.of(
                                context,
                              ).sessionTokens.clear();
                              setState(() {
                                _me = null;
                                _lastToken = null;
                              });
                              session.signOut();
                            },
                      child: kDebugMode
                          ? const Text('退出登入（預覽）')
                          : const Text('退出登入'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _schoolChip(
    BuildContext context,
    String shortName, {
    required bool alumni,
  }) {
    final dto = EducationEntryDto(schoolShortName: shortName, alumni: alumni);
    return Semantics(
      container: true,
      label: '學籍標籤，${dto.chipLabel}',
      hint: '學校或校友身分標籤，僅顯示',
      excludeSemantics: true,
      child: Chip(
        label: Text(dto.chipLabel),
        visualDensity: VisualDensity.compact,
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  static Widget _schoolChipFromDto(BuildContext context, EducationEntryDto e) {
    return Semantics(
      container: true,
      label: '學籍標籤，${e.chipLabel}',
      hint: '學校或校友身分標籤，僅顯示',
      excludeSemantics: true,
      child: Chip(
        label: Text(e.chipLabel),
        visualDensity: VisualDensity.compact,
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
