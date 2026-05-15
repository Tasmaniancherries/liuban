import 'package:liuban/data/models/json_utils.dart';

class BlockedUserDto {
  const BlockedUserDto({required this.userId, this.displayLabel});

  final String userId;

  /// 例如 @custom_id 或暱稱，依後端。
  final String? displayLabel;

  factory BlockedUserDto.fromJson(Map<String, dynamic> json) {
    return BlockedUserDto(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      displayLabel:
          json['custom_id']?.toString() ??
          json['display']?.toString() ??
          json['label']?.toString(),
    );
  }

  static List<BlockedUserDto> listFromResponse(dynamic data) =>
      asJsonObjectList(data).map(BlockedUserDto.fromJson).toList();

  /// 單元測試用夾具。
  static List<BlockedUserDto> fixtureList() => const <BlockedUserDto>[
    BlockedUserDto(userId: 'fixture_blocked_1', displayLabel: '@river_2026'),
  ];
}
