import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/core/ui/scroll_constants.dart';
import 'package:liuban/features/promotion/promotion_models.dart';
import 'package:liuban/features/promotion/promotion_share.dart';

class _PromotionListLoad {
  const _PromotionListLoad({
    required this.items,
    required this.loadFailed,
    this.apiFailureSnackMessage,
  });

  final List<PromotionItem> items;
  final bool loadFailed;
  final String? apiFailureSnackMessage;
}

class PromotionListScreen extends StatefulWidget {
  const PromotionListScreen({super.key});

  @override
  State<PromotionListScreen> createState() => _PromotionListScreenState();
}

class _PromotionListScreenState extends State<PromotionListScreen> {
  Future<_PromotionListLoad>? _future;

  Future<_PromotionListLoad> _load() async {
    final container = AppContainerScope.of(context);
    try {
      final dtos = await container.promotion.listPromotions();
      return _PromotionListLoad(
        items: dtos.map(PromotionItem.fromDto).toList(),
        loadFailed: false,
      );
    } on LiubanApiException catch (e) {
      return _PromotionListLoad(
        items: const <PromotionItem>[],
        loadFailed: true,
        apiFailureSnackMessage: e.message,
      );
    } catch (_) {
      return const _PromotionListLoad(items: <PromotionItem>[], loadFailed: true);
    }
  }

  Future<_PromotionListLoad> _loadAndNotify() async {
    final r = await _load();
    if (r.loadFailed && mounted) {
      final apiMsg = r.apiFailureSnackMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          liubanSnackBarWithSemanticsHint(
            apiMsg ?? ApiDevSemantics.promotionListLoadFailedMessage,
            semanticsHint: apiMsg != null
                ? ApiDevSemantics.promotionListGetApiErrorSnackHint
                : ApiDevSemantics.promotionListLoadFailedSnackHint,
          ),
        );
      });
    }
    return r;
  }

  Future<void> _onRefresh() async {
    final next = _loadAndNotify();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    _future ??= _loadAndNotify();

    return Scaffold(
      appBar: AppBar(title: const Text('推廣', semanticsLabel: '推廣與活動列表')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FutureBuilder<_PromotionListLoad>(
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
                        child: CircularProgressIndicator(semanticsLabel: '載入中'),
                      ),
                    ),
                  );
                }
                final load = snap.data!;
                final items = load.items;
                return ListView(
                  cacheExtent: kLiubanListCacheExtent,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Semantics(
                        header: true,
                        label: ApiDevSemantics.promotionListBanner,
                        hint: '下方為推廣列表，點擊進詳情；長按可分享連結',
                        excludeSemantics: true,
                        child: SelectionArea(
                          child: Text(
                            ApiDevSemantics.promotionListBanner,
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
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Semantics(
                            container: true,
                            label: '暫無推廣內容',
                            hint: '下拉可重新整理',
                            excludeSemantics: true,
                            child: SelectionArea(
                              child: Text(
                                '暫無推廣內容',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (var i = 0; i < items.length; i++) ...[
                      if (i != 0) const Divider(height: 1),
                      Tooltip(
                        message: '點擊看詳情；長按分享連結',
                        child: Semantics(
                          button: true,
                          label:
                              '${items[i].title}。${items[i].subtitle} · ${items[i].publishedAt}',
                          hint: '點擊看詳情；長按分享連結',
                          customSemanticsActions:
                              <CustomSemanticsAction, VoidCallback>{
                                const CustomSemanticsAction(
                                  label: '分享或複製此推廣連結',
                                ): () => unawaitedDebug(
                                  'PromotionListScreen.openPromotionShareActions',
                                  openPromotionShareActions(
                                    context,
                                    items[i].id,
                                  ),
                                ),
                              },
                          excludeSemantics: true,
                          child: ListTile(
                            title: SelectionArea(
                              child: Text(
                                items[i].title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            subtitle: SelectionArea(
                              child: Text(
                                '${items[i].subtitle} · ${items[i].publishedAt}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              semanticLabel: '前往詳情',
                            ),
                            onTap: () => unawaitedDebugFuture(
                              'PromotionListScreen.openDetail',
                              context.push('/promotion/${items[i].id}'),
                            ),
                            onLongPress: () => unawaitedDebug(
                              'PromotionListScreen.openPromotionShareActions',
                              openPromotionShareActions(context, items[i].id),
                            ),
                          ),
                        ),
                      ),
                    ],
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
