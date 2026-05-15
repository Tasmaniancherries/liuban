import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/core/text/liuban_input_limits.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';
import 'package:liuban/core/ui/liuban_api_exception_snack_hint.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';
import 'package:liuban/core/ui/scroll_constants.dart';

/// 忘記密碼：郵箱重設或聯絡客服。
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _email = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

  /// 未成功寄信前，只要郵箱欄有內容或正在送出，任何分頁返回都先確認（避免切到客服後誤退仍丟草稿）。
  bool get _emailFormBlocking =>
      !_sent && (_submitting || _email.text.trim().isNotEmpty);

  void _onEmailChanged() => setState(() {});

  Future<void> _tryPop() async {
    if (_submitting) return;
    if (!_emailFormBlocking) {
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
          content: const SelectionArea(child: Text('已輸入郵箱，確定離開？')),
          actions: [
            Tooltip(
              message: '繼續輸入',
              child: Semantics(
                button: true,
                label: '繼續輸入',
                hint: '關閉對話框並保留郵箱欄位',
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('取消'),
                ),
              ),
            ),
            Tooltip(
              message: '捨棄郵箱內容並離開',
              child: Semantics(
                button: true,
                label: '捨棄郵箱內容並離開',
                hint: '離開並清除已輸入的郵箱',
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
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _email.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _email.removeListener(_onEmailChanged);
    _email.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String s) {
    final t = s.trim();
    return t.contains('@') && t.length >= 5;
  }

  Future<void> _sendEmail() async {
    final addr = _email.text.trim();
    if (addr.length > LiubanInputLimits.emailMaxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.inputTooLongMessage(
            '郵箱',
            LiubanInputLimits.emailMaxLength,
          ),
          semanticsHint: ApiDevSemantics.forgotPasswordEmailTooLongSnackHint(
            LiubanInputLimits.emailMaxLength,
          ),
        ),
      );
      return;
    }
    if (!_looksLikeEmail(addr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          '請輸入有效郵箱',
          semanticsHint: ApiDevSemantics.forgotPasswordInvalidEmailSnackHint,
        ),
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await AppContainerScope.of(
        context,
      ).auth.requestPasswordResetEmail(email: addr);
      if (!mounted) return;
      setState(() => _sent = true);
    } on LiubanApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          e.message,
          semanticsHint: liubanApiExceptionSnackHint(
            e,
            defaultHint: ApiDevSemantics.forgotPasswordApiErrorSnackHint,
            clientTooLongHint:
                ApiDevSemantics.forgotPasswordEmailTooLongSnackHint(
                  LiubanInputLimits.emailMaxLength,
                ),
          ),
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
    final blockPop = _emailFormBlocking;

    return PopScope(
      canPop: !blockPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _tryPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('忘記密碼', semanticsLabel: '忘記密碼與重設'),
          leading: Semantics(
            hint: '返回上一頁；郵箱分頁有輸入時可能先詢問是否捨棄',
            child: IconButton(
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back, semanticLabel: '返回'),
              onPressed: _submitting
                  ? null
                  : () => unawaitedDebug(
                      'ForgotPasswordScreen._tryPop',
                      _tryPop(),
                    ),
            ),
          ),
          bottom: TabBar(
            controller: _tabs,
            tabs: [
              Tab(
                child: Semantics(
                  hint: '切換至以郵箱寄送重設連結',
                  child: const Text('郵箱重設', semanticsLabel: '以郵箱重設密碼'),
                ),
              ),
              Tab(
                child: Semantics(
                  hint: '切換至官方客服協助與身分核實說明',
                  child: const Text('客服協助', semanticsLabel: '透過客服協助重設'),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _buildEmailTab(context),
            _SupportPanel(onPopLogin: _tryPop),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailTab(BuildContext context) {
    if (_sent) {
      return ListView(
        cacheExtent: kLiubanListCacheExtent,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 56,
            semanticLabel: '重設郵件已寄出',
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            label:
                '若該郵箱已註冊留伴，我們已寄出重設信。請檢查收件匣與垃圾郵件。'
                '為安全起見，未註冊的郵箱不會提示「是否存在」；連結開啟後請在「重設密碼」頁設定新密碼。',
            hint: '下方可改用其他郵箱或返回登入',
            excludeSemantics: true,
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '若該郵箱已註冊留伴，我們已寄出重設信。請檢查收件匣與垃圾郵件。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '為安全起見，未註冊的郵箱不會提示「是否存在」；連結開啟後請在「重設密碼」頁設定新密碼。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Tooltip(
            message: '重新輸入郵箱',
            child: Semantics(
              button: true,
              label: '重新輸入郵箱',
              hint: '回到郵件輸入步驟，可改用其他信箱',
              excludeSemantics: true,
              child: OutlinedButton(
                onPressed: () => setState(() => _sent = false),
                child: const Text('改用其他郵箱'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '返回登入',
            child: Semantics(
              button: true,
              label: '返回登入',
              hint: '離開忘記密碼並回到登入畫面',
              excludeSemantics: true,
              child: TextButton(
                onPressed: () =>
                    unawaitedDebug('ForgotPasswordScreen._tryPop', _tryPop()),
                child: const Text('返回登入'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '前往註冊並提交身分審核',
            child: Semantics(
              button: true,
              label: '前往註冊並提交身分審核',
              hint: '開啟註冊表單；可上傳 Offer、錄取證明或學生證',
              excludeSemantics: true,
              child: TextButton(
                onPressed: () => unawaitedDebugFuture(
                  'ForgotPasswordScreen._emailTabSent.pushRegister',
                  context.push('/register'),
                ),
                child: const Text('還沒有帳號？註冊'),
              ),
            ),
          ),
        ],
      );
    }

    return AutofillGroup(
      child: ListView(
        cacheExtent: kLiubanListCacheExtent,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          Semantics(
            header: true,
            label:
                '${ApiDevSemantics.forgotPasswordIntro} ${ApiDevSemantics.passwordResetRequest}',
            hint: '下方可輸入郵箱並寄送重設信',
            excludeSemantics: true,
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ApiDevSemantics.forgotPasswordIntro,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ApiDevSemantics.passwordResetRequest,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            label: '郵箱',
            hint: '輸入註冊信箱以寄送重設連結',
            textField: true,
            child: TextField(
              controller: _email,
              enabled: !_submitting,
              maxLength: LiubanInputLimits.emailMaxLength + 1,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '郵箱',
                hintText: 'name@university.edu.hk',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => unawaitedDebug(
                'ForgotPasswordScreen._sendEmail',
                _sendEmail(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Tooltip(
            message: '發送密碼重設郵件',
            child: Semantics(
              button: true,
              enabled: !_submitting,
              label: '發送密碼重設郵件',
              hint: _submitting ? '處理中' : '寄送重設連結至所填郵箱',
              excludeSemantics: true,
              child: FilledButton(
                onPressed: _submitting
                    ? null
                    : () => unawaitedDebug(
                        'ForgotPasswordScreen._sendEmail',
                        _sendEmail(),
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
                    : const Text('發送重設信'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Tooltip(
            message: '使用郵件內的重設憑證',
            child: Semantics(
              button: true,
              label: '使用郵件內的重設憑證',
              hint: '開啟輸入重設憑證頁面',
              excludeSemantics: true,
              child: TextButton(
                onPressed: () => unawaitedDebugFuture(
                  'ForgotPasswordScreen._emailTabForm.pushResetPassword',
                  context.push('/reset-password'),
                ),
                child: const Text('已有郵件連結？前往輸入 token'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '返回登入',
            child: Semantics(
              button: true,
              label: '返回登入',
              hint: '關閉並回到登入畫面',
              excludeSemantics: true,
              child: TextButton(
                onPressed: () =>
                    unawaitedDebug('ForgotPasswordScreen._tryPop', _tryPop()),
                child: const Text('返回登入'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '前往註冊並提交身分審核',
            child: Semantics(
              button: true,
              label: '前往註冊並提交身分審核',
              hint: '開啟註冊表單；可上傳 Offer、錄取證明或學生證',
              excludeSemantics: true,
              child: TextButton(
                onPressed: () => unawaitedDebugFuture(
                  'ForgotPasswordScreen._emailTabForm.pushRegister',
                  context.push('/register'),
                ),
                child: const Text('還沒有帳號？註冊'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel({required this.onPopLogin});

  final Future<void> Function() onPopLogin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      cacheExtent: kLiubanListCacheExtent,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(20),
      children: [
        Semantics(
          header: true,
          label: '若無法收信或帳號僅綁定自訂 ID，可聯絡官方客服核實身分後協助處理。',
          hint: '下方可開啟客服、註冊或返回登入',
          excludeSemantics: true,
          child: SelectionArea(
            child: Text(
              '若無法收信或帳號僅綁定自訂 ID，可聯絡官方客服核實身分後協助處理。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Tooltip(
          message: '開啟官方客服對話',
          child: Semantics(
            button: true,
            label: '開啟官方客服對話',
            hint: '開啟官方客服聊天畫面',
            excludeSemantics: true,
            child: FilledButton(
              onPressed: () => unawaitedDebugFuture(
                'ForgotPasswordScreen._SupportPanel.pushSupport',
                context.push('/support'),
              ),
              child: const Text('前往官方客服'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: '返回登入',
          child: Semantics(
            button: true,
            label: '返回登入',
            hint: '關閉並回到忘記密碼分頁的登入入口',
            excludeSemantics: true,
            child: TextButton(
              onPressed: () => unawaitedDebug(
                'ForgotPasswordScreen._tryPop.support',
                onPopLogin(),
              ),
              child: const Text('返回登入'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: '前往註冊並提交身分審核',
          child: Semantics(
            button: true,
            label: '前往註冊並提交身分審核',
            hint: '開啟註冊表單；可上傳 Offer、錄取證明或學生證',
            excludeSemantics: true,
            child: TextButton(
              onPressed: () => unawaitedDebugFuture(
                'ForgotPasswordScreen._SupportPanel.pushRegister',
                context.push('/register'),
              ),
              child: const Text('還沒有帳號？註冊'),
            ),
          ),
        ),
      ],
    );
  }
}
