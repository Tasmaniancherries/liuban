import "package:liuban/data/models/json_utils.dart";

class PromotionDto {
  const PromotionDto({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.publishedAt,
    required this.body,
  });

  final String id;
  final String title;
  final String subtitle;
  final String publishedAt;
  final String body;

  factory PromotionDto.fromJson(Map<String, dynamic> json) {
    return PromotionDto(
      id: json["id"]?.toString() ?? "",
      title: json["title"] as String? ?? "",
      subtitle: json["subtitle"] as String? ?? json["source"] as String? ?? "",
      publishedAt:
          json["published_at"] as String? ?? json["date"] as String? ?? "",
      body: json["body"] as String? ?? json["content"] as String? ?? "",
    );
  }

  static List<PromotionDto> listFromResponse(dynamic data) =>
      asJsonObjectList(data).map(PromotionDto.fromJson).toList();
}
