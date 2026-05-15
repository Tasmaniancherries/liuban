import 'package:liuban/data/models/json_utils.dart';

class FeedPostDto {
  const FeedPostDto({
    required this.id,
    required this.authorId,
    required this.authorDisplay,
    required this.body,
    this.createdAt,
    this.audience,
    this.hideSchool = false,
  });

  final String id;
  final String authorId;
  final String authorDisplay;
  final String body;
  final String? createdAt;
  final String? audience;
  final bool hideSchool;

  factory FeedPostDto.fromJson(Map<String, dynamic> json) {
    return FeedPostDto(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorDisplay:
          json['author_display'] as String? ?? json['author'] as String? ?? '',
      body: json['body'] as String? ?? json['content'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      audience: json['audience'] as String?,
      hideSchool: json['hide_school'] as bool? ?? false,
    );
  }

  static List<FeedPostDto> listFromResponse(dynamic data) =>
      asJsonObjectList(data).map(FeedPostDto.fromJson).toList();

  /// 單元測試用動態列表夾具（不應在正式 UI 中顯示）。
  static List<FeedPostDto> fixturePublicFeed() {
    return List<FeedPostDto>.generate(
      6,
      (int i) => FeedPostDto(
        id: 'fixture_pub_$i',
        authorId: 'fixture_author',
        authorDisplay: '測試夾具作者',
        body: '測試夾具：公開廣場列表第 ${i + 1} 則。',
        audience: 'public',
      ),
    );
  }

  static List<FeedPostDto> fixtureSchoolFeed() {
    return List<FeedPostDto>.generate(
      5,
      (int i) => FeedPostDto(
        id: 'fixture_sch_$i',
        authorId: 'fixture_peer',
        authorDisplay: '測試夾具同校',
        body: '測試夾具：同校動態列表第 ${i + 1} 則。',
        audience: 'school',
      ),
    );
  }

  static List<FeedPostDto> fixtureFriendsFeed() {
    return List<FeedPostDto>.generate(
      4,
      (int i) => FeedPostDto(
        id: 'fixture_fr_$i',
        authorId: 'fixture_friend',
        authorDisplay: '測試夾具好友',
        body: '測試夾具：好友動態列表第 ${i + 1} 則。',
        audience: 'friends',
      ),
    );
  }
}
