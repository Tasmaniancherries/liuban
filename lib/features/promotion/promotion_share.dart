import "package:flutter/material.dart";
import "package:liuban/core/config/app_config.dart";
import "package:liuban/core/share/share_link_sheet.dart";

/// 推廣詳情分享／複製用 URL（`SHARE_LINK_ORIGIN` 與動態帖一致）。
String promotionShareUrl(String promotionId) {
  final enc = Uri.encodeComponent(promotionId);
  var base = AppConfig.shareLinkOrigin;
  if (base.endsWith("/")) {
    base = base.substring(0, base.length - 1);
  }
  return "$base/promotion/$enc";
}

Future<void> openPromotionShareActions(
    BuildContext context, String promotionId) {
  return showShareLinkSheet(context, url: promotionShareUrl(promotionId));
}
