import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/text/account_input_normalize.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';

/// 雙向好友：搜尋對方自訂 ID 並發出申請。
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _id = TextEditingController();
  bool _submitting = false;

  bool get _hasDraft => normalizeLeadingAtCustomId(_id.text).isNotEmpty;

  void _onInputChanged() => setState(() {});

  Future<void> _tryPop() async {
    if (_submitting) return;
    if (!_hasDraft) {
      if (mounted) context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => Semantics(
        container: true,
        label: '捨棄輸入確認',
        hint: ApiDevSemantics.discardUnsavedLocalFormDialogHint,
        child: AlertDialog(
          title: const Text('捨棄輸入？'),
          content: const SelectionArea(child: Text('已輸入對方 ID，確定離開？')),
          actions: [
            Tooltip(
              message: '繼續輸入',
              child: Semantics(
                button: true,
                label: '繼續輸入',
                hint: '關閉對話框並保留對方 ID',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('取消'),
                ),
              ),
            ),
            Tooltip(
              message: '捨棄對方 ID 並離開',
              child: Semantics(
                button: true,
                label: '捨棄對方 ID 並離開',
                hint: '離開並清除已輸入的 ID',
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
  void initState() {
    super.initState();
    _id.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _id.removeListener(_onInputChanged);
    _id.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final raw = normalizeLeadingAtCustomId(_id.text);
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '請輸入 ID',
          semanticsHint: ApiDevSemantics.addFriendIdEmptySnackHint,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppContainerScope.of(
        context,
      ).friends.sendFriendRequest(targetCustomId: raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '已向 @$raw 發出好友申請',
          semanticsHint: ApiDevSemantics.addFriendRequestSentSnackHint,
        ),
      );
      context.pop();
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.addFriendApiErrorSnackHint,
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
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasDraft && !_submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _tryPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('添加好友', semanticsLabel: '添加好友申請'),
          leading: Semantics(
            hint: '返回上一頁；已輸入對方 ID 時會先詢問是否捨棄',
            child: IconButton(
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
              onPressed: _submitting
                  ? null
                  : () => unawaitedDebug('AddFriendScreen._tryPop', _tryPop()),
            ),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                label: '輸入對方自訂 ID（無粉絲機制，需對方通過後成為雙向好友）。',
                hint: '下方可輸入 ID 並送出好友申請',
                excludeSemantics: true,
                child: SelectionArea(
                  child: Text(
                    '輸入對方自訂 ID（無粉絲機制，需對方通過後成為雙向好友）。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: '對方 ID',
                hint: '輸入對方自訂 ID；前置 @ 為顯示用，可使用鍵盤完成送出申請',
                textField: true,
                child: TextField(
                  controller: _id,
                  enabled: !_submitting,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: '對方 ID',
                    hintText: '例如 river_2026',
                    prefixText: '@',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    if (_submitting) return;
                    unawaitedDebug('AddFriendScreen._submit', _submit());
                  },
                ),
              ),
              const SizedBox(height: 24),
              Tooltip(
                message: '發送好友申請',
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: '發送好友申請',
                  hint: ApiDevSemantics.friendRequestSubmitHint(
                    submitting: _submitting,
                  ),
                  excludeSemantics: true,
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : () => unawaitedDebug(
                            'AddFriendScreen._submit',
                            _submit(),
                          ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              semanticsLabel: '處理中',
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('發送申請'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
