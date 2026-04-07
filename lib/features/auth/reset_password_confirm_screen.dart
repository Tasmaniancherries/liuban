import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/core/ui/scroll_constants.dart";

/// 郵件內連結導向：`/reset-password?token=...`（與 [AuthApi.completePasswordResetWithToken] 對齊）。
class ResetPasswordConfirmScreen extends StatefulWidget {
  const ResetPasswordConfirmScreen({super.key, required this.initialToken});

  /// 來自 deep link query；可為空，改由使用者貼上。
  final String initialToken;

  @override
  State<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends State<ResetPasswordConfirmScreen> {
  late final TextEditingController _token;
  final _pass = TextEditingController();
  final _again = TextEditingController();
  bool _obscureP = true;
  bool _obscureA = true;
  bool _submitting = false;

  bool get _hasDraft =>
      _token.text.trim().isNotEmpty ||
      _pass.text.isNotEmpty ||
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
        label: "捨棄輸入確認",
        hint: ApiDevSemantics.discardUnsavedLocalFormDialogHint,
        child: AlertDialog(
          title: const Text("捨棄輸入？"),
          content: const SelectionArea(
            child: Text("重設憑證或新密碼已輸入，確定離開？"),
          ),
          actions: [
            Tooltip(
              message: "繼續輸入",
              child: Semantics(
                button: true,
                label: "繼續輸入",
                hint: "關閉對話框並保留已輸入內容",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("取消"),
                ),
              ),
            ),
            Tooltip(
              message: "捨棄重設表單並離開",
              child: Semantics(
                button: true,
                label: "捨棄重設表單並離開",
                hint: "離開並清除憑證與新密碼欄位",
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
  void initState() {
    super.initState();
    _token = TextEditingController(text: widget.initialToken);
    _token.addListener(_onInputChanged);
    _pass.addListener(_onInputChanged);
    _again.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _token.removeListener(_onInputChanged);
    _pass.removeListener(_onInputChanged);
    _again.removeListener(_onInputChanged);
    _token.dispose();
    _pass.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final raw = _token.text.trim();
    final p = _pass.text;
    final a = _again.text;
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          "請輸入重設憑證（token）",
          semanticsHint: ApiDevSemantics.resetPasswordTokenMissingSnackHint,
        ),
      );
      return;
    }
    if (p.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          "新密碼至少 8 字元",
          semanticsHint: ApiDevSemantics.resetPasswordTooShortSnackHint,
        ),
      );
      return;
    }
    if (p != a) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          "兩次密碼不一致",
          semanticsHint: ApiDevSemantics.resetPasswordMismatchSnackHint,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppContainerScope.of(context).auth.completePasswordResetWithToken(
            token: raw,
            newPassword: p,
          );
      if (!mounted) return;
      TextInput.finishAutofillContext(shouldSave: true);
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          "密碼已重設，請使用新密碼登入",
          semanticsHint: ApiDevSemantics.resetPasswordSuccessSnackHint,
        ),
      );
      context.go("/login");
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.resetPasswordApiErrorSnackHint,
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
          title: const Text(
            "重設密碼",
            semanticsLabel: "重設登入密碼",
          ),
          leading: Semantics(
            hint: "返回上一頁；表單有內容時會先詢問是否捨棄",
            child: IconButton(
              tooltip: "返回",
              icon: const Icon(Icons.arrow_back, semanticLabel: "返回"),
              onPressed: _submitting
                  ? null
                  : () => unawaitedDebug(
                        "ResetPasswordConfirmScreen._tryPop",
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
                label: ApiDevSemantics.passwordResetComplete,
                hint: "下方可輸入憑證與新密碼；亦可前往登入、忘記密碼或註冊",
                excludeSemantics: true,
                child: SelectionArea(
                  child: Text(
                    ApiDevSemantics.passwordResetComplete,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: "重設憑證（token）",
                hint: "貼上或輸入郵件重設連結中的 token",
                textField: true,
                child: TextField(
                  controller: _token,
                  enabled: !_submitting,
                  decoration: const InputDecoration(
                    labelText: "重設憑證（token）",
                    hintText: "郵件連結中的 token",
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: "新密碼（至少 8 字元）",
                hint: "設定新登入密碼；需與確認欄位一致",
                textField: true,
                child: TextField(
                  controller: _pass,
                  enabled: !_submitting,
                  obscureText: _obscureP,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: "新密碼（至少 8 字元）",
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      hint: _obscureP ? "暫時顯示新密碼" : "隱藏新密碼內容",
                      child: IconButton(
                        tooltip: _obscureP ? "顯示密碼" : "隱藏密碼",
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _obscureP = !_obscureP),
                        icon: Icon(
                          _obscureP
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          semanticLabel: _obscureP ? "顯示密碼" : "隱藏密碼",
                        ),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: "確認新密碼",
                hint: "再次輸入新密碼；完成後可送出重設",
                textField: true,
                child: TextField(
                  controller: _again,
                  enabled: !_submitting,
                  obscureText: _obscureA,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: "確認新密碼",
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      hint: _obscureA ? "暫時顯示確認新密碼" : "隱藏確認新密碼內容",
                      child: IconButton(
                        tooltip: _obscureA ? "顯示密碼" : "隱藏密碼",
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _obscureA = !_obscureA),
                        icon: Icon(
                          _obscureA
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          semanticLabel: _obscureA ? "顯示密碼" : "隱藏密碼",
                        ),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_submitting) return;
                    unawaitedDebug(
                      "ResetPasswordConfirmScreen._submit",
                      _submit(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              Tooltip(
                message: "完成密碼重設",
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: "完成密碼重設",
                  hint: _submitting ? "處理中" : "套用新密碼並完成重設",
                  excludeSemantics: true,
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : () => unawaitedDebug(
                              "ResetPasswordConfirmScreen._submit",
                              _submit(),
                            ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              semanticsLabel: "處理中",
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("完成重設"),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Tooltip(
                message: "回到登入",
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: "返回登入",
                  hint: "前往登入頁",
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: _submitting ? null : () => context.go("/login"),
                    child: const Text("返回登入"),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Tooltip(
                message: "忘記密碼",
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: "忘記密碼",
                  hint: "開啟郵箱重設與客服說明",
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => unawaitedDebugFuture(
                              "ResetPasswordConfirmScreen.pushForgotPassword",
                              context.push("/forgot-password"),
                            ),
                    child: const Text("忘記密碼？"),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Tooltip(
                message: "前往註冊並提交身分審核",
                child: Semantics(
                  button: true,
                  enabled: !_submitting,
                  label: "前往註冊並提交身分審核",
                  hint: "開啟註冊表單；可上傳 Offer、錄取證明或學生證",
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => unawaitedDebugFuture(
                              "ResetPasswordConfirmScreen.pushRegister",
                              context.push("/register"),
                            ),
                    child: const Text("還沒有帳號？註冊"),
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
