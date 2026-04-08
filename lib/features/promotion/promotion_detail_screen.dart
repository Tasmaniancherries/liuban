import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/features/promotion/promotion_models.dart';
import 'package:liuban/features/promotion/promotion_share.dart';

class _PromotionDetailLoad {
  const _PromotionDetailLoad({
    required this.item,
    required this.usedErrorFallback,
    this.apiFailureSnackMessage,
  });

  final PromotionItem? item;
  final bool usedErrorFallback;

  /// 非空時顯示後端錯誤字串（仍可能已套用本地摘要）。
  final String? apiFailureSnackMessage;
}

/// 推廣詳情；API 說明見 [ApiDevSemantics.promotionDetailDevNote]。
class PromotionDetailScreen extends StatefulWidget {
  const PromotionDetailScreen({super.key, required this.promotionId});

  final String promotionId;

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  late Future<_PromotionDetailLoad> _future;
  var _kickedOff = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_kickedOff) return;
    _kickedOff = true;
    _future = _loadWithNotify();
  }

  Future<_PromotionDetailLoad> _loadCore() async {
    final container = AppContainerScope.of(context);
    try {
      final dto = await container.promotion.getPromotion(widget.promotionId);
      return _PromotionDetailLoad(
        item: PromotionItem.fromDto(dto),
        usedErrorFallback: false,
      );
    } on LiubanApiException catch (e) {
      return _PromotionDetailLoad(
        item: promotionById(widget.promotionId),
        usedErrorFallback: true,
        apiFailureSnackMessage: e.message,
      );
    } catch (_) {
      return _PromotionDetailLoad(
        item: promotionById(widget.promotionId),
        usedErrorFallback: true,
      );
    }
  }

  Future<_PromotionDetailLoad> _loadWithNotify() async {
    final r = await _loadCore();
    if (r.usedErrorFallback && mounted) {
      final apiMsg = r.apiFailureSnackMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            apiMsg ?? ApiDevSemantics.promotionDetailErrorFallbackMessage,
            semanticsHint: apiMsg != null
                ? ApiDevSemantics.promotionDetailGetApiErrorSnackHint
                : ApiDevSemantics.promotionDetailErrorFallbackSnackHint,
          ),
        );
      });
    }
    return r;
  }

  Future<void> _onPullRefresh() async {
    final next = _loadWithNotify();
    setState(() => _future = next);
    await next;
  }

  Future<void> _shareLink() =>
      openPromotionShareActions(context, widget.promotionId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推廣詳情', semanticsLabel: '推廣活動詳情'),
        leading: Semantics(
          hint: '關閉推廣詳情並返回上一頁',
          child: IconButton(
            tooltip: '返回',
            icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          FutureBuilder<_PromotionDetailLoad>(
            future: _future,
            builder: (context, snap) {
              final busy = snap.connectionState != ConnectionState.done;
              final loaded = snap.connectionState == ConnectionState.done;
              final item = snap.data?.item;
              final hasItem = item != null;
              final canShare = loaded && hasItem;
              return Semantics(
                hint: busy
                    ? '內容載入完成後可分享連結'
                    : hasItem
                    ? '開啟複製或系統分享此推廣連結'
                    : '推廣內容未載入，無法分享連結',
                child: IconButton(
                  tooltip: '分享連結',
                  icon: const Icon(Icons.share_outlined, semanticLabel: '分享連結'),
                  onPressed: canShare
                      ? () => unawaitedDebug(
                          'PromotionDetailScreen._shareLink',
                          _shareLink(),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_PromotionDetailLoad>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(semanticsLabel: '載入中'),
            );
          }
          final data = snap.data!;
          final p = data.item;
          if (p == null) {
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
                                label:
                                    ApiDevSemantics.promotionDetailEmptyTitle,
                                hint: ApiDevSemantics
                                    .promotionDetailEmptySemanticsHint,
                                excludeSemantics: true,
                                child: SelectionArea(
                                  child: Text(
                                    ApiDevSemantics.promotionDetailEmptyTitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Tooltip(
                                message: '返回上一頁',
                                child: Semantics(
                                  button: true,
                                  label: '返回上一頁',
                                  hint: '離開此頁並回到推廣列表或來源畫面',
                                  excludeSemantics: true,
                                  child: FilledButton(
                                    onPressed: () => context.pop(),
                                    child: const Text('返回'),
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
          final showCacheBanner = data.usedErrorFallback;
          return RefreshIndicator(
            onRefresh: _onPullRefresh,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Semantics(
                customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                  const CustomSemanticsAction(label: '分享或複製此推廣連結'): () =>
                      unawaitedDebug(
                        'PromotionDetailScreen.openPromotionShareActions',
                        openPromotionShareActions(context, widget.promotionId),
                      ),
                },
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Semantics(
                          header: true,
                          label: ApiDevSemantics.promotionDetailDevNote,
                          hint: '開發與 API 說明',
                          excludeSemantics: true,
                          child: SelectionArea(
                            child: Text(
                              ApiDevSemantics.promotionDetailDevNote,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      if (showCacheBanner) ...[
                        Semantics(
                          container: true,
                          label: ApiDevSemantics
                              .promotionDetailCacheBannerVisibleText,
                          hint: ApiDevSemantics
                              .promotionDetailCacheBannerSemanticsHint,
                          excludeSemantics: true,
                          child: Text(
                            ApiDevSemantics
                                .promotionDetailCacheBannerVisibleText,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Semantics(
                        header: true,
                        label: p.title,
                        hint: '推廣文章標題',
                        excludeSemantics: true,
                        child: Text(
                          p.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${p.subtitle}　${p.publishedAt}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        p.body,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '本頁為推廣合作內容；涉商業合作請依規標示「廣告」。洽談請至「訊息 · 官方客服」。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
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
