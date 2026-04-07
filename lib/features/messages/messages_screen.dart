import "package:flutter/material.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:go_router/go_router.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/core/persistence/app_persistence_scope.dart";
import "package:liuban/core/session/app_session_scope.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/core/ui/scroll_constants.dart";
import "package:liuban/data/models/friend_inbox_item_dto.dart";
import "package:liuban/widgets/guest_lock_overlay.dart";

class _FriendsInboxLoad {
  const _FriendsInboxLoad({
    required this.items,
    required this.usedErrorFallback,
    this.apiFailureSnackMessage,
  });

  final List<FriendInboxItemDto> items;
  final bool usedErrorFallback;
  final String? apiFailureSnackMessage;
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _inboxRefreshTick = 0;

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final initialTab =
            AppPersistenceScope.maybeOf(context)?.readMessagesTabIndex() ?? 0;
        return DefaultTabController(
          length: 2,
          initialIndex: initialTab.clamp(0, 1),
          child: _MessagesTabPersistenceBinder(
            child: Scaffold(
              appBar: AppBar(
                title: const Text(
                  "訊息",
                  semanticsLabel: "訊息與客服",
                ),
                bottom: TabBar(
                  tabs: [
                    Tab(
                      child: Semantics(
                        hint: "切換至官方客服與訪客留言分頁",
                        child: const Text(
                          "官方客服",
                          semanticsLabel: "官方客服對話入口",
                        ),
                      ),
                    ),
                    Tab(
                      child: Semantics(
                        hint: "切換至好友私訊收件匣分頁",
                        child: const Text(
                          "好友",
                          semanticsLabel: "好友私信列表",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  const _SupportEntry(),
                  GuestLockOverlay(
                    locked: session.isGuestLike,
                    title: "好友私信",
                    message: "通過身分審核並互為好友後，可在此發起聊天。",
                    onGoToLogin: () => unawaitedDebugFuture(
                          "MessagesScreen.guestLockGoToLogin",
                          context.push("/login"),
                        ),
                    onGoToRegister: () => unawaitedDebugFuture(
                          "MessagesScreen.guestLockGoToRegister",
                          context.push("/register"),
                        ),
                    child: _FriendsInbox(
                      refreshTick: _inboxRefreshTick,
                      guestLocked: session.isGuestLike,
                      onAddFriend: () async {
                        await context.push<void>("/add-friend");
                        if (!mounted) return;
                        setState(() => _inboxRefreshTick++);
                      },
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

class _MessagesTabPersistenceBinder extends StatefulWidget {
  const _MessagesTabPersistenceBinder({required this.child});

  final Widget child;

  @override
  State<_MessagesTabPersistenceBinder> createState() =>
      _MessagesTabPersistenceBinderState();
}

class _MessagesTabPersistenceBinderState
    extends State<_MessagesTabPersistenceBinder> {
  TabController? _tab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DefaultTabController.of(context);
    if (!identical(_tab, next)) {
      _tab?.removeListener(_onTabChanged);
      _tab = next;
      _tab!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    final c = _tab;
    if (c == null || c.indexIsChanging || !mounted) return;
    final p = AppPersistenceScope.maybeOf(context);
    if (p == null) return;
    unawaitedDebug(
      "MessagesScreen.writeMessagesTabIndex",
      p.writeMessagesTabIndex(c.index),
    );
  }

  @override
  void dispose() {
    _tab?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SupportEntry extends StatefulWidget {
  const _SupportEntry();

  @override
  State<_SupportEntry> createState() => _SupportEntryState();
}

class _SupportEntryState extends State<_SupportEntry>
    with AutomaticKeepAliveClientMixin {
  bool _showBanner = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        if (_showBanner)
          MaterialBanner(
            content: Semantics(
              liveRegion: true,
              container: true,
              label: "提示。${ApiDevSemantics.supportGuestBanner}",
              hint: "可使用知道了關閉此橫幅",
              excludeSemantics: true,
              child: Text(ApiDevSemantics.supportGuestBanner),
            ),
            actions: [
              Tooltip(
                message: "關閉提示",
                child: Semantics(
                  button: true,
                  label: "關閉訪客提示",
                  hint: "隱藏此訪客說明橫幅",
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: () => setState(() => _showBanner = false),
                    child: const Text("知道了"),
                  ),
                ),
              ),
            ],
          ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 56,
                    semanticLabel: "客服",
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    label: "與留伴客服對話",
                    hint: "下方按鈕可進入官方客服聊天",
                    excludeSemantics: true,
                    child: Text(
                      "與留伴客服對話",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    container: true,
                    label: "說明。合作、申訴、審核問題皆可留言。商家洽談也可走此通道。"
                        " ${ApiDevSemantics.supportMessages}",
                    hint: "客服通道用途說明",
                    excludeSemantics: true,
                    child: SelectionArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "合作、申訴、審核問題皆可留言。商家洽談也可走此通道。",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ApiDevSemantics.supportMessages,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Tooltip(
                    message: "進入對話",
                    child: Semantics(
                      button: true,
                      label: "進入官方客服對話",
                      hint: "開啟官方客服聊天畫面",
                      excludeSemantics: true,
                      child: FilledButton.icon(
                        onPressed: () => unawaitedDebugFuture(
                              "MessagesScreen._SupportEntry.pushSupport",
                              context.push<void>("/support"),
                            ),
                        icon: const Icon(Icons.chat, semanticLabel: "進入對話"),
                        label: const Text("進入對話"),
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
  }
}

class _FriendsInbox extends StatefulWidget {
  const _FriendsInbox({
    required this.refreshTick,
    required this.guestLocked,
    required this.onAddFriend,
  });

  final int refreshTick;
  final bool guestLocked;
  final Future<void> Function() onAddFriend;

  @override
  State<_FriendsInbox> createState() => _FriendsInboxState();
}

class _FriendsInboxState extends State<_FriendsInbox>
    with AutomaticKeepAliveClientMixin {
  Future<_FriendsInboxLoad>? _future;
  var _seenTick = -1;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant _FriendsInbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guestLocked != widget.guestLocked ||
        oldWidget.refreshTick != widget.refreshTick) {
      _future = _loadAndNotify();
    }
  }

  Future<_FriendsInboxLoad> _load() async {
    if (widget.guestLocked) {
      return const _FriendsInboxLoad(
        items: <FriendInboxItemDto>[],
        usedErrorFallback: false,
      );
    }
    final container = AppContainerScope.of(context);
    try {
      final list = await container.friends.listInbox();
      return _FriendsInboxLoad(items: list, usedErrorFallback: false);
    } on LiubanApiException catch (e) {
      return _FriendsInboxLoad(
        items: FriendInboxItemDto.mockInbox(),
        usedErrorFallback: true,
        apiFailureSnackMessage: e.message,
      );
    } catch (_) {
      return _FriendsInboxLoad(
        items: FriendInboxItemDto.mockInbox(),
        usedErrorFallback: true,
      );
    }
  }

  Future<_FriendsInboxLoad> _loadAndNotify() async {
    final r = await _load();
    if (r.usedErrorFallback && mounted) {
      final apiMsg = r.apiFailureSnackMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            apiMsg ?? ApiDevSemantics.friendsInboxErrorFallbackMessage,
            semanticsHint: apiMsg != null
                ? ApiDevSemantics.friendsInboxGetApiErrorSnackHint
                : ApiDevSemantics.friendsInboxErrorFallbackSnackHint,
          ),
        );
      });
    }
    return r;
  }

  Future<void> _pullRefresh() async {
    final next = _loadAndNotify();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.guestLocked) {
      return Column(
        children: [
          _InboxHeader(
            onAddFriend: widget.onAddFriend,
            showRequestsLink: false,
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      );
    }

    if (_seenTick != widget.refreshTick) {
      _seenTick = widget.refreshTick;
      _future = _loadAndNotify();
    }
    _future ??= _loadAndNotify();

    return Column(
      children: [
        _InboxHeader(
          onAddFriend: widget.onAddFriend,
          showRequestsLink: !widget.guestLocked,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: _pullRefresh,
                child: FutureBuilder<_FriendsInboxLoad>(
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Semantics(
                            header: true,
                            label: ApiDevSemantics.friendsInbox,
                            hint: "下方為好友私訊會話列表",
                            excludeSemantics: true,
                            child: SelectionArea(
                              child: Text(
                                ApiDevSemantics.friendsInbox,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        if (usingMock)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Semantics(
                              container: true,
                              label: ApiDevSemantics
                                  .friendsInboxMockDataBannerVisibleText,
                              hint: ApiDevSemantics
                                  .friendsInboxMockDataBannerSemanticsHint,
                              excludeSemantics: true,
                              child: SelectionArea(
                                child: Text(
                                  ApiDevSemantics
                                      .friendsInboxMockDataBannerVisibleText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Center(
                              child: Semantics(
                                container: true,
                                label: "暫無好友會話",
                                hint: "下拉可重新整理；通過審核並互加好友後會顯示在此",
                                excludeSemantics: true,
                                child: SelectionArea(
                                  child: Text(
                                    "暫無好友會話",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          for (var i = 0; i < items.length; i++) ...[
                            if (i != 0) const Divider(height: 1),
                            _InboxTile(item: items[i]),
                          ],
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item});

  final FriendInboxItemDto item;

  @override
  Widget build(BuildContext context) {
    final m = item;
    final preview = m.lastMessagePreview ?? "尚無預覽";
    return Tooltip(
      message: "開啟與 @${m.peerCustomId} 的私聊",
      child: Semantics(
        button: true,
        label: "@${m.peerCustomId}。$preview",
        hint: "開啟與 @${m.peerCustomId} 的私聊",
        excludeSemantics: true,
        child: ListTile(
          leading: CircleAvatar(
            child: Text(
              m.peerCustomId.isNotEmpty ? m.peerCustomId[0].toUpperCase() : "?",
              semanticsLabel: m.peerCustomId.isNotEmpty
                  ? "@${m.peerCustomId} 的大頭貼"
                  : "私訊對象頭像",
            ),
          ),
          title: SelectionArea(
            child: Text("@${m.peerCustomId}"),
          ),
          subtitle: SelectionArea(
            child: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          onTap: () {
            final pid = Uri.encodeComponent(m.peerId);
            final u = Uri.encodeComponent(m.peerCustomId);
            unawaitedDebugFuture(
              "MessagesScreen._FriendsInboxTile.openDm",
              context.push("/dm/$pid?custom=$u"),
            );
          },
        ),
      ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({
    required this.onAddFriend,
    required this.showRequestsLink,
  });

  final Future<void> Function() onAddFriend;
  final bool showRequestsLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              label: "雙向好友 · 無粉絲數",
              hint: "此分頁為互關好友收件匣；右側可管理申請與加好友",
              excludeSemantics: true,
              child: SelectionArea(
                child: Text(
                  "雙向好友 · 無粉絲數",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
          if (showRequestsLink)
            Tooltip(
              message: "查看待處理好友申請",
              child: Semantics(
                button: true,
                label: "查看待處理好友申請",
                hint: "開啟待處理好友邀請列表",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => unawaitedDebugFuture(
                        "MessagesScreen._InboxHeader.pushFriendRequests",
                        context.push("/friend-requests"),
                      ),
                  child: const Text("待處理申請"),
                ),
              ),
            ),
          Tooltip(
            message: "添加好友",
            child: Semantics(
              button: true,
              label: "添加好友",
              hint: "開啟輸入對方 ID 以送出申請",
              excludeSemantics: true,
              child: FilledButton.tonalIcon(
                onPressed: () => unawaitedDebug(
                      "MessagesScreen._InboxHeader.onAddFriend",
                      onAddFriend(),
                    ),
                icon: const Icon(
                  Icons.person_add_alt_1,
                  size: 20,
                  semanticLabel: "添加好友",
                ),
                label: const Text("添加好友"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
