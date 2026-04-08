import "package:liuban/data/models/json_utils.dart";

/// 與單一好友的私聊訊息（HTTP 拉取；之後可換 WebSocket）。
class DmMessageDto {
  const DmMessageDto({
    required this.id,
    required this.body,
    required this.isMine,
    this.createdAt,
  });

  final String id;
  final String body;
  final bool isMine;
  final String? createdAt;

  factory DmMessageDto.fromJson(Map<String, dynamic> json) {
    return DmMessageDto(
      id: json["id"]?.toString() ?? "",
      body:
          json["body"] as String? ??
          json["text"] as String? ??
          json["content"] as String? ??
          "",
      isMine: json["is_mine"] as bool? ?? json["mine"] as bool? ?? false,
      createdAt: json["created_at"] as String?,
    );
  }

  static List<DmMessageDto> listFromResponse(dynamic data) =>
      asJsonObjectList(data).map(DmMessageDto.fromJson).toList();

  static List<DmMessageDto> mockThread() => const <DmMessageDto>[
    DmMessageDto(
      id: "m1",
      body: "嗨！下週有沒有空？",
      isMine: false,
      createdAt: "10:02",
    ),
    DmMessageDto(id: "m2", body: "可以呀，週六下午？", isMine: true, createdAt: "10:05"),
  ];
}
