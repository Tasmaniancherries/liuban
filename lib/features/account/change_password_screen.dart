import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/core/ui/scroll_constants.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _obscureCur = true;
  bool _obscureNew = true;
  bool _obscureAgain = true;
  bool _submitting = false;

  bool get _hasDraft =>
      _current.text.isNotEmpty ||
      _next.text.isNotEmpty ||
      _again.text.isNotEmpty;

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
          content: const SelectionArea(child: Text('密碼欄位已輸入內容，確定離開？')),
          actions: [
            Tooltip(
              message: '繼續輸入',
              child: Semantics(
                button: true,
                label: '繼續輸入',
                hint: '關閉對話框並保留密碼欄位',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('取消'),
                ),
              ),
            ),
            Tooltip(
              message: '捨棄密碼欄位並離開',
              child: Semantics(
                button: true,
                label: '捨棄密碼欄位並離開',
                hint: '離開並清除已輸入的密碼',
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
    _current.addListener(_onInputChanged);
    _next.addListener(_onInputChanged);
    _again.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _current.removeListener(_onInputChanged);
    _next.removeListener(_onInputChanged);
    _again.removeListener(_onInputChanged);
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final cur = _current.text;
    final nw = _next.text;
    final ag = _again.text;
    if (cur.isEmpty || nw.isEmpty || ag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '請填寫完整',
          semanticsHint: ApiDevSemantics.changePasswordIncompleteSnackHint,
        ),
      );
      return;
    }
    if (nw.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '新密碼至少 8 字元',
          semanticsHint: ApiDevSemantics.changePasswordTooShortSnackHint,
        ),
      );
      return;
    }
    if (nw != ag) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '兩次新密碼不一致',
          semanticsHint: ApiDevSemantics.changePasswordMismatchSnackHint,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppContainerScope.of(
        context,
      ).auth.changePassword(currentPassword: cur, newPassword: nw);
      if (!mounted) return;
      TextInput.finishAutofillContext(shouldSave: true);
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '已更新密碼',
          semanticsHint: ApiDevSemantics.changePasswordSuccessSnackHint,
        ),
      );
      context.pop();
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.changePasswordApiErrorSnackHint,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.authSubmitGenericFailureMessage,
          semanticsHint: ApiDevSemantics.authSubmitGenericFailureSnackHint,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting && !_hasDraft,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _tryPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('修改密碼', semanticsLabel: '變更帳號密碼'),
          leading: Semantics(
            hint: '返回上一頁；密碼欄位有內容時會先詢問是否捨棄',
            child: IconButton(
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
              onPressed: _submitting
                  ? null
                  : () => unawaitedDebug(
                      'ChangePasswordScreen._tryPop',
                      _tryPop(),
                    ),
            ),
          ),
        ),
        body: AutofillGroup(
          child: ListView(
            cacheExtent: kLiubanListCacheExtent,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            children: [
              Semantics(
                header: true,
                label: ApiDevSemantics.authChangePassword,
                hint: '下方為目前密碼與新密碼欄位',
                excludeSemantics: true,
                child: SelectionArea(
                  child: Text(
                    ApiDevSemantics.authChangePassword,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: '目前密碼',
                hint: '輸入現正使用的登入密碼以驗證身分',
                textField: true,
                child: TextField(
                  controller: _current,
                  enabled: !_submitting,
                  obscureText: _obscureCur,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: '目前密碼',
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      hint: _obscureCur ? '暫時顯示目前密碼' : '隱藏目前密碼內容',
                      child: IconButton(
                        tooltip: _obscureCur ? '顯示密碼' : '隱藏密碼',
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _obscureCur = !_obscureCur),
                        icon: Icon(
                          _obscureCur
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          semanticLabel: _obscureCur ? '顯示密碼' : '隱藏密碼',
                        ),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: '新密碼（至少 8 字元）',
                hint: '設定新的登入密碼；需與確認欄位一致',
                textField: true,
                child: TextField(
                  controller: _next,
                  enabled: !_submitting,
                  obscureText: _obscureNew,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: '新密碼（至少 8 字元）',
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      hint: _obscureNew ? '暫時顯示新密碼' : '隱藏新密碼內容',
                      child: IconButton(
                        tooltip: _obscureNew ? '顯示密碼' : '隱藏密碼',
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _obscureNew = !_obscureNew),
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          semanticLabel: _obscureNew ? '顯示密碼' : '隱藏密碼',
                        ),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: '確認新密碼',
                hint: '再次輸入新密碼；完成後可送出修改',
                textField: true,
                child: TextField(
                  controller: _again,
                  enabled: !_submitting,
                  obscureText: _obscureAgain,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: '確認新密碼',
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      hint: _obscureAgain ? '暫時顯示確認新密碼' : '隱藏確認新密碼內容',
                      child: IconButton(
                        tooltip: _obscureAgain ? '顯示密碼' : '隱藏密碼',
                        onPressed: _submitting
                            ? null
                            : () => setState(
                                () => _obscureAgain = !_obscureAgain,
                              ),
                        icon: Icon(
                          _obscureAgain
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          semanticLabel: _obscureAgain ? '顯示密碼' : '隱藏密碼',
                        ),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_submitting) return;
                    unawaitedDebug('ChangePasswordScreen._submit', _submit());
                  },
                ),
              ),
              const SizedBox(height: 28),
              Tooltip(
                message: '確認修改密碼',
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: '確認修改密碼',
                  hint: _submitting ? '處理中' : '送出後以新密碼登入',
                  excludeSemantics: true,
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : () => unawaitedDebug(
                            'ChangePasswordScreen._submit',
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
                        : const Text('確認修改'),
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
