import 'package:liuban/data/models/json_utils.dart';

/// 待處理的好友申請（對方想加我）。
class FriendRequestDto {
  const FriendRequestDto({
    required this.id,
    required this.fromCustomId,
    this.createdAt,
  });

  final String id;
  final String fromCustomId;
  final String? createdAt;

  factory FriendRequestDto.fromJson(Map<String, dynamic> json) {
    return FriendRequestDto(
      id: json['id']?.toString() ?? '',
      fromCustomId:
          json['from_custom_id'] as String? ??
          json['requester_custom_id'] as String? ??
          '',
      createdAt: json['created_at'] as String?,
    );
  }

  static List<FriendRequestDto> listFromResponse(dynamic data) =>
      asJsonObjectList(data).map(FriendRequestDto.fromJson).toList();

  static List<FriendRequestDto> mockPending() => const <FriendRequestDto>[
    FriendRequestDto(
      id: 'mock_r1',
      fromCustomId: 'coffee_hk',
      createdAt: '2026-03-28',
    ),
  ];
}
