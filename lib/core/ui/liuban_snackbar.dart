import 'package:flutter/material.dart';

/// 與 Material [SnackBar] 預設顯示時間一致（`packages/flutter/.../snack_bar.dart` 之 `_snackBarDisplayDuration`）。
const Duration _kLiubanSnackBarDefaultDuration = Duration(milliseconds: 4000);

Widget _liubanSnackBarLiveContent(Widget child) {
  return Semantics(liveRegion: true, child: child);
}

/// 短暫提示：為內容加上 [Semantics.liveRegion]，方便螢幕閱讀器播報。
///
/// [SnackBar.behavior] 未設定時由 [SnackBarTheme]（留伴主題為浮動）決定。
/// [duration] 為 null 時沿用與 [SnackBar] 相同的預設顯示時間。
SnackBar liubanSnackBar(
  String message, {
  Duration? duration,
  SnackBarAction? action,
}) {
  return SnackBar(
    content: _liubanSnackBarLiveContent(Text(message)),
    duration: duration ?? _kLiubanSnackBarDefaultDuration,
    action: action,
  );
}

/// 與 [liubanSnackBar] 相同之外觀，另為螢幕閱讀器提供 [semanticsHint]（不影響可視文字）。
SnackBar liubanSnackBarWithSemanticsHint(
  String message, {
  required String semanticsHint,
  Duration? duration,
  SnackBarAction? action,
}) {
  return SnackBar(
    content: Semantics(
      liveRegion: true,
      label: message,
      hint: semanticsHint,
      excludeSemantics: true,
      child: Text(message),
    ),
    duration: duration ?? _kLiubanSnackBarDefaultDuration,
    action: action,
  );
}

/// 與 [liubanSnackBar] 相同之無障礙包裝，但 [content] 可為複合 Widget（例如多行或 RichText）。
SnackBar liubanSnackBarContent(
  Widget content, {
  Duration? duration,
  SnackBarAction? action,
}) {
  return SnackBar(
    content: _liubanSnackBarLiveContent(content),
    duration: duration ?? _kLiubanSnackBarDefaultDuration,
    action: action,
  );
}
