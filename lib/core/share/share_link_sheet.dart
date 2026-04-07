import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:share_plus/share_plus.dart";

Rect? _shareAnchorFromContext(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// 底部選單：複製連結或呼叫系統分享面板。
Future<void> showShareLinkSheet(BuildContext context,
    {required String url}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    routeSettings: const RouteSettings(name: "share_link_sheet"),
    builder: (ctx) {
      Future<void> copyLink() async {
        try {
          await Clipboard.setData(ClipboardData(text: url));
        } catch (_) {
          if (ctx.mounted) {
            ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
              liubanSnackBarWithSemanticsHint(
                ApiDevSemantics.shareLinkCopyFailedMessage,
                semanticsHint: ApiDevSemantics.shareLinkCopyFailedSnackHint,
              ),
            );
          }
          return;
        }
        HapticFeedback.lightImpact();
        if (ctx.mounted) Navigator.of(ctx).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            liubanSnackBarWithSemanticsHint(
              "已複製連結",
              semanticsHint: ApiDevSemantics.shareLinkCopiedSnackHint,
            ),
          );
        }
      }

      Future<void> systemShare() async {
        final origin = _shareAnchorFromContext(ctx);
        HapticFeedback.lightImpact();
        if (ctx.mounted) Navigator.of(ctx).pop();
        try {
          await Share.share(
            url,
            subject: "留伴",
            sharePositionOrigin: origin,
          );
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              liubanSnackBarWithSemanticsHint(
                ApiDevSemantics.shareLinkSystemShareFailedMessage,
                semanticsHint:
                    ApiDevSemantics.shareLinkSystemShareFailedSnackHint,
              ),
            );
          }
        }
      }

      return Semantics(
        container: true,
        label: "分享連結選項",
        hint: "可複製連結或使用系統分享面板。${ApiDevSemantics.shareLinkSheetFootnote}",
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Semantics(
                  label: "分享連結預覽，可選取複製。$url",
                  hint: "完整網址，可拖曳選取後手動複製",
                  excludeSemantics: true,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              url,
                              style:
                                  Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ApiDevSemantics.shareLinkSheetFootnote,
                              style:
                                  Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Tooltip(
                message: "複製到剪貼簿",
                child: Semantics(
                  button: true,
                  label: "複製連結",
                  hint: "複製到剪貼簿",
                  excludeSemantics: true,
                  child: ListTile(
                    leading: const Icon(
                      Icons.copy_outlined,
                      semanticLabel: "複製",
                    ),
                    title: const Text("複製連結"),
                    onTap: () => unawaitedDebug(
                      "ShareLinkSheet.copyLink",
                      copyLink(),
                    ),
                  ),
                ),
              ),
              Tooltip(
                message: "透過其他 App 分享連結",
                child: Semantics(
                  button: true,
                  label: "分享至其他 App",
                  hint: "透過系統分享連結",
                  excludeSemantics: true,
                  child: ListTile(
                    leading: const Icon(
                      Icons.ios_share_outlined,
                      semanticLabel: "系統分享",
                    ),
                    title: const Text("分享至…"),
                    onTap: () => unawaitedDebug(
                      "ShareLinkSheet.systemShare",
                      systemShare(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
