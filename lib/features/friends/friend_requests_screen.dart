import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/core/ui/scroll_constants.dart";
import "package:liuban/data/models/friend_outgoing_request_dto.dart";
import "package:liuban/data/models/friend_request_dto.dart";

class _IncomingTabLoad {
  const _IncomingTabLoad({
    required this.items,
    required this.usedErrorFallback,
    this.apiFailureSnackMessage,
  });

  final List<FriendRequestDto> items;
  final bool usedErrorFallback;
  final String? apiFailureSnackMessage;
}

class _OutgoingTabLoad {
  const _OutgoingTabLoad({
    required this.items,
    required this.usedErrorFallback,
    this.apiFailureSnackMessage,
  });

  final List<FriendOutgoingRequestDto> items;
  final bool usedErrorFallback;
  final String? apiFailureSnackMessage;
}

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Future<_IncomingTabLoad>? _incoming;
  Future<_OutgoingTabLoad>? _outgoing;
  var _loadsStarted = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadsStarted) return;
    _loadsStarted = true;
    _incoming = _loadIncoming();
    _outgoing = _loadOutgoing();
    unawaitedDebug(
      "FriendRequestsScreen._notifyIfAnyFriendRequestsFallback",
      _notifyIfAnyFriendRequestsFallback(),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<_IncomingTabLoad> _loadIncoming() async {
    try {
      final list =
          await AppContainerScope.of(context).friends.listIncomingRequests();
      return _IncomingTabLoad(items: list, usedErrorFallback: false);
    } on LiubanApiException catch (e) {
      return _IncomingTabLoad(
        items: FriendRequestDto.mockPending(),
        usedErrorFallback: true,
        apiFailureSnackMessage: e.message,
      );
    } catch (_) {
      return _IncomingTabLoad(
        items: FriendRequestDto.mockPending(),
        usedErrorFallback: true,
      );
    }
  }

  Future<_OutgoingTabLoad> _loadOutgoing() async {
    try {
      final list =
          await AppContainerScope.of(context).friends.listOutgoingRequests();
      return _OutgoingTabLoad(items: list, usedErrorFallback: false);
    } on LiubanApiException catch (e) {
      return _OutgoingTabLoad(
        items: FriendOutgoingRequestDto.mockOutgoing(),
        usedErrorFallback: true,
        apiFailureSnackMessage: e.message,
      );
    } catch (_) {
      return _OutgoingTabLoad(
        items: FriendOutgoingRequestDto.mockOutgoing(),
        usedErrorFallback: true,
      );
    }
  }

  void _scheduleFriendRequestsFallbackSnack({String? apiMessage}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        liubanSnackBarWithSemanticsHint(
          apiMessage ?? ApiDevSemantics.friendRequestsListsErrorFallbackMessage,
          semanticsHint: apiMessage != null
              ? ApiDevSemantics.friendRequestsListsGetApiErrorSnackHint
              : ApiDevSemantics.friendRequestsListsErrorFallbackSnackHint,
        ),
      );
    });
  }

  Future<void> _notifyIfAnyFriendRequestsFallback() async {
    final ir = await _incoming!;
    final or = await _outgoing!;
    if (!mounted) return;
    if (ir.usedErrorFallback || or.usedErrorFallback) {
      final apiMsg = ir.apiFailureSnackMessage ?? or.apiFailureSnackMessage;
      _scheduleFriendRequestsFallbackSnack(apiMessage: apiMsg);
    }
  }

  Future<void> _refreshAll() async {
    final inc = _loadIncoming();
    final out = _loadOutgoing();
    setState(() {
      _incoming = inc;
      _outgoing = out;
    });
    final ir = await inc;
    final or = await out;
    if (!mounted) return;
    if (ir.usedErrorFallback || or.usedErrorFallback) {
      final apiMsg = ir.apiFailureSnackMessage ?? or.apiFailureSnackMessage;
      _scheduleFriendRequestsFallbackSnack(apiMessage: apiMsg);
    }
  }

  Future<void> _respond(String id, bool accept) async {
    try {
      await AppContainerScope.of(context).friends.respondToFriendRequest(
            requestId: id,
            accept: accept,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          accept ? "已接受" : "已拒絕",
          semanticsHint: ApiDevSemantics.friendRequestRespondSuccessSnackHint,
        ),
      );
      await _refreshAll();
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.friendRequestRespondApiErrorSnackHint,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "好友申請",
          semanticsLabel: "好友申請列表",
        ),
        leading: Semantics(
          hint: "關閉好友申請並返回上一頁",
          child: IconButton(
            tooltip: "返回",
            icon: const Icon(Icons.arrow_back, semanticLabel: "返回"),
            onPressed: () => context.pop(),
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(
              child: Semantics(
                hint: "切換至收到的好友申請列表",
                child: const Text(
                  "收到的",
                  semanticsLabel: "收到的好友申請",
                ),
              ),
            ),
            Tab(
              child: Semantics(
                hint: "切換至已發出的好友申請列表",
                child: const Text(
                  "我發出的",
                  semanticsLabel: "我發出的好友申請",
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _IncomingPanel(
            future: _incoming!,
            onRefresh: _refreshAll,
            onRespond: _respond,
          ),
          _OutgoingPanel(
            future: _outgoing!,
            onRefresh: _refreshAll,
          ),
        ],
      ),
    );
  }
}

