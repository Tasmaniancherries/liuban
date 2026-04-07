import "package:dio/dio.dart";
import "package:liuban/core/network/api_exception.dart";
import "package:liuban/data/models/json_utils.dart";
import "package:liuban/data/models/promotion_dto.dart";

/// 推廣：合作方內容由平台審核後發佈，與廣場用戶動態分流。
///
/// 契約見 `docs/backend_domain_apis_contract.md`；單篇 `{id}` 路徑使用 [Uri.encodeComponent]。
class PromotionApi {
  PromotionApi(this._dio, {required this.apiPrefix});

  final Dio _dio;
  final String apiPrefix;

  String _path(String relative) {
    if (relative.startsWith("/")) {
      return "$apiPrefix$relative";
    }
    return "$apiPrefix/$relative";
  }

  /// 已上線的推廣條目列表。
  Future<List<PromotionDto>> listPromotions() async {
    try {
      final res = await _dio.get<dynamic>(_path("/promotions"));
      return PromotionDto.listFromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 單篇推廣內容詳情；[id] 以 [Uri.encodeComponent] 置於路徑中。
  Future<PromotionDto> getPromotion(String id) async {
    try {
      final enc = Uri.encodeComponent(id);
      final res = await _dio.get<dynamic>(_path("/promotions/$enc"));
      return PromotionDto.fromJson(asJsonMap(res.data));
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }
}
