import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/session/verification_phase_mapper.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/features/feed/compose_post_screen.dart';
import 'package:liuban/widgets/auth_required_gate.dart';

/// 發佈／編輯動態：需登入，且須為已通過身分審核（Offer／錄取或學生證）之帳號（與廣場 FAB 權限一致）。
class ComposeAccessGate extends StatelessWidget {
  const ComposeAccessGate({super.key, this.editingPostId, this.initialPost});

  /// 非空時進入編輯模式，對應路由 `/compose/edit/:postId`。
  final String? editingPostId;
  final FeedPostDto? initialPost;

  bool get _isEdit => editingPostId != null && editingPostId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AuthRequiredGate(
      title: _isEdit ? '編輯動態' : '發佈動態',
      child: _ComposeVerifiedShell(
        isEdit: _isEdit,
        editingPostId: editingPostId,
        initialPost: initialPost,
      ),
    );
  }
}

class _ComposeVerifiedShell extends StatefulWidget {
  const _ComposeVerifiedShell({
    required this.isEdit,
    this.editingPostId,
    this.initialPost,
  });

  final bool isEdit;
  final String? editingPostId;
  final FeedPostDto? initialPost;

  @override
  State<_ComposeVerifiedShell> createState() => _ComposeVerifiedShellState();
}

class _ComposeVerifiedShellState extends State<_ComposeVerifiedShell> {
  bool _syncing = false;

  Future<void> _syncVerification() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final st = await AppContainerScope.of(
        context,
      ).auth.fetchVerificationStatus();
      if (!mounted) return;
      AppSessionScope.of(
        context,
      ).setPhase(accountPhaseFromVerificationApi(st.phase));
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '已同步審核狀態',
          semanticsHint: ApiDevSemantics.verificationSyncSuccessSnackHint,
        ),
      );
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
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (session.canUseSchoolAndFriends) {
          return ComposePostScreen(
            editingPostId: widget.editingPostId,
            initialPost: widget.initialPost,
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.isEdit ? '編輯動態' : '發佈動態',
              semanticsLabel: widget.isEdit ? '編輯廣場動態' : '發佈廣場動態',
            ),
            leading: Semantics(
              hint: '關閉撰寫限制說明並返回上一頁',
              child: IconButton(
                tooltip: '返回',
                icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
                onPressed: _syncing ? null : () => context.pop(),
              ),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    semanticLabel: '需通過審核才能發佈',
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    label: '通過身分審核後才可發佈廣場動態。審核中與訪客權限相同，可先到「我的」同步審核狀態。',
                    hint: '下方按鈕可同步審核狀態或前往個人頁',
                    excludeSemantics: true,
                    child: SelectionArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '通過身分審核後才可發佈廣場動態',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '審核中與訪客權限相同，可先到「我的」同步審核狀態。',
                            textAlign: TextAlign.center,
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
                  const SizedBox(height: 28),
                  Tooltip(
                    message: '同步審核狀態',
                    child: Semantics(
                      button: true,
                      enabled: !_syncing,
                      label: '同步審核狀態',
                      hint: _syncing
                          ? '處理中'
                          : ApiDevSemantics.verificationSyncSubtitle,
                      excludeSemantics: true,
                      child: FilledButton.tonalIcon(
                        onPressed: _syncing
                            ? null
                            : () => unawaitedDebug(
                                'ComposeAccessGate._syncVerification',
                                _syncVerification(),
                              ),
                        icon: _syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  semanticsLabel: '處理中',
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.sync,
                                size: 20,
                                semanticLabel: '同步審核狀態',
                              ),
                        label: const Text('同步審核狀態'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Tooltip(
                    message: '前往個人頁',
                    child: Semantics(
                      button: true,
                      enabled: !_syncing,
                      label: '前往個人頁',
                      hint: '開啟「我的」分頁',
                      excludeSemantics: true,
                      child: FilledButton(
                        onPressed: _syncing
                            ? null
                            : () => context.go('/profile'),
                        child: const Text('前往我的'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: '返回上一頁',
                    child: Semantics(
                      button: true,
                      enabled: !_syncing,
                      label: '返回上一頁',
                      hint: '關閉並回到上一頁',
                      excludeSemantics: true,
                      child: TextButton(
                        onPressed: _syncing ? null : () => context.pop(),
                        child: const Text('返回'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
