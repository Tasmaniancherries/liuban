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

  /// 無法連線伺服器時的公開廣場占位。
  static List<FeedPostDto> mockPublicFeed() {
    return List<FeedPostDto>.generate(
      6,
      (int i) => FeedPostDto(
        id: 'local_pub_$i',
        authorId: 'demo',
        authorDisplay: '示例作者',
        body: '訪客與正式用戶皆可瀏覽。無法連線伺服器時顯示本地示例 ${i + 1}。',
        audience: 'public',
      ),
    );
  }

  static List<FeedPostDto> mockSchoolFeed() {
    return List<FeedPostDto>.generate(
      5,
      (int i) => FeedPostDto(
        id: 'local_sch_$i',
        authorId: 'peer',
        authorDisplay: '同校示例',
        body: '僅同校可見之動態占位 ${i + 1}。後端就緒後會替換為真實本校流。',
        audience: 'school',
      ),
    );
  }

  static List<FeedPostDto> mockFriendsFeed() {
    return List<FeedPostDto>.generate(
      4,
      (int i) => FeedPostDto(
        id: 'local_fr_$i',
        authorId: 'friend',
        authorDisplay: '好友示例',
        body: '雙向好友動態占位 ${i + 1}。',
        audience: 'friends',
      ),
    );
  }
}
