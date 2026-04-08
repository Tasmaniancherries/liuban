import "package:flutter/material.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/core/network/api_exception.dart";

/// 廣場檢舉：選原因 → [FeedApi.reportPost]。
Future<void> runFeedReportFlow(
  BuildContext context, {
  required String postId,
}) async {
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => Semantics(
      container: true,
      label: "檢舉此動態",
      hint: ApiDevSemantics.feedReportDialogIntro,
      child: AlertDialog(
        title: const Text("檢舉此動態"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectionArea(
              child: Text(
                ApiDevSemantics.feedReportDialogIntro,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Tooltip(
              message: "檢舉原因：垃圾或廣告",
              child: Semantics(
                button: true,
                label: "檢舉原因，垃圾或廣告",
                hint: "選取後送出此檢舉原因",
                excludeSemantics: true,
                child: ListTile(
                  title: const Text("垃圾或廣告"),
                  onTap: () => Navigator.of(ctx).pop("spam"),
                ),
              ),
            ),
            Tooltip(
              message: "檢舉原因：騷擾或仇恨",
              child: Semantics(
                button: true,
                label: "檢舉原因，騷擾或仇恨",
                hint: "選取後送出此檢舉原因",
                excludeSemantics: true,
                child: ListTile(
                  title: const Text("騷擾或仇恨"),
                  onTap: () => Navigator.of(ctx).pop("harassment"),
                ),
              ),
            ),
            Tooltip(
              message: "檢舉原因：其他",
              child: Semantics(
                button: true,
                label: "檢舉原因，其他",
                hint: "選取後送出此檢舉原因",
                excludeSemantics: true,
                child: ListTile(
                  title: const Text("其他"),
                  onTap: () => Navigator.of(ctx).pop("other"),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: "關閉，不檢舉",
            child: Semantics(
              button: true,
              label: "關閉，不檢舉",
              hint: "關閉對話框，不送出檢舉",
              excludeSemantics: true,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("取消"),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  if (code == null || !context.mounted) return;
  try {
    await AppContainerScope.of(
      context,
    ).feed.reportPost(postId: postId, reason: code);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        "已收到檢舉，感謝回饋",
        semanticsHint: ApiDevSemantics.feedReportSuccessSnackHint,
      ),
    );
  } on LiubanApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        e.message,
        semanticsHint: ApiDevSemantics.feedReportErrorSnackHint,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        ApiDevSemantics.feedModerationGenericFailureMessage,
        semanticsHint: ApiDevSemantics.feedModerationGenericFailureSnackHint,
      ),
    );
  }
}

/// 屏蔽用戶（廣場／動態作者），對齊 [FriendsApi.blockUser]。
Future<void> runBlockUserFlow(
  BuildContext context, {
  required String userId,
}) async {
  if (userId.isEmpty) return;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => Semantics(
      container: true,
      label: "屏蔽此用戶確認",
      hint: ApiDevSemantics.blockUserApiNote,
      child: AlertDialog(
        title: const Text("屏蔽此用戶"),
        content: SelectionArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "確定屏蔽？此用戶的內容將依平台規則從你的視角隱藏，可於「設定 · 已屏蔽用戶」解除。",
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                ApiDevSemantics.blockUserApiNote,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Tooltip(
            message: "取消",
            child: Semantics(
              button: true,
              label: "取消屏蔽",
              hint: "關閉對話框，不執行屏蔽",
              excludeSemantics: true,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("取消"),
              ),
            ),
          ),
          Tooltip(
            message: "確認屏蔽",
            child: Semantics(
              button: true,
              label: "確認屏蔽此用戶",
              hint: "確認後向伺服器提交屏蔽",
              excludeSemantics: true,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("屏蔽"),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  if (confirm != true || !context.mounted) return;
  try {
    await AppContainerScope.of(context).friends.blockUser(userId: userId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        "已提交屏蔽，內容將依後端策略更新",
        semanticsHint: ApiDevSemantics.blockUserSuccessSnackHint,
      ),
    );
  } on LiubanApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        e.message,
        semanticsHint: ApiDevSemantics.blockUserErrorSnackHint,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        ApiDevSemantics.feedModerationGenericFailureMessage,
        semanticsHint: ApiDevSemantics.feedModerationGenericFailureSnackHint,
      ),
    );
  }
}

/// 刪除自己的動態（確認後呼叫 [FeedApi.deletePost]）。成功回傳 `true`。
Future<bool> runDeleteOwnPostFlow(
  BuildContext context, {
  required String postId,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => Semantics(
      container: true,
      label: "刪除此動態確認",
      hint: ApiDevSemantics.deleteOwnPostApiNote,
      child: AlertDialog(
        title: const Text("刪除此動態"),
        content: SelectionArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("確定刪除？此操作無法復原。", style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(
                ApiDevSemantics.deleteOwnPostApiNote,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Tooltip(
            message: "取消刪除",
            child: Semantics(
              button: true,
              label: "取消刪除",
              hint: "關閉對話框，保留此動態",
              excludeSemantics: true,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("取消"),
              ),
            ),
          ),
          Tooltip(
            message: "確認刪除此動態",
            child: Semantics(
              button: true,
              label: "確認刪除此動態",
              hint: "確認後將永久刪除此則動態",
              excludeSemantics: true,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("刪除"),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return false;
  try {
    await AppContainerScope.of(context).feed.deletePost(postId);
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        "已刪除",
        semanticsHint: ApiDevSemantics.deleteOwnPostSuccessSnackHint,
      ),
    );
    return true;
  } on LiubanApiException catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        e.message,
        semanticsHint: ApiDevSemantics.deleteOwnPostErrorSnackHint,
      ),
    );
    return false;
  } catch (_) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      liubanSnackBarWithSemanticsHint(
        ApiDevSemantics.feedModerationGenericFailureMessage,
        semanticsHint: ApiDevSemantics.feedModerationGenericFailureSnackHint,
      ),
    );
    return false;
  }
}
