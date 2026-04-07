import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:go_router/go_router.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/data/models/feed_post_dto.dart";
import "package:liuban/features/feed/feed_post_share.dart";
import "package:liuban/features/feed/feed_report_flow.dart";

class _ResolvedPost {
  const _ResolvedPost({
    required this.post,
    required this.fromListFallback,
    this.listFallbackApiMessage,
  });

  final FeedPostDto post;
  final bool fromListFallback;

  /// 非空表示單篇 GET 為 [LiubanApiException]，畫面暫用列表快取帖文。
  final String? listFallbackApiMessage;
}

/// 廣場單篇：優先自伺服器載入單筆動態（路徑見 `ApiDevSemantics`／docs 契約，`id` 經 [Uri.encodeComponent]）；
/// 失敗時使用列表頁傳入之 [fallback]。
class FeedPostDetailScreen extends StatefulWidget {
  const FeedPostDetailScreen({
    super.key,
    required this.postId,
    this.fallback,
  });

  final String postId;
  final FeedPostDto? fallback;

  @override
  State<FeedPostDetailScreen> createState() => _FeedPostDetailScreenState();
}

class _FeedPostDetailScreenState extends State<FeedPostDetailScreen> {
  Future<_ResolvedPost?>? _future;
  var _started = false;
  String? _myUserId;
  var _notifiedFetchMeFailure = false;

