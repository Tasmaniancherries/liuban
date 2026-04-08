/// 動態可見範圍（對齊 PRD：公開廣場／本校／好友／僅自己）
enum PostAudience {
  /// 公開廣場：訪客可瀏覽
  publicSquare,

  /// 本校：僅同校已認證用戶；若勾選「隱藏學校」則不可選
  schoolPeers,

  /// 雙向好友可見
  friendsOnly,

  /// 僅自己
  selfOnly,
}

/// 由後端 [FeedPostDto.audience] 還原；未知值時回傳 `null`。
PostAudience? postAudienceFromApiValue(String? v) {
  if (v == null || v.isEmpty) return null;
  return switch (v) {
    "public" => PostAudience.publicSquare,
    "school" => PostAudience.schoolPeers,
    "friends" => PostAudience.friendsOnly,
    "private" => PostAudience.selfOnly,
    _ => null,
  };
}

extension PostAudienceLabel on PostAudience {
  String get shortLabel => switch (this) {
    PostAudience.publicSquare => "公開",
    PostAudience.schoolPeers => "本校",
    PostAudience.friendsOnly => "好友",
    PostAudience.selfOnly => "僅自己",
  };

  /// 與後端 `audience` 欄位對齊（契約：`docs/backend_domain_apis_contract.md`「audience 枚舉」）。
  String get apiValue => switch (this) {
    PostAudience.publicSquare => "public",
    PostAudience.schoolPeers => "school",
    PostAudience.friendsOnly => "friends",
    PostAudience.selfOnly => "private",
  };
}
