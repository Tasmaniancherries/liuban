import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/core/ui/scroll_constants.dart";

class ChatMessage {
  const ChatMessage(
      {required this.text, required this.fromUser, required this.time});

  final String text;
  final bool fromUser;
  final DateTime time;
}

/// 官方客服：本地示意對話，上線後接通 IM / WebSocket
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _items = [
    ChatMessage(
      text: "你好，這裡是留伴官方客服。訪客也可留言，我們會盡快回覆。",
      fromUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  bool _sending = false;

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
        label: "捨棄未送出訊息確認",
        hint: ApiDevSemantics.discardUnsentMessageDraftHint,
        child: AlertDialog(
          title: const Text("捨棄未送出訊息？"),
          content: const SelectionArea(
            child: Text("輸入框內尚有內容，確定離開？"),
          ),
          actions: [
            Tooltip(
              message: "繼續輸入",
              child: Semantics(
                button: true,
                label: "繼續輸入",
                hint: "關閉對話框並保留輸入框內容",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("取消"),
                ),
              ),
            ),
            Tooltip(
              message: "捨棄未送出訊息",
              child: Semantics(
                button: true,
                label: "捨棄未送出訊息",
                hint: "離開並清除未送出的文字",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("捨棄"),
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

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final container = AppContainerScope.of(context);
      await container.support.sendMessage(
        text: t,
        guestToken: container.guestDeviceId,
      );
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.supportSendMessageApiErrorSnackHint,
        ),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.supportSendMessageGenericFailureMessage,
          semanticsHint:
              ApiDevSemantics.supportSendMessageGenericFailureSnackHint,
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    if (!mounted) return;
    setState(() {
      _items.add(ChatMessage(text: t, fromUser: true, time: DateTime.now()));
      _input.clear();
    });
    Future.microtask(() {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
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
          title: const Text(
            "官方客服",
            semanticsLabel: "官方客服聊天",
          ),
          leading: Semantics(
            hint: "返回上一頁；輸入框有未送出內容時會先詢問",
            child: IconButton(
              tooltip: "返回",
              icon: const Icon(Icons.arrow_back, semanticLabel: "返回"),
              onPressed: _sending
                  ? null
                  : () => unawaitedDebug(
                        "SupportChatScreen._tryPop",
                        _tryPop(),
                      ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Semantics(
                header: true,
                label: ApiDevSemantics.supportMessages,
                hint: "開發與 API 說明，下方為客服對話",
                excludeSemantics: true,
                child: SelectionArea(
                  child: Text(
                    ApiDevSemantics.supportMessages,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                cacheExtent: kLiubanListCacheExtent,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: _scroll,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final m = _items[i];
                  final align =
                      m.fromUser ? Alignment.centerRight : Alignment.centerLeft;
                  final bg = m.fromUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest;
                  final fg = m.fromUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant;
                  final timeLabel = MaterialLocalizations.of(context)
                      .formatTimeOfDay(TimeOfDay.fromDateTime(m.time));
                  final bubbleLabel = m.fromUser
                      ? "我，$timeLabel：${m.text}"
                      : "官方客服，$timeLabel：${m.text}";
                  return Align(
                    alignment: align,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                      child: Semantics(
                        container: true,
                        label: bubbleLabel,
                        hint: "聊天訊息氣泡",
                        excludeSemantics: true,
                        child: Card(
                          color: bg,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: SelectionArea(
                              child: Text(m.text, style: TextStyle(color: fg)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                        label: "訊息輸入",
                        hint: "送出鍵或傳送按鈕可送出",
                        textField: true,
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          enabled: !_sending,
                          decoration: const InputDecoration(
                            hintText: "輸入訊息⋯",
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (_sending) return;
                            unawaitedDebug("SupportChatScreen._send", _send());
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      hint: _sending ? "訊息送出中" : "送出輸入框內文字給官方客服",
                      child: IconButton.filled(
                        tooltip: "傳送",
                        onPressed: _sending
                            ? null
                            : () => unawaitedDebug(
                                  "SupportChatScreen._send",
                                  _send(),
                                ),
                        icon: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  semanticsLabel: "處理中",
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send, semanticLabel: "傳送"),
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
