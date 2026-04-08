import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";

/// 未帶有效 access token 時顯示登入引導，不渲染 [child]（避免誤打需登入 API）。
///
/// 說明與 API 路徑見 [ApiDevSemantics.authRequiredGateApiFootnote]。
class AuthRequiredGate extends StatelessWidget {
  const AuthRequiredGate({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  bool _hasToken(BuildContext context) {
    final t = AppContainerScope.of(context).sessionTokens.accessToken;
    return t != null && t.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppContainerScope.of(context).sessionTokens;
    return AnimatedBuilder(
      animation: tokens,
      builder: (context, _) {
        if (_hasToken(context)) return child;
        return Scaffold(
          appBar: AppBar(
            title: Text(title ?? "需要登入", semanticsLabel: title ?? "需要登入以使用此功能"),
            leading: Semantics(
              hint: "關閉登入提示並返回上一頁",
              child: IconButton(
                tooltip: "返回",
                icon: const Icon(Icons.arrow_back, semanticLabel: "返回"),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    semanticLabel: "需要登入",
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    label: ApiDevSemantics.authRequiredGateSemanticsLabel,
                    hint: "可使用前往登入、註冊或返回上一頁",
                    excludeSemantics: true,
                    child: SelectionArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "請先登入以使用此功能",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "訪客可瀏覽公開廣場與推廣；好友與私聊需帳號。",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ApiDevSemantics.authRequiredGateApiFootnote,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Tooltip(
                    message: "前往登入",
                    child: Semantics(
                      button: true,
                      label: "前往登入",
                      hint: "開啟登入頁，完成後可返回此功能",
                      excludeSemantics: true,
                      child: FilledButton(
                        onPressed: () {
                          final u = GoRouterState.of(context).uri;
                          final path = u.path.isEmpty ? "/" : u.path;
                          final target = u.hasQuery ? "$path?${u.query}" : path;
                          unawaitedDebugFuture(
                            "AuthRequiredGate.pushLogin",
                            context.push(
                              "/login?redirect=${Uri.encodeQueryComponent(target)}",
                            ),
                          );
                        },
                        child: const Text("前往登入"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: "前往註冊並提交身分審核",
                    child: Semantics(
                      button: true,
                      label: "前往註冊並提交身分審核",
                      hint: "開啟註冊表單；可上傳 Offer、錄取證明或學生證",
                      excludeSemantics: true,
                      child: OutlinedButton(
                        onPressed: () => unawaitedDebugFuture(
                          "AuthRequiredGate.pushRegister",
                          context.push("/register"),
                        ),
                        child: const Text("還沒有帳號？註冊"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: "返回上一頁",
                    child: Semantics(
                      button: true,
                      label: "返回上一頁",
                      hint: "關閉並回到上一頁",
                      excludeSemantics: true,
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text("返回"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
