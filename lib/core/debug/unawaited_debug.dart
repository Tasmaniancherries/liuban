import "dart:async";

import "package:flutter/foundation.dart";

/// Fire-and-forget [Future<void>]；僅在 [kDebugMode] 下將失敗印至 console（例如 persistence／表單送出）。
/// 若為帶回傳值的 [Future]（例如 `context.push`、[Future<bool>]），請用 [unawaitedDebugFuture]。
void unawaitedDebug(String label, Future<void> future) {
  unawaited(
    future.catchError((Object e, StackTrace st) {
      if (kDebugMode) {
        debugPrint("Liuban [$label] failed: $e\n$st");
      }
    }),
  );
}

/// 與 [unawaitedDebug] 相同，但接受任意 [Future<T>]（go_router 的 [BuildContext.push]、[Navigator.push] 等）。
void unawaitedDebugFuture<T>(String label, Future<T> future) {
  unawaitedDebug(label, future.then((_) {}));
}
