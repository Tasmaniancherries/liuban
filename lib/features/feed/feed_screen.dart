import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/persistence/app_persistence_scope.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/core/ui/scroll_constants.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/features/feed/feed_post_share.dart';
import 'package:liuban/features/feed/feed_report_flow.dart';
import 'package:liuban/widgets/guest_lock_overlay.dart';
import 'package:liuban/widgets/phase_badge.dart';

enum FeedStreamKind { public, school, friends }

extension on FeedStreamKind {
  String get listHint => switch (this) {
    FeedStreamKind.public => ApiDevSemantics.feedPublicList,
    FeedStreamKind.school => ApiDevSemantics.feedSchoolList,
    FeedStreamKind.friends => ApiDevSemantics.feedFriendsList,
  };
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tab;
  int _feedRefreshTick = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tab != null) return;
    final persistence = AppPersistenceScope.maybeOf(context);
    final initial = persistence?.readFeedTabIndex() ?? 0;
    final tab = TabController(length: 3, vsync: this, initialIndex: initial);
    tab.addListener(_persistFeedTabIndex);
    _tab = tab;
  }

  void _persistFeedTabIndex() {
    if (!mounted) return;
    final tab = _tab;
    if (tab == null || tab.indexIsChanging) return;
    final persistence = AppPersistenceScope.maybeOf(context);
    if (persistence == null) return;
    unawaitedDebug(
      'FeedScreen.writeFeedTabIndex',
      persistence.writeFeedTabIndex(tab.index),
    );
  }

  @override
  void dispose() {
    final tab = _tab;
    if (tab != null) {
      tab.removeListener(_persistFeedTabIndex);
      tab.dispose();
    }
    super.dispose();
  }

  Future<void> _onComposeFabPressed() async {
    final result = await context.push<String>('/compose');
    if (!mounted) return;
    if (result == null) return;
    setState(() => _feedRefreshTick++);
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        '已發佈：$result',
        semanticsHint: ApiDevSemantics.feedComposeNewPostSuccessSnackHint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tab;
    if (tab == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(semanticsLabel: '載入中')),
      );
    }
    final session = AppSessionScope.of(context);

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('留伴 · 廣場', semanticsLabel: '留伴廣場動態'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  hint: '帳戶審核階段標籤，僅顯示',
                  child: const PhaseBadge(),
                ),
              ),
            ],
            bottom: TabBar(
              controller: tab,
              tabs: [
                Tab(
                  child: Semantics(
                    hint: '切換至公開廣場動態分頁',
                    child: const Text('公開', semanticsLabel: '公開廣場動態'),
                  ),
                ),
                Tab(
                  child: Semantics(
                    hint: '切換至本校同儕可見動態分頁',
                    child: const Text('本校', semanticsLabel: '本校可見動態'),
                  ),
                ),
                Tab(
                  child: Semantics(
                    hint: '切換至雙向好友動態分頁',
                    child: const Text('好友', semanticsLabel: '好友動態'),
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: tab,
            children: [
              _FeedStreamTab(
                kind: FeedStreamKind.public,
                refreshTick: _feedRefreshTick,
                guestLocked: false,
              ),
              GuestLockOverlay(
                locked: session.isGuestLike,
                title: '本校動態',
                message: '登入並通過身分審核後，可瀏覽與發佈本校可見內容。',
                onGoToLogin: () => unawaitedDebugFuture(
                  'FeedScreen.guestLockGoToLogin',
                  context.push('/login'),
                ),
                onGoToRegister: () => unawaitedDebugFuture(
                  'FeedScreen.guestLockGoToRegister',
                  context.push('/register'),
                ),
                child: _FeedStreamTab(
                  kind: FeedStreamKind.school,
                  refreshTick: _feedRefreshTick,
                  guestLocked: session.isGuestLike,
                ),
              ),
              GuestLockOverlay(
                locked: session.isGuestLike,
                title: '好友動態',
                message: '通過審核並互相添加好友後，可在此查看好友動態。',
                onGoToLogin: () => unawaitedDebugFuture(
                  'FeedScreen.guestLockGoToLogin',
                  context.push('/login'),
                ),
                onGoToRegister: () => unawaitedDebugFuture(
                  'FeedScreen.guestLockGoToRegister',
                  context.push('/register'),
                ),
                child: _FeedStreamTab(
                  kind: FeedStreamKind.friends,
                  refreshTick: _feedRefreshTick,
                  guestLocked: session.isGuestLike,
                ),
              ),
            ],
          ),
          floatingActionButton: session.canUseSchoolAndFriends
              ? Semantics(
                  button: true,
                  label: '撰寫並發佈動態',
                  hint: '開啟撰寫動態頁面。${ApiDevSemantics.feedComposeFabHint}',
                  excludeSemantics: true,
                  child: FloatingActionButton.extended(
                    tooltip: '撰寫並發佈動態',
                    onPressed: () => unawaitedDebug(
                      'FeedScreen._onComposeFabPressed',
                      _onComposeFabPressed(),
                    ),
                    icon: const Icon(Icons.edit, semanticLabel: '撰寫並發佈動態'),
                    label: const Text('發佈'),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _FeedStreamTab extends StatefulWidget {
  const _FeedStreamTab({
    required this.kind,
    required this.refreshTick,
    required this.guestLocked,
  });

  final FeedStreamKind kind;
  final int refreshTick;

  /// 訪客鎖定頁：不呼叫需登入 API，避免 401 清 token。
  final bool guestLocked;

  @override
  State<_FeedStreamTab> createState() => _FeedStreamTabState();
}

class _FeedStreamTabState extends State<_FeedStreamTab>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 20;

  @override
  bool get wantKeepAlive => true;

  final List<FeedPostDto> _posts = <FeedPostDto>[];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _usingMock = false;
  int _page = 1;
  var _seenTick = 0;
  String? _myUserId;
  String? _lastSeenAccessToken;
  var _notifiedFeedFetchMeFailure = false;

  @override
  void initState() {
    super.initState();
    _seenTick = widget.refreshTick;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyLockedOrReload());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = AppContainerScope.of(context).sessionTokens.accessToken;
    if (t != _lastSeenAccessToken) {
      _lastSeenAccessToken = t;
      unawaitedDebug('FeedStreamTab._refreshMyUserId', _refreshMyUserId());
    }
  }

  @override
  void didUpdateWidget(covariant _FeedStreamTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guestLocked != widget.guestLocked) {
      unawaitedDebug('FeedStreamTab._refreshMyUserId', _refreshMyUserId());
      _applyLockedOrReload();
    }
  }

  Future<void> _refreshMyUserId() async {
    if (!mounted) return;
    final token = AppContainerScope.of(context).sessionTokens.accessToken;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _myUserId = null;
          _notifiedFeedFetchMeFailure = false;
        });
      }
      return;
    }
    try {
      final me = await AppContainerScope.of(context).auth.fetchMe();
      if (!mounted) return;
      setState(() {
        _myUserId = me.userId.isEmpty ? null : me.userId;
        _notifiedFeedFetchMeFailure = false;
      });
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      setState(() => _myUserId = null);
      if (_notifiedFeedFetchMeFailure) return;
      _notifiedFeedFetchMeFailure = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            e.message,
            semanticsHint: ApiDevSemantics.authMeLoadApiErrorSnackHint,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _myUserId = null);
      if (_notifiedFeedFetchMeFailure) return;
      _notifiedFeedFetchMeFailure = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            ApiDevSemantics.feedStreamFetchMeFailedMessage,
            semanticsHint: ApiDevSemantics.authMeFetchGenericFailureSnackHint,
          ),
        );
      });
    }
  }

  void _applyLockedOrReload() {
    if (!mounted) return;
    if (widget.guestLocked && widget.kind != FeedStreamKind.public) {
      setState(() {
        _posts.clear();
        _initialLoading = false;
        _loadingMore = false;
        _hasMore = false;
        _usingMock = false;
        _page = 1;
      });
      return;
    }
    unawaitedDebug('FeedStreamTab._reloadFromStart', _reloadFromStart());
  }

  Future<void> _fetchPage(int page, {required bool replace}) async {
    if (widget.guestLocked && widget.kind != FeedStreamKind.public) {
      return;
    }
    final container = AppContainerScope.of(context);
    late List<FeedPostDto> batch;
    try {
      batch = switch (widget.kind) {
        FeedStreamKind.public => await container.feed.listPublicFeed(
          page: page,
        ),
        FeedStreamKind.school => await container.feed.listSchoolFeed(
          page: page,
        ),
        FeedStreamKind.friends => await container.feed.listFriendsFeed(
          page: page,
        ),
      };
      if (replace && page == 1) {
        _usingMock = false;
      }
    } on LiubanApiException catch (e) {
      if (replace && page == 1) {
        batch = switch (widget.kind) {
          FeedStreamKind.public => FeedPostDto.mockPublicFeed(),
          FeedStreamKind.school => FeedPostDto.mockSchoolFeed(),
          FeedStreamKind.friends => FeedPostDto.mockFriendsFeed(),
        };
        _usingMock = true;
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              liubanSnackBarWithSemanticsHint(
                e.message,
                semanticsHint: ApiDevSemantics.feedInitialLoadApiErrorSnackHint,
              ),
            );
          });
        }
      } else {
        if (mounted) {
          setState(() => _loadingMore = false);
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            liubanSnackBarWithSemanticsHint(
              e.message,
              semanticsHint: ApiDevSemantics.feedLoadMoreApiErrorSnackHint,
            ),
          );
        }
        return;
      }
    } catch (_) {
      if (replace && page == 1) {
        batch = switch (widget.kind) {
          FeedStreamKind.public => FeedPostDto.mockPublicFeed(),
          FeedStreamKind.school => FeedPostDto.mockSchoolFeed(),
          FeedStreamKind.friends => FeedPostDto.mockFriendsFeed(),
        };
        _usingMock = true;
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              liubanSnackBarWithSemanticsHint(
                ApiDevSemantics.feedInitialLoadFallbackMessage,
                semanticsHint: ApiDevSemantics.feedInitialLoadFallbackSnackHint,
              ),
            );
          });
        }
      } else {
        if (mounted) {
          setState(() => _loadingMore = false);
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            liubanSnackBarWithSemanticsHint(
              ApiDevSemantics.feedLoadMoreFailedMessage,
              semanticsHint: ApiDevSemantics.feedLoadMoreFailedSnackHint,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _initialLoading = false;
      _loadingMore = false;
      if (replace) {
        _posts
          ..clear()
          ..addAll(batch);
      } else {
        final seen = _posts.map((FeedPostDto e) => e.id).toSet();
        for (final FeedPostDto p in batch) {
          if (!seen.contains(p.id)) {
            _posts.add(p);
            seen.add(p.id);
          }
        }
      }
      _page = page;
      if (_usingMock) {
        _hasMore = false;
      } else {
        _hasMore = batch.length >= _pageSize;
      }
    });
  }

  Future<void> _reloadFromStart() async {
    if (!mounted) return;
    if (widget.guestLocked && widget.kind != FeedStreamKind.public) {
      return;
    }
    if (_posts.isEmpty) {
      setState(() => _initialLoading = true);
    }
    await _fetchPage(1, replace: true);
  }

  Future<void> _onRefresh() async {
    await _reloadFromStart();
    await _refreshMyUserId();
  }

  Future<void> _onLoadMore() async {
    if (_loadingMore || !_hasMore || _usingMock) return;
    setState(() => _loadingMore = true);
    await _fetchPage(_page + 1, replace: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_seenTick != widget.refreshTick) {
      _seenTick = widget.refreshTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.guestLocked && widget.kind != FeedStreamKind.public) {
            _applyLockedOrReload();
          } else {
            unawaitedDebug(
              'FeedStreamTab._reloadFromStart',
              _reloadFromStart(),
            );
          }
        }
      });
    }

    if (widget.guestLocked && widget.kind != FeedStreamKind.public) {
      return _buildListView(
        context,
        posts: const <FeedPostDto>[],
        hint: '解鎖後才會向伺服器請求此列表。',
        showLoadMore: false,
        usingMock: false,
      );
    }

    if (_initialLoading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(
                  child: CircularProgressIndicator(semanticsLabel: '載入中'),
                ),
              ),
            ),
          );
        },
      );
    }

    return _buildListView(
      context,
      posts: _posts,
      hint: widget.kind.listHint,
      showLoadMore: !_usingMock && _hasMore,
      usingMock: _usingMock,
    );
  }

  Widget _buildListView(
    BuildContext context, {
    required List<FeedPostDto> posts,
    required String hint,
    required bool showLoadMore,
    required bool usingMock,
  }) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        cacheExtent: kLiubanListCacheExtent,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              header: true,
              label: hint,
              hint: '資料來源與列表說明，下方為動態貼文',
              excludeSemantics: true,
              child: SelectionArea(
                child: Text(
                  hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          if (usingMock) ...[
            const SizedBox(height: 6),
            Semantics(
              container: true,
              label: ApiDevSemantics.feedMockDataBannerVisibleText,
              hint: ApiDevSemantics.feedMockDataBannerSemanticsHint,
              excludeSemantics: true,
              child: SelectionArea(
                child: Text(
                  ApiDevSemantics.feedMockDataBannerVisibleText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ],
          if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Semantics(
                  container: true,
                  label: '暫無動態',
                  hint: '下拉頁面可重新整理列表',
                  excludeSemantics: true,
                  child: SelectionArea(
                    child: Text(
                      '暫無動態',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ),
          for (var i = 0; i < posts.length; i++) ...[
            if (i != 0) const SizedBox(height: 12),
            _FeedPostCard(
              post: posts[i],
              myUserId: _myUserId,
              onPostRemoved: (id) =>
                  setState(() => _posts.removeWhere((e) => e.id == id)),
              onPostEdited: _reloadFromStart,
            ),
          ],
          if (showLoadMore) ...[
            const SizedBox(height: 8),
            Center(
              child: _loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          semanticsLabel: '處理中',
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Tooltip(
                      message: '載入更多動態',
                      child: Semantics(
                        button: true,
                        label: '載入更多動態',
                        hint: '向伺服器載入下一頁貼文',
                        excludeSemantics: true,
                        child: TextButton(
                          onPressed: () => unawaitedDebug(
                            'FeedStreamTab._onLoadMore',
                            _onLoadMore(),
                          ),
                          child: const Text('載入更多'),
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

String _feedPostCardSemanticLabel(FeedPostDto p) {
  final who = p.authorDisplay.isEmpty ? '匿名' : p.authorDisplay;
  final scope = (p.audience != null && p.audience!.isNotEmpty)
      ? '可見範圍 ${p.audience}'
      : '';
  var snippet = p.body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (snippet.length > 120) {
    snippet = '${snippet.substring(0, 120)}⋯';
  }
  final time = (p.createdAt != null && p.createdAt!.isNotEmpty)
      ? '。${p.createdAt}'
      : '';
  final hide = p.hideSchool ? '。作者已隱藏學校標籤' : '';
  return "$who${scope.isNotEmpty ? "。$scope" : ""}$hide。$snippet$time";
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.post,
    this.myUserId,
    this.onPostRemoved,
    this.onPostEdited,
  });

  final FeedPostDto post;
  final String? myUserId;
  final void Function(String postId)? onPostRemoved;
  final Future<void> Function()? onPostEdited;

  bool _isMine(FeedPostDto p) =>
      myUserId != null && p.authorId.isNotEmpty && p.authorId == myUserId;

  @override
  Widget build(BuildContext context) {
    final p = post;
    final audience = p.audience;
    final isMine = _isMine(p);
    void openDetail() {
      final enc = Uri.encodeComponent(p.id);
      unawaitedDebugFuture(
        'FeedScreen._FeedPostCard.openDetail',
        context.push('/post/$enc', extra: p),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: '查看動態詳情',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: _feedPostCardSemanticLabel(p),
                hint: '開啟完整動態詳情',
                customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                  const CustomSemanticsAction(label: '分享或複製此動態連結'): () =>
                      unawaitedDebug(
                        'FeedScreen.openFeedPostShareActions',
                        openFeedPostShareActions(context, p.id),
                      ),
                },
                excludeSemantics: true,
                child: InkWell(
                  onTap: openDetail,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  p.authorDisplay.isEmpty
                                      ? '匿名'
                                      : p.authorDisplay,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              if (audience != null && audience.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 4,
                                    top: 2,
                                  ),
                                  child: Text(
                                    audience,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.body,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (p.createdAt != null &&
                              p.createdAt!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              p.createdAt!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 4),
              child: Semantics(
                hint: '開啟選單：分享、編輯或刪除（本人）、檢舉與屏蔽等',
                child: PopupMenuButton<String>(
                  tooltip: '更多',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    Icons.more_vert,
                    size: 22,
                    semanticLabel: '更多選項',
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  onSelected: (v) async {
                    if (v == 'share') {
                      await openFeedPostShareActions(context, p.id);
                    } else if (v == 'edit' && isMine) {
                      final enc = Uri.encodeComponent(p.id);
                      final summary = await context.push<String>(
                        '/compose/edit/$enc',
                        extra: p,
                      );
                      if (!context.mounted) return;
                      if (summary != null) {
                        await onPostEdited?.call();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            liubanSnackBarWithSemanticsHint(
                              summary,
                              semanticsHint:
                                  ApiDevSemantics.feedComposeEditSavedSnackHint,
                            ),
                          );
                        }
                      }
                    } else if (v == 'delete' && isMine) {
                      final ok = await runDeleteOwnPostFlow(
                        context,
                        postId: p.id,
                      );
                      if (ok && context.mounted) {
                        onPostRemoved?.call(p.id);
                      }
                    } else if (v == 'report' && !isMine) {
                      await runFeedReportFlow(context, postId: p.id);
                    } else if (v == 'block' &&
                        !isMine &&
                        p.authorId.isNotEmpty) {
                      await runBlockUserFlow(context, userId: p.authorId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Text('分享連結', semanticsLabel: '分享此動態連結'),
                    ),
                    if (isMine) ...[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('編輯', semanticsLabel: '編輯此動態'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('刪除', semanticsLabel: '刪除此動態'),
                      ),
                    ],
                    if (!isMine)
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Text('檢舉', semanticsLabel: '檢舉此動態'),
                      ),
                    if (p.authorId.isNotEmpty && !isMine)
                      const PopupMenuItem<String>(
                        value: 'block',
                        child: Text('屏蔽此用戶', semanticsLabel: '屏蔽動態作者'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