class _IncomingPanel extends StatelessWidget {
  const _IncomingPanel({
    required this.future,
    required this.onRefresh,
    required this.onRespond,
  });

  final Future<_IncomingTabLoad> future;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String id, bool accept) onRespond;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<_IncomingTabLoad>(
            future: future,
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Semantics(
                    header: true,
                    label: ApiDevSemantics.friendRequestsIncoming,
                    hint: "下方為收到的好友申請列表",
                    excludeSemantics: true,
                    child: SelectionArea(
                      child: Text(
                        ApiDevSemantics.friendRequestsIncoming,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          .friendRequestsMockDataBannerVisibleText,
                      hint: ApiDevSemantics
                          .friendRequestsMockDataBannerSemanticsHint,
                      excludeSemantics: true,
                      child: SelectionArea(
                        child: Text(
                          ApiDevSemantics
                              .friendRequestsMockDataBannerVisibleText,
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
                          label: "暫無待處理申請",
                          hint: "下拉可重新整理",
                          excludeSemantics: true,
                          child: SelectionArea(
                            child: Text(
                              "暫無待處理申請",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    for (final r in items)
                      Semantics(
                        container: true,
                        explicitChildNodes: true,
                        label: "來自 @${r.fromCustomId} 的好友申請，"
                            "${r.createdAt ?? "想加你為好友"}",
                        hint: "請使用拒絕或接受按鈕回覆",
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                r.fromCustomId.isNotEmpty
                                    ? r.fromCustomId[0].toUpperCase()
                                    : "?",
                                semanticsLabel: r.fromCustomId.isNotEmpty
                                    ? "@${r.fromCustomId} 的大頭貼"
                                    : "申請者頭像",
                              ),
                            ),
                            title: SelectionArea(
                              child: Text("@${r.fromCustomId}"),
                            ),
                            subtitle: SelectionArea(
                              child: Text(r.createdAt ?? "想加你為好友"),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  hint: "拒絕此好友申請並從列表移除",
                                  child: IconButton(
                                    tooltip: "拒絕",
                                    onPressed: () => unawaitedDebug(
                                      "FriendRequestsScreen._respond.decline",
                                      onRespond(r.id, false),
                                    ),
                                    icon: const Icon(
                                      Icons.close,
                                      semanticLabel: "拒絕",
                                    ),
                                  ),
                                ),
                                Semantics(
                                  hint: "接受並與對方成為雙向好友",
                                  child: IconButton.filledTonal(
                                    tooltip: "接受",
                                    onPressed: () => unawaitedDebug(
                                      "FriendRequestsScreen._respond.accept",
                                      onRespond(r.id, true),
                                    ),
                                    icon: const Icon(
                                      Icons.check,
                                      semanticLabel: "接受",
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }
}

class _OutgoingPanel extends StatelessWidget {
  const _OutgoingPanel({
    required this.future,
    required this.onRefresh,
  });

  final Future<_OutgoingTabLoad> future;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<_OutgoingTabLoad>(
            future: future,
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Semantics(
                    header: true,
                    label: ApiDevSemantics.friendRequestsOutgoing,
                    hint: "下方為已發出的好友申請列表",
                    excludeSemantics: true,
                    child: SelectionArea(
                      child: Text(
                        ApiDevSemantics.friendRequestsOutgoing,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          .friendRequestsMockDataBannerVisibleText,
                      hint: ApiDevSemantics
                          .friendRequestsMockDataBannerSemanticsHint,
                      excludeSemantics: true,
                      child: SelectionArea(
                        child: Text(
                          ApiDevSemantics
                              .friendRequestsMockDataBannerVisibleText,
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
                          label: "暫無發出中的申請",
                          hint: "下拉可重新整理",
                          excludeSemantics: true,
                          child: SelectionArea(
                            child: Text(
                              "暫無發出中的申請",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    for (final r in items)
                      Semantics(
                        container: true,
                        explicitChildNodes: true,
                        label: "已向 @${r.toCustomId} 發出好友申請，狀態 ${r.status}",
                        hint: "狀態由伺服器回傳；下拉列表可重新整理",
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                r.toCustomId.isNotEmpty
                                    ? r.toCustomId[0].toUpperCase()
                                    : "?",
                                semanticsLabel: r.toCustomId.isNotEmpty
                                    ? "@${r.toCustomId} 的大頭貼"
                                    : "對象頭像",
                              ),
                            ),
                            title: SelectionArea(
                              child: Text("@${r.toCustomId}"),
                            ),
                            subtitle: SelectionArea(
                              child: Text(r.createdAt ?? ""),
                            ),
                            trailing: Semantics(
                              container: true,
                              label: "申請狀態，${r.status}",
                              hint: "僅顯示伺服器回傳狀態，無法在此變更",
                              excludeSemantics: true,
                              child: Chip(
                                label: SelectionArea(
                                  child: Text(r.status),
                                ),
                                visualDensity: VisualDensity.compact,
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
    );
  }
}
