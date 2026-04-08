import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/core/ui/scroll_constants.dart';
import 'package:liuban/data/models/dm_message_dto.dart';

/// 與單一好友的私聊（HTTP；之後可換 WebSocket 推播）。
class DmChatScreen extends StatefulWidget {
  const DmChatScreen({
    super.key,
    required this.peerId,
    required this.peerCustomId,
  });

  final String peerId;
  final String peerCustomId;

  @override
  State<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends State<DmChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<DmMessageDto> _items = <DmMessageDto>[];
  bool _loading = true;
  bool _sending = false;
  bool _usingMockThread = false;

  bool get _hasUnsentDraft => _input.text.trim().isNotEmpty;

  void _onInputChanged() => setState(() {});

  Future<void> _tryPop() async {
    if (_sending) return;
    if (!_hasUnsentDraft) {
      if (mounted) context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => Semantics(
        container: true,
        label: '捨棄未送出訊息確認',
        hint: ApiDevSemantics.discardUnsentMessageDraftHint,
        child: AlertDialog(
          title: const Text('捨棄未送出訊息？'),
          content: const SelectionArea(child: Text('輸入框內尚有內容，確定離開？')),
          actions: [
            Tooltip(
              message: '繼續輸入',
              child: Semantics(
                button: true,
                label: '繼續輸入',
                hint: '關閉對話框並保留輸入框內容',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('取消'),
                ),
              ),
            ),
            Tooltip(
              message: '捨棄未送出訊息',
              child: Semantics(
                button: true,
                label: '捨棄未送出訊息',
                hint: '離開並清除未送出的文字',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('捨棄'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted && discard == true) context.pop();
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await AppContainerScope.of(
        context,
      ).friends.listDmMessages(peerId: widget.peerId);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _usingMockThread = false;
      });
      _scrollToEnd();
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _items = DmMessageDto.mockThread();
        _loading = false;
        _usingMockThread = true;
      });
      _scrollToEnd();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            liubanSnackBarWithSemanticsHint(
              e.message,
              semanticsHint: ApiDevSemantics.dmThreadGetApiErrorSnackHint,
            ),
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = DmMessageDto.mockThread();
        _loading = false;
        _usingMockThread = true;
      });
      _scrollToEnd();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            liubanSnackBarWithSemanticsHint(
              ApiDevSemantics.dmThreadLoadErrorFallbackMessage,
              semanticsHint: ApiDevSemantics.dmThreadLoadErrorFallbackSnackHint,
            ),
          );
        });
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await AppContainerScope.of(
        context,
      ).friends.sendDmMessage(peerId: widget.peerId, text: t);
      if (!mounted) return;
      _input.clear();
      await _load();
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.dmSendMessageApiErrorSnackHint,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.dmSendMessageGenericFailureMessage,
          semanticsHint: ApiDevSemantics.dmSendMessageGenericFailureSnackHint,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaitedDebug('DmChatScreen._load', _load()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsentDraft && !_sending,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _tryPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '@${widget.peerCustomId}',
            semanticsLabel: '與 ${widget.peerCustomId} 的私訊',
          ),
          leading: Semantics(
            hint: '返回上一頁；輸入框有未送出內容時會先詢問',
            child: IconButton(
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
              onPressed: _sending
                  ? null
                  : () => unawaitedDebug('DmChatScreen._tryPop', _tryPop()),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Semantics(
                header: true,
                label: ApiDevSemantics.dmThread,
                hint: '開發與 API 說明，下方為聊天訊息',
                excludeSemantics: true,
                child: SelectionArea(
                  child: Text(
                    ApiDevSemantics.dmThread,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            if (_usingMockThread)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Semantics(
                  container: true,
                  label: ApiDevSemantics.dmMockThreadBannerVisibleText,
                  hint: ApiDevSemantics.dmMockThreadBannerSemanticsHint,
                  excludeSemantics: true,
                  child: SelectionArea(
                    child: Text(
                      ApiDevSemantics.dmMockThreadBannerVisibleText,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(semanticsLabel: '載入中'),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        cacheExtent: kLiubanListCacheExtent,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final m = _items[i];
                          final align = m.isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft;
                          final bg = m.isMine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest;
                          final fg = m.isMine
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant;
                          final peerLabel = widget.peerCustomId.isNotEmpty
                              ? '@${widget.peerCustomId}'
                              : '對方';
                          final timeSuffix =
                              (m.createdAt != null && m.createdAt!.isNotEmpty)
                              ? '，${m.createdAt}'
                              : '';
                          final bubbleLabel = m.isMine
                              ? '我：${m.body}$timeSuffix'
                              : '$peerLabel：${m.body}$timeSuffix';
                          return Align(
                            alignment: align,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              child: Semantics(
                                container: true,
                                label: bubbleLabel,
                                hint: '聊天訊息氣泡',
                                excludeSemantics: true,
                                child: Card(
                                  color: bg,
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: SelectionArea(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.body,
                                            style: TextStyle(color: fg),
                                          ),
                                          if (m.createdAt != null &&
                                              m.createdAt!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                m.createdAt!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: fg.withValues(
                                                        alpha: 0.7,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Semantics(
                        label: '訊息輸入',
                        hint: '送出鍵或傳送按鈕可送出',
                        textField: true,
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          enabled: !_sending,
                          decoration: const InputDecoration(
                            hintText: '輸入訊息⋯',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (_sending) return;
                            unawaitedDebug('DmChatScreen._send', _send());
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      hint: _sending ? '訊息送出中' : '送出輸入框內文字給對方',
                      child: IconButton.filled(
                        tooltip: '傳送',
                        onPressed: _sending
                            ? null
                            : () =>
                                  unawaitedDebug('DmChatScreen._send', _send()),
                        icon: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  semanticsLabel: '處理中',
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send, semanticLabel: '傳送'),
                      ),
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
