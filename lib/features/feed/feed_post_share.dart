import 'package:flutter/material.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/core/share/share_link_sheet.dart';

/// 分享／複製用動態頁 URL（`--dart-define=SHARE_LINK_ORIGIN=` 可覆寫）。
String feedPostShareUrl(String postId) {
  final enc = Uri.encodeComponent(postId);
  var base = AppConfig.shareLinkOrigin;
  if (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  return '$base/post/$enc';
}

Future<void> openFeedPostShareActions(BuildContext context, String postId) {
  return showShareLinkSheet(context, url: feedPostShareUrl(postId));
}
