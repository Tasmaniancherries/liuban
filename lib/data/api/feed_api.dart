import "package:dio/dio.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/data/models/feed_post_dto.dart";
import "package:liuban/data/models/json_utils.dart";

/// 廣場動態（公開／本校／好友、發佈／編輯／檢舉／刪除）。
///
/// 路徑中含動態 `{id}` 之請求使用 [Uri.encodeComponent]；其餘見
/// `docs/backend_domain_apis_contract.md`（含 `audience` 枚舉）。
class FeedApi {
  FeedApi(this._dio, {required this.apiPrefix});

  final Dio _dio;
  final String apiPrefix;

  String _path(String relative) {
    if (relative.startsWith("/")) {
      return "$apiPrefix$relative";
    }
    return "$apiPrefix/$relative";
  }

  Future<List<FeedPostDto>> listPublicFeed({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        _path("/feed/public"),
        queryParameters: <String, dynamic>{"page": page, "page_size": pageSize},
      );
      return FeedPostDto.listFromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 本校可見動態列表；路徑與 Query 見 `docs/backend_domain_apis_contract.md`。
  Future<List<FeedPostDto>> listSchoolFeed({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        _path("/feed/school"),
        queryParameters: <String, dynamic>{"page": page, "page_size": pageSize},
      );
      return FeedPostDto.listFromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<List<FeedPostDto>> listFriendsFeed({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        _path("/feed/friends"),
        queryParameters: <String, dynamic>{"page": page, "page_size": pageSize},
      );
      return FeedPostDto.listFromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 單篇動態；路徑可依後端調整為 `/feed/post/{id}` 等。
  Future<FeedPostDto> getPost(String id) async {
    try {
      final enc = Uri.encodeComponent(id);
      final res = await _dio.get<dynamic>(_path("/feed/posts/$enc"));
      return FeedPostDto.fromJson(asJsonMap(res.data));
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<FeedPostDto> createPost({
    required String body,
    required String audienceApiValue,
    required bool hideSchool,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        _path("/feed/posts"),
        data: <String, dynamic>{
          "body": body,
          "audience": audienceApiValue,
          "hide_school": hideSchool,
        },
      );
      final data = res.data;
      if (data == null || (data is Map && data.isEmpty)) {
        return FeedPostDto(
          id: "local",
          authorId: "",
          authorDisplay: "我",
          body: body,
          audience: audienceApiValue,
          hideSchool: hideSchool,
        );
      }
      return FeedPostDto.fromJson(asJsonMap(data));
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 更新本人動態。預設：`PATCH {apiPrefix}/feed/posts/{id}`，欄位與 [createPost] 一致。
  Future<FeedPostDto> updatePost({
    required String postId,
    required String body,
    required String audienceApiValue,
    required bool hideSchool,
  }) async {
    try {
      final enc = Uri.encodeComponent(postId);
      final res = await _dio.patch<dynamic>(
        _path("/feed/posts/$enc"),
        data: <String, dynamic>{
          "body": body,
          "audience": audienceApiValue,
          "hide_school": hideSchool,
        },
      );
      final data = res.data;
      if (data == null || (data is Map && data.isEmpty)) {
        return FeedPostDto(
          id: postId,
          authorId: "",
          authorDisplay: "",
          body: body,
          audience: audienceApiValue,
          hideSchool: hideSchool,
        );
      }
      return FeedPostDto.fromJson(asJsonMap(data));
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 檢舉動態。預設：`POST {apiPrefix}/feed/posts/{id}/report`，body 可含 `reason`。
  Future<void> reportPost({required String postId, String? reason}) async {
    try {
      final enc = Uri.encodeComponent(postId);
      await _dio.post<dynamic>(
        _path("/feed/posts/$enc/report"),
        data: <String, dynamic>{
          if (reason != null && reason.isNotEmpty) "reason": reason,
        },
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 刪除本人發佈的動態。預設：`DELETE {apiPrefix}/feed/posts/{id}`（可改為 POST …/delete）。
  Future<void> deletePost(String postId) async {
    try {
      final enc = Uri.encodeComponent(postId);
      await _dio.delete<dynamic>(_path("/feed/posts/$enc"));
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }
}
