import 'package:liuban/data/models/json_utils.dart';

/// 我發出的好友申請。
class FriendOutgoingRequestDto {
  const FriendOutgoingRequestDto({
    required this.id,
    required this.toCustomId,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String toCustomId;

  /// 例如：pending / accepted / rejected
  final String status;
  final String? createdAt;

  factory FriendOutgoingRequestDto.fromJson(Map<String, dynamic> json) {
    return FriendOutgoingRequestDto(
      id: json['id']?.toString() ?? '',
      toCustomId:
          json['to_custom_id'] as String? ??
          json['target_custom_id'] as String? ??
          '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String?,
    );
  }

  static List<FriendOutgoingRequestDto> listFromResponse(dynamic data) =>
      asJsonObjectList(data).map(FriendOutgoingRequestDto.fromJson).toList();

  static List<FriendOutgoingRequestDto> mockOutgoing() =>
      const <FriendOutgoingRequestDto>[
        FriendOutgoingRequestDto(
          id: 'mock_o1',
          toCustomId: 'library_fan',
          status: 'pending',
          createdAt: '2026-03-27',
        ),
      ];
}
