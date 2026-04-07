import "package:liuban/data/models/education_entry_dto.dart";
import "package:liuban/data/models/json_utils.dart";

/// `GET …/auth/me` 當前用戶公開資料。
///
/// JSON 欄位與別名見 `docs/backend_auth_contract.md`「GET …/auth/me」。
class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.customId,
    this.displayName,
    this.educations = const <EducationEntryDto>[],
  });

  final String userId;
  final String customId;
  final String? displayName;
  final List<EducationEntryDto> educations;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    final eduRaw = json["educations"] ?? json["schools"] ?? json["degrees"];
    return UserProfileDto(
      userId: json["id"]?.toString() ?? json["user_id"]?.toString() ?? "",
      customId: json["custom_id"] as String? ??
          json["username"] as String? ??
          json["login"] as String? ??
          "",
      displayName:
          json["display_name"] as String? ?? json["nickname"] as String?,
      educations:
          eduRaw != null ? EducationEntryDto.listFromJson(eduRaw) : const [],
    );
  }

  factory UserProfileDto.fromResponse(dynamic data) =>
      UserProfileDto.fromJson(asJsonMap(data));

  static UserProfileDto previewFallback() => const UserProfileDto(
        userId: "local",
        customId: "demo_id",
        educations: <EducationEntryDto>[
          EducationEntryDto(schoolShortName: "港大", alumni: true),
          EducationEntryDto(schoolShortName: "中大", alumni: false),
        ],
      );
}
