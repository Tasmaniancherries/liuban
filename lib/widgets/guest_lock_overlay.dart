import "package:flutter/material.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";

/// 訪客／審核中時遮住子內容，展示說明（符合 PRD：本校／好友須正式用戶）。
class GuestLockOverlay extends StatelessWidget {
  const GuestLockOverlay({
    super.key,
    required this.locked,
    required this.child,
    required this.title,
    required this.message,
    this.onGoToLogin,
    this.onGoToRegister,
  });

  final bool locked;
  final Widget child;
  final String title;
  final String message;

  /// 鎖定時可選：前往登入（例如 `context.push("/login")`）。
  final VoidCallback? onGoToLogin;

  /// 鎖定時可選：前往註冊（例如 `context.push("/register")`）。
  final VoidCallback? onGoToRegister;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final hasAuthShortcuts =
        onGoToLogin != null || onGoToRegister != null;
    final lockHint = hasAuthShortcuts
        ? "底層內容已鎖定，可使用下方按鈕前往登入或註冊，通過身分審核後可使用完整功能 ${ApiDevSemantics.docsTrail}"
        : "底層內容已鎖定，完成登入或身分審核後可使用完整功能 ${ApiDevSemantics.docsTrail}";

    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(child: Opacity(opacity: 0.25, child: child)),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Semantics(
              container: true,
              label: "$title。$message",
              hint: lockHint,
              excludeSemantics: true,
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          semanticLabel: "功能受限",
                          size: 40,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      SelectionArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (hasAuthShortcuts) ...[
                        const SizedBox(height: 20),
                        if (onGoToLogin != null)
                          Tooltip(
                            message: "前往登入",
                            child: Semantics(
                              button: true,
                              label: "前往登入",
                              hint: "開啟登入頁",
                              excludeSemantics: true,
                              child: FilledButton(
                                onPressed: onGoToLogin,
                                child: const Text("前往登入"),
                              ),
                            ),
                          ),
                        if (onGoToRegister != null) ...[
                          if (onGoToLogin != null) const SizedBox(height: 8),
                          Tooltip(
                            message: "前往註冊並提交身分審核",
                            child: Semantics(
                              button: true,
                              label: "前往註冊並提交身分審核",
                              hint: "開啟註冊表單；可上傳 Offer、錄取證明或學生證",
                              excludeSemantics: true,
                              child: OutlinedButton(
                                onPressed: onGoToRegister,
                                child: const Text("還沒有帳號？註冊"),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