  /// 僅在 [LiubanApiException] 且無 [FeedPostDetailScreen.fallback] 時，供 [_loadAndNotify] 顯示後端訊息。
  String? _pendingGetPostFailureApiMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _future = _loadAndNotify();
    unawaitedDebug(
      "FeedPostDetailScreen._loadMyUserId",
      _loadMyUserId(),
    );
  }

  void _refreshDetail() {
    setState(() => _future = _loadAndNotify());
    unawaitedDebug(
      "FeedPostDetailScreen._loadMyUserId",
      _loadMyUserId(),
    );
  }

  Future<void> _onPullRefresh() async {
    final next = _loadAndNotify();
    setState(() => _future = next);
    await next;
    await _loadMyUserId();
  }

  Future<void> _loadMyUserId() async {
    final t = AppContainerScope.of(context).sessionTokens.accessToken;
    if (t == null || t.isEmpty) {
      if (mounted) {
        setState(() {
          _myUserId = null;
          _notifiedFetchMeFailure = false;
        });
      }
      return;
    }
    try {
      final me = await AppContainerScope.of(context).auth.fetchMe();
      if (!mounted) return;
      setState(() {
        _myUserId = me.userId.isEmpty ? null : me.userId;
        _notifiedFetchMeFailure = false;
      });
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      setState(() => _myUserId = null);
      if (_notifiedFetchMeFailure) return;
      _notifiedFetchMeFailure = true;
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
      if (_notifiedFetchMeFailure) return;
      _notifiedFetchMeFailure = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            ApiDevSemantics.feedPostDetailFetchMeFailedMessage,
            semanticsHint: ApiDevSemantics.authMeFetchGenericFailureSnackHint,
          ),
        );
      });
    }
  }

  Future<_ResolvedPost?> _load() async {
    _pendingGetPostFailureApiMessage = null;
    try {
      final dto =
          await AppContainerScope.of(context).feed.getPost(widget.postId);
      return _ResolvedPost(post: dto, fromListFallback: false);
    } on LiubanApiException catch (e) {
      if (widget.fallback != null) {
        return _ResolvedPost(
          post: widget.fallback!,
          fromListFallback: true,
          listFallbackApiMessage: e.message,
        );
      }
      _pendingGetPostFailureApiMessage = e.message;
      return null;
    } catch (_) {
      if (widget.fallback != null) {
        return _ResolvedPost(post: widget.fallback!, fromListFallback: true);
      }
      return null;
    }
  }

  Future<_ResolvedPost?> _loadAndNotify() async {
    final r = await _load();
    if (!mounted) return r;
    if (r != null && r.fromListFallback) {
      final apiMsg = r.listFallbackApiMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            apiMsg ?? ApiDevSemantics.feedPostDetailListFallbackSnackMessage,
            semanticsHint: apiMsg != null
                ? ApiDevSemantics.feedPostGetApiErrorSnackHint
                : ApiDevSemantics.feedPostDetailListFallbackSnackHint,
          ),
        );
      });
    } else if (r == null) {
      final apiMsg = _pendingGetPostFailureApiMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            apiMsg ?? ApiDevSemantics.feedPostDetailLoadFailedTitle,
            semanticsHint: apiMsg != null
                ? ApiDevSemantics.feedPostGetApiErrorSnackHint
                : ApiDevSemantics.feedPostDetailLoadFailedSemanticsHint,
          ),
        );
      });
    }
    return r;
  }

  Future<void> _onReport() => runFeedReportFlow(context, postId: widget.postId);

  Future<void> _onBlockAuthor(String authorId) =>
      runBlockUserFlow(context, userId: authorId);

  Future<void> _onDelete() async {
    final ok = await runDeleteOwnPostFlow(context, postId: widget.postId);
    if (ok && mounted) context.pop();
  }

  Future<void> _onShareLink() =>
      openFeedPostShareActions(context, widget.postId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "動態詳情",
          semanticsLabel: "單則廣場動態詳情",
        ),
        leading: Semantics(
          hint: "關閉動態詳情並返回上一頁",
          child: IconButton(
            tooltip: "返回",
            icon: const Icon(Icons.arrow_back, semanticLabel: "返回"),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          FutureBuilder<_ResolvedPost?>(
            future: _future,
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              if (snap.data == null) {
                return const SizedBox.shrink();
              }
              final post = snap.data!.post;
              final isMine = _myUserId != null &&
                  post.authorId.isNotEmpty &&
                  post.authorId == _myUserId;
              final canBlock = post.authorId.isNotEmpty && !isMine;
              final canModerateOthers = !isMine;
              return Semantics(
                hint: "開啟選單：分享、編輯或刪除（本人）、檢舉與屏蔽等",
                child: PopupMenuButton<String>(
                  tooltip: "更多",
                  icon: const Icon(Icons.more_vert, semanticLabel: "更多選項"),
                  onSelected: (v) async {
                    if (v == "share") {
                      await _onShareLink();
                    } else if (v == "edit" && isMine) {
                      final enc = Uri.encodeComponent(post.id);
                      final summary = await this.context.push<String>(
                            "/compose/edit/$enc",
                            extra: post,
                          );
                      if (!mounted) return;
                      if (summary != null) {
                        _refreshDetail();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          liubanSnackBarWithSemanticsHint(
                            summary,
                            semanticsHint:
                                ApiDevSemantics.feedComposeEditSavedSnackHint,
                          ),
                        );
                      }
                    } else if (v == "delete" && isMine) {
                      await _onDelete();
                    } else if (v == "report" && canModerateOthers) {
                      await _onReport();
                    } else if (v == "block" && canBlock) {
                      await _onBlockAuthor(post.authorId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: "share",
                      child: Text(
                        "分享連結",
                        semanticsLabel: "分享此動態連結",
                      ),
                    ),
                    if (isMine) ...[
                      const PopupMenuItem<String>(
                        value: "edit",
                        child: Text("編輯", semanticsLabel: "編輯此動態"),
                      ),
                      const PopupMenuItem<String>(
                        value: "delete",
                        child: Text("刪除", semanticsLabel: "刪除此動態"),
                      ),
                    ],
                    if (canModerateOthers)
                      const PopupMenuItem<String>(
                        value: "report",
                        child: Text("檢舉", semanticsLabel: "檢舉此動態"),
                      ),
                    if (canBlock)
                      const PopupMenuItem<String>(
                        value: "block",
                        child: Text(
                          "屏蔽此用戶",
                          semanticsLabel: "屏蔽動態作者",
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_ResolvedPost?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(semanticsLabel: "載入中"),
            );
          }
          final resolved = snap.data;
          if (resolved == null) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: _onPullRefresh,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                container: true,
                                label: ApiDevSemantics
                                    .feedPostDetailLoadFailedTitle,
                                hint: ApiDevSemantics
                                    .feedPostDetailLoadFailedSemanticsHint,
                                excludeSemantics: true,
                                child: SelectionArea(
                                  child: Text(
                                    ApiDevSemantics
                                        .feedPostDetailLoadFailedTitle,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Tooltip(
                                message: "返回上一頁",
                                child: Semantics(
                                  button: true,
                                  label: "返回上一頁",
                                  hint: "離開錯誤狀態並回到上一頁",
                                  excludeSemantics: true,
                                  child: FilledButton(
                                    onPressed: () => context.pop(),
                                    child: const Text("返回"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          final p = resolved.post;
          final audience = p.audience;
          final authorLabel = p.authorDisplay.isEmpty ? "匿名" : p.authorDisplay;
          return RefreshIndicator(
            onRefresh: _onPullRefresh,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Semantics(
                customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                  const CustomSemanticsAction(
                    label: "分享或複製此動態連結",
                  ): () => unawaitedDebug(
                        "FeedPostDetailScreen._onShareLink",
                        _onShareLink(),
                      ),
                },
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (resolved.fromListFallback)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Semantics(
                            container: true,
                            label: ApiDevSemantics.feedPostDetailFallbackBanner,
                            hint: "下拉頁面可重新整理；完整內容以伺服器為準",
                            excludeSemantics: true,
                            child: Text(
                              ApiDevSemantics.feedPostDetailFallbackBanner,
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
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              label: authorLabel,
                              hint: "動態作者顯示名稱",
                              excludeSemantics: true,
                              child: Text(
                                authorLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                          if (audience != null && audience.isNotEmpty)
                            Text(
                              audience,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                        ],
                      ),
                      if (p.hideSchool) ...[
                        const SizedBox(height: 8),
                        Text(
                          "作者已隱藏學校標籤",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(p.body,
                          style: Theme.of(context).textTheme.bodyLarge),
                      if (p.createdAt != null && p.createdAt!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          p.createdAt!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
