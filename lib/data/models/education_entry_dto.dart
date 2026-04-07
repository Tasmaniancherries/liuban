import "package:liuban/data/models/json_utils.dart";

/// 學籍列單筆；併入 [UserProfileDto] 之 `educations` / `schools` / `degrees`。
///
/// 欄位見 `docs/backend_auth_contract.md`「educations[] 元素」。
class EducationEntryDto {
  const EducationEntryDto({
    required this.schoolShortName,
    required this.alumni,
  });

  final String schoolShortName;
  final bool alumni;

  String get chipLabel =>
      alumni ? "$schoolShortName 校友" : "$schoolShortName 在讀";

  factory EducationEntryDto.fromJson(Map<String, dynamic> json) {
    final short = json["school_short_name"] as String? ??
        json["school"] as String? ??
        json["name"] as String? ??
        "";
    final alumni = json["alumni"] as bool? ??
        json["is_alumni"] as bool? ??
        (json["status"] == "alumni" || json["status"] == "graduated");
    return EducationEntryDto(schoolShortName: short, alumni: alumni);
  }

  static List<EducationEntryDto> listFromJson(dynamic data) {
    if (data is! List) return <EducationEntryDto>[];
    return data.map((e) => EducationEntryDto.fromJson(asJsonMap(e))).toList();
  }
}
