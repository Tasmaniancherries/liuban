import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/navigation/post_login_redirect.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/session/verification_phase_mapper.dart';
import 'package:liuban/core/text/account_input_normalize.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/core/ui/scroll_constants.dart';

/// 帳密登入；頂部無障礙說明見 [ApiDevSemantics.loginBanner]。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectAfterLogin});

  /// 登入成功後導向（已由路由層 [sanitizePostLoginRedirect] 檢查）。
  final String? redirectAfterLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  bool get _hasDraft {
    final account = normalizeLoginAccount(_account.text);
    return account.isNotEmpty || _password.text.isNotEmpty;
  }

  void _onInputChanged() => setState(() {});

  Future<void> _tryPop() async {
    if (_loading) return;
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
          content: const SelectionArea(child: Text('帳號或密碼已輸入，確定離開？')),
          actions: [
            Tooltip(
              message: '繼續輸入',
              child: Semantics(
                button: true,
                label: '繼續輸入',
                hint: '關閉對話框並保留帳號密碼',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('取消'),
                ),
              ),
            ),
            Tooltip(
              message: '捨棄並離開',
              child: Semantics(
                button: true,
                label: '捨棄並離開',
                hint: '離開並清除已輸入的帳號密碼',
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
    _account.addListener(_onInputChanged);
    _password.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _account.removeListener(_onInputChanged);
    _password.removeListener(_onInputChanged);
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final account = normalizeLoginAccount(_account.text);
    final password = _password.text;
    if (account.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '請輸入帳號與密碼',
          semanticsHint: ApiDevSemantics.loginValidationEmptyFieldsSnackHint,
        ),
      );
      return;
    }
    final container = AppContainerScope.of(context);
    final session = AppSessionScope.of(context);
    setState(() => _loading = true);
    try {
      final pair = await container.auth.login(
        account: account,
        password: password,
      );
      container.sessionTokens.applyPair(
        access: pair.accessToken,
        refresh: pair.refreshToken,
      );
      try {
        final st = await container.auth.fetchVerificationStatus();
        session.setPhase(accountPhaseFromVerificationApi(st.phase));
      } catch (_) {
        session.setPhase(AccountPhase.pendingVerification);
      }
      if (!mounted) return;
      TextInput.finishAutofillContext();
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '登入成功',
          semanticsHint: ApiDevSemantics.loginSuccessSnackHint,
        ),
      );
      final next = sanitizePostLoginRedirect(widget.redirectAfterLogin);
      if (next != null) {
        context.go(next);
      } else {
        context.pop();
      }
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: ApiDevSemantics.loginApiErrorSnackHint,
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading && !_hasDraft,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _tryPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('登入', semanticsLabel: '登入留伴帳號'),
          leading: Semantics(
            hint: '返回上一頁；帳密欄位有內容時會先詢問是否捨棄',
            child: IconButton(
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
              onPressed: _loading
                  ? null
                  : () => unawaitedDebug('LoginScreen._tryPop', _tryPop()),
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
                label: '使用註冊時的自訂 ID（或學校郵箱）與密碼登入。成功後會自動帶上與刷新 Token。',
                hint: '下方為帳號密碼欄位與登入動作',
                excludeSemantics: true,
                child: SelectionArea(
                  child: Text(
                    '使用註冊時的自訂 ID（或學校郵箱）與密碼登入。成功後會自動帶上與刷新 Token。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                label: '帳號',
                hint: '輸入註冊時的自訂 ID 或學校郵箱',
                textField: true,
                child: TextField(
                  controller: _account,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: '帳號',
                    hintText: '自訂 ID 或郵箱',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: '密碼',
                hint: '輸入登入密碼後可按登入或鍵盤完成送出',
                textField: true,
                child: TextField(
                  controller: _password,
                  enabled: !_loading,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: '密碼',
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      hint: _obscure ? '暫時顯示已輸入的密碼' : '隱藏密碼欄位內容',
                      child: IconButton(
                        tooltip: _obscure ? '顯示密碼' : '隱藏密碼',
                        onPressed: _loading
                            ? null
                            : () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          semanticLabel: _obscure ? '顯示密碼' : '隱藏密碼',
                        ),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_loading) return;
                    unawaitedDebug('LoginScreen._submit', _submit());
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Tooltip(
                  message: '忘記密碼',
                  child: Semantics(
                    button: true,
                    enabled: !_loading,
                    label: '忘記密碼',
                    hint: '開啟郵箱重設與客服說明',
                    excludeSemantics: true,
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () => unawaitedDebugFuture(
                              'LoginScreen.pushForgotPassword',
                              context.push('/forgot-password'),
                            ),
                      child: const Text('忘記密碼？'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Tooltip(
                message: '登入',
                child: Semantics(
                  button: true,
                  enabled: !_loading,
                  label: '登入',
                  hint: ApiDevSemantics.loginSubmitHint(loading: _loading),
                  excludeSemantics: true,
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : () =>
                              unawaitedDebug('LoginScreen._submit', _submit()),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              semanticsLabel: '處理中',
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('登入'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Tooltip(
                message: '返回上一頁',
                child: Semantics(
                  button: true,
                  enabled: !_loading,
                  label: '返回上一頁',
                  hint: '關閉登入並回到上一頁',
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () =>
                              unawaitedDebug('LoginScreen._tryPop', _tryPop()),
                    child: const Text('返回'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Tooltip(
                message: '前往註冊並提交身分審核',
                child: Semantics(
                  button: true,
                  enabled: !_loading,
                  label: '前往註冊並提交身分審核',
                  hint: '開啟註冊表單；可上傳 Offer、錄取證明或學生證',
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => unawaitedDebugFuture(
                            'LoginScreen.pushRegister',
                            context.push('/register'),
                          ),
                    child: const Text('還沒有帳號？註冊'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Tooltip(
                message: '使用郵件連結重設密碼',
                child: Semantics(
                  button: true,
                  enabled: !_loading,
                  label: '使用郵件連結重設密碼',
                  hint: '開啟輸入重設憑證頁面',
                  excludeSemantics: true,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => unawaitedDebugFuture(
                            'LoginScreen.pushResetPassword',
                            context.push('/reset-password'),
                          ),
                    child: const Text('已有郵件重設連結？'),
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
