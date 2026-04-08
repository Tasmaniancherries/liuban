import "package:liuban/data/models/json_utils.dart";

/// 好友收件匣一格（`GET …/friends/inbox` 等，欄位見 `docs/backend_domain_apis_contract.md`）。
class FriendInboxItemDto {
  const FriendInboxItemDto({
    required this.peerId,
    required this.peerCustomId,
    this.lastMessagePreview,
    this.updatedAt,
  });

  final String peerId;
  final String peerCustomId;
  final String? lastMessagePreview;
  final String? updatedAt;

  factory FriendInboxItemDto.fromJson(Map<String, dynamic> json) {
    return FriendInboxItemDto(
      peerId: json["peer_id"]?.toString() ?? json["user_id"]?.toString() ?? "",
      peerCustomId:
          json["peer_custom_id"] as String? ??
          json["custom_id"] as String? ??
          json["username"] as String? ??
          "",
      lastMessagePreview:
          json["last_message"] as String? ?? json["preview"] as String?,
      updatedAt: json["updated_at"] as String?,
    );
  }

  static List<FriendInboxItemDto> listFromResponse(dynamic data) =>
      asJsonObjectList(data).map(FriendInboxItemDto.fromJson).toList();

  static List<FriendInboxItemDto> mockInbox() => const <FriendInboxItemDto>[
    FriendInboxItemDto(
      peerId: "mock_1",
      peerCustomId: "river_2026",
      lastMessagePreview: "晚安！週末要不要一起爬山？",
    ),
    FriendInboxItemDto(
      peerId: "mock_2",
      peerCustomId: "hk_reading_club",
      lastMessagePreview: "社團群公告已更新",
    ),
  ];
}
