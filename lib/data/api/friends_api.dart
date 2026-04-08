import 'package:dio/dio.dart';
import 'package:liuban/core/network/api_exception.dart';
import 'package:liuban/data/models/blocked_user_dto.dart';
import 'package:liuban/data/models/dm_message_dto.dart';
import 'package:liuban/data/models/friend_inbox_item_dto.dart';
import 'package:liuban/data/models/friend_outgoing_request_dto.dart';
import 'package:liuban/data/models/friend_request_dto.dart';

/// 雙向好友與私訊（JSON REST，與全站一致）。
///
/// 完整契約見 `docs/backend_domain_apis_contract.md`（含路徑參數 [Uri.encodeComponent] 約定）。
/// 摘要：
///
/// - 收件匣 [listInbox]：`GET {apiPrefix}/friends/inbox` → 陣列或 `{ items: [] }`
/// - 申請 [sendFriendRequest]：`POST {apiPrefix}/friends/requests`，body：`{"target_custom_id"}`
/// - 待我處理 [listIncomingRequests]：`GET {apiPrefix}/friends/requests/incoming`
/// - 回覆 [respondToFriendRequest]：`POST {apiPrefix}/friends/requests/{id}/respond` body：`{"accept": true|false}`
/// - 我發出的申請 [listOutgoingRequests]：`GET {apiPrefix}/friends/requests/outgoing`
/// - 私聊 [listDmMessages] / [sendDmMessage]：`GET|POST {apiPrefix}/friends/dm/{peerId}/messages`
/// - 屏蔽用戶 [blockUser]：`POST {apiPrefix}/friends/blocks`，body：`user_id`
/// - 已屏蔽列表 [listBlockedUsers]：`GET {apiPrefix}/friends/blocks`
/// - 解除屏蔽 [unblockUser]：`POST {apiPrefix}/friends/blocks/remove`，body：`user_id`
class FriendsApi {
  FriendsApi(this._dio, {required this.apiPrefix});

  final Dio _dio;
  final String apiPrefix;

  String _path(String relative) {
    if (relative.startsWith('/')) {
      return '$apiPrefix$relative';
    }
    return '$apiPrefix/$relative';
  }

  /// 與好友的最後預覽列表（或會話列表）。
  Future<List<FriendInboxItemDto>> listInbox() async {
    try {
      final res = await _dio.get<dynamic>(_path('/friends/inbox'));
      return FriendInboxItemDto.listFromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 向對方自訂 ID 發出好友申請（對方通過後成為雙向好友）。
  Future<void> sendFriendRequest({required String targetCustomId}) async {
    try {
      await _dio.post<dynamic>(
        _path('/friends/requests'),
        data: <String, dynamic>{'target_custom_id': targetCustomId},
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<List<FriendRequestDto>> listIncomingRequests() async {
    try {
      final res = await _dio.get<dynamic>(_path('/friends/requests/incoming'));
      return FriendRequestDto.listFromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// [requestId] 會以 [Uri.encodeComponent] 置於路徑中。
  Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    try {
      final enc = Uri.encodeComponent(requestId);
      await _dio.post<dynamic>(
        _path('/friends/requests/$enc/respond'),
        data: <String, dynamic>{'accept': accept},
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<List<FriendOutgoingRequestDto>> listOutgoingRequests() async {
    try {
      final res = await _dio.get<dynamic>(_path('/friends/requests/outgoing'));
      return FriendOutgoingRequestDto.listFromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  String _dmMessagesPath(String peerId) =>
      _path('/friends/dm/${Uri.encodeComponent(peerId)}/messages');

  Future<List<DmMessageDto>> listDmMessages({required String peerId}) async {
    try {
      final res = await _dio.get<dynamic>(_dmMessagesPath(peerId));
      return DmMessageDto.listFromResponse(res.data);
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<void> sendDmMessage({
    required String peerId,
    required String text,
  }) async {
    try {
      await _dio.post<dynamic>(
        _dmMessagesPath(peerId),
        data: <String, dynamic>{'text': text},
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  /// 不再看到該用戶之公開／廣場內容（與好友／私聊分流依後端）。
  Future<void> blockUser({required String userId}) async {
    try {
      await _dio.post<dynamic>(
        _path('/friends/blocks'),
        data: <String, dynamic>{'user_id': userId},
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<List<BlockedUserDto>> listBlockedUsers() async {
    try {
      final res = await _dio.get<dynamic>(_path('/friends/blocks'));
      try {
        return BlockedUserDto.listFromResponse(res.data);
      } on FormatException {
        return <BlockedUserDto>[];
      }
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }

  Future<void> unblockUser({required String userId}) async {
    try {
      await _dio.post<dynamic>(
        _path('/friends/blocks/remove'),
        data: <String, dynamic>{'user_id': userId},
      );
    } on DioException catch (e) {
      throw LiubanApiException.fromDio(e);
    }
  }
}
