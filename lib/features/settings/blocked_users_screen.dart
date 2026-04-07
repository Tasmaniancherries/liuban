import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/core/ui/scroll_constants.dart";
import "package:liuban/data/models/blocked_user_dto.dart";

class _BlockedUsersLoad {
  const _BlockedUsersLoad({
    required this.items,
    required this.usedErrorFallback,
    this.apiFailureSnackMessage,
  });

  final List<BlockedUserDto> items;
  final bool usedErrorFallback;
  final String? apiFailureSnackMessage;
}

/// 已屏蔽用戶列表；畫面說明見 `ApiDevSemantics.friendsBlocks`。
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  Future<_BlockedUsersLoad>? _future;
  var _started = false;

  Future<_BlockedUsersLoad> _load() async {
    try {
      final list =
          await AppContainerScope.of(context).friends.listBlockedUsers();
      return _BlockedUsersLoad(items: list, usedErrorFallback: false);
    } on LiubanApiException catch (e) {
      return _BlockedUsersLoad(
        items: BlockedUserDto.mockList(),
        usedErrorFallback: true,
        apiFailureSnackMessage: e.message,
      );
    } catch (_) {
      return _BlockedUsersLoad(
        items: BlockedUserDto.mockList(),
        usedErrorFallback: true,
      );
    }
  }

  Future<_BlockedUsersLoad> _loadAndNotify() async {
    final r = await _load();
    if (r.usedErrorFallback && mounted) {
      final apiMsg = r.apiFailureSnackMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            apiMsg ?? ApiDevSemantics.blockedUsersListErrorFallbackMessage,
            semanticsHint: apiMsg != null
                ? ApiDevSemantics.blockedUsersListGetApiErrorSnackHint
                : ApiDevSemantics.blockedUsersListErrorFallbackSnackHint,
          ),
        );
      });
    }
    return r;
  }

  Future<void> _refresh() async {
    final next = _loadAndNotify();
    setState(() => _future = next);
    await next;
  }

  Future<void> _confirmUnblock(BlockedUserDto b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Semantics(
        container: true,
        label: "解除屏蔽確認",
        hint: ApiDevSemantics.unblockUserConfirmDialogHint,
        child: AlertDialog(
          title: const Text("解除屏蔽"),
          content: SelectionArea(
            child: Text(
              "確定要對 ${b.displayLabel ?? b.userId} 解除屏蔽嗎？",
            ),
          ),
          actions: [
            Tooltip(
              message: "保留屏蔽",
              child: Semantics(
                button: true,
                label: "保留屏蔽",
                hint: "關閉對話框，維持屏蔽狀態",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("取消"),
                ),
              ),
            ),
            Tooltip(
              message: "確認解除屏蔽",
              child: Semantics(
                button: true,
                label: "確認解除屏蔽",
                hint: "確認後向伺服器提交解除屏蔽",
                excludeSemantics: true,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("解除"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppContainerScope.of(context).friends.unblockUser(userId: b.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          "已解除屏蔽",
          semanticsHint: ApiDevSemantics.unblockUserSuccessSnackHint,
        ),
      );
      await _refresh();
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.unblockUserApiErrorSnackHint,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.friendsWriteGenericFailureMessage,
          semanticsHint: ApiDevSemantics.friendsWriteGenericFailureSnackHint,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _future = _loadAndNotify();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "已屏蔽用戶",
          semanticsLabel: "已屏蔽用戶名單",
        ),
        leading: Semantics(
          hint: "關閉已屏蔽名單並返回上一頁",
          child: IconButton(
            tooltip: "返回",
            icon: const Icon(Icons.arrow_back, semanticLabel: "返回"),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FutureBuilder<_BlockedUsersLoad>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: "載入中",
                        ),
                      ),
                    ),
                  );
                }
                final load = snap.data!;
                final items = load.items;
                final usingMock = load.usedErrorFallback;
                return ListView(
                  cacheExtent: kLiubanListCacheExtent,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Semantics(
                      header: true,
                      label: ApiDevSemantics.friendsBlocks,
                      hint: "下方為已屏蔽使用者列表，可解除屏蔽",
                      excludeSemantics: true,
                      child: SelectionArea(
                        child: Text(
                          ApiDevSemantics.friendsBlocks,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                    if (usingMock) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        container: true,
                        label: ApiDevSemantics
                            .blockedUsersMockDataBannerVisibleText,
                        hint: ApiDevSemantics
                            .blockedUsersMockDataBannerSemanticsHint,
                        excludeSemantics: true,
                        child: SelectionArea(
                          child: Text(
                            ApiDevSemantics
                                .blockedUsersMockDataBannerVisibleText,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Center(
                          child: Semantics(
                            container: true,
                            label: "尚無屏蔽對象",
                            hint: "下拉可重新整理列表",
                            excludeSemantics: true,
                            child: SelectionArea(
                              child: Text(
                                "尚無屏蔽對象",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      for (final b in items)
                        Semantics(
                          container: true,
                          explicitChildNodes: true,
                          label:
                              "${b.displayLabel?.isNotEmpty == true ? b.displayLabel! : b.userId}，已屏蔽用戶",
                          hint: "可使用解除按鈕取消屏蔽",
                          child: Card(
                            child: ListTile(
                              title: SelectionArea(
                                child: Text(
                                  b.displayLabel?.isNotEmpty == true
                                      ? b.displayLabel!
                                      : b.userId,
                                ),
                              ),
                              subtitle: b.displayLabel?.isNotEmpty == true
                                  ? SelectionArea(
                                      child: Text("ID · ${b.userId}"),
                                    )
                                  : null,
                              trailing: Tooltip(
                                message: "解除對此用戶的屏蔽",
                                child: Semantics(
                                  button: true,
                                  label: "解除對此用戶的屏蔽",
                                  hint: "開啟確認對話框以解除屏蔽",
                                  excludeSemantics: true,
                                  child: TextButton(
                                    onPressed: () => unawaitedDebug(
                                      "BlockedUsersScreen._confirmUnblock",
                                      _confirmUnblock(b),
                                    ),
                                    child: const Text("解除"),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
