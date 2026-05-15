import 'package:liuban/core/config/app_config.dart';

/// 功能與無障礙說明用文案：實際請求為 **主機** + [AppConfig.apiPrefix] + 下列相對路徑
///（`dart define API_PREFIX` 可覆寫預設 `/v1`）。
abstract final class ApiDevSemantics {
  ApiDevSemantics._();

  /// 可接在自訂 API 說明後（與 [_p] 使用同一段落）。
  static const String docsTrail =
      '詳專案 docs 後端契約：README、backend_auth_contract、backend_domain_apis_contract。';

  static String _p(String sentence) => '$sentence $docsTrail';

  static String get feedPublicList =>
      _p('優先載入 GET ${AppConfig.apiPrefix}/feed/public。可載入更多、下拉刷新；發佈成功後可刷新。');

  static String get feedSchoolList =>
      _p('優先載入 GET ${AppConfig.apiPrefix}/feed/school；僅已認證同校。可載入更多。');

  static String get feedFriendsList =>
      _p('優先載入 GET ${AppConfig.apiPrefix}/feed/friends；雙向好友。可載入更多。');

  /// [FeedScreen] 分頁載入下一頁失敗時之 SnackBar 本文。
  static const String feedLoadMoreFailedMessage = '載入更多失敗，請稍後再試';

  /// 同上之無障礙 hint（列表端點見 [feedPublicList] 等）。
  static String get feedLoadMoreFailedSnackHint =>
      _p('載入更多為同一動態列表 GET 之分頁請求失敗；已顯示內容保留。可下拉重新整理自第一頁重試。');

  /// [_FeedStreamTab] 第一頁列表 GET 失敗且後端回傳業務訊息時（本體為 [LiubanApiException.message]）；端點見 [feedPublicList] 等。
  static String get feedInitialLoadApiErrorSnackHint => _p(
    '載入動態列表失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/feed/public、…/school 或 …/friends（第一頁）。',
  );

  /// [_FeedStreamTab] 第一頁 GET 發生非 API 例外時之 SnackBar 本文。
  static const String feedInitialLoadFailedMessage = '載入動態失敗，請稍後再試';

  /// 同上之無障礙 hint；列表維持空狀態並可下拉重試。
  static String get feedInitialLoadFailedSnackHint =>
      _p('載入第一頁失敗，已維持空列表；可下拉重新整理重試同一 feed 端點。');

  /// [_FeedStreamTab] 載入更多同一列表失敗且後端回傳業務訊息時（本體為 [LiubanApiException.message]）。
  static String get feedLoadMoreApiErrorSnackHint =>
      _p('載入下一頁失敗，訊息由後端回傳。與第一頁相同之 feed 列表 GET，帶分頁參數。');

  /// 動態分頁右下角「發佈」FAB（開啟撰寫頁；實際送出見 [composePostSubmitHint]）。
  static String get feedComposeFabHint => _p(
    '開啟撰寫動態頁；完成時 POST ${AppConfig.apiPrefix}/feed/posts（編輯時 PATCH 同路徑已編碼 ID）。',
  );

  /// [PhaseBadge] 帳戶階段標籤之無障礙補充（非按鈕）。
  static String get phaseBadgeDevNote => _p(
    '階段反映伺服器與本機 session：GET ${AppConfig.apiPrefix}/auth/me、GET ${AppConfig.apiPrefix}/auth/me/verification。',
  );

  /// [MainShell] 底部導覽列整體補充；逐格仍為短標籤，詳細 API 在各分頁。
  static String get mainShellBottomNavHint => _p(
    '底欄切換四個分頁：廣場、推廣、訊息、我的；資料載入與 REST 路徑說明見各該頁面。前綴：${AppConfig.apiPrefix}。',
  );

  /// 登入、註冊、重設密碼、加好友等「捨棄輸入」確認對話框。
  static String get discardUnsavedLocalFormDialogHint =>
      _p('僅捨棄此頁尚未按主要送出鈕的內容，不會因此呼叫對應 REST（例如登入／註冊／重設／加好友等）。');

  /// [ComposePostScreen] 捨棄草稿或捨棄編輯確認對話框。
  static String get discardComposeUnpublishedHint => _p(
    '捨棄將關閉撰寫頁且不發佈。送出動態見完成鈕：POST ${AppConfig.apiPrefix}/feed/posts；編輯則 PATCH 同路徑已編碼 ID。',
  );

  /// [DmChatScreen]、[SupportChatScreen] 輸入框尚有內容時離開。
  static String get discardUnsentMessageDraftHint => _p(
    '僅捨棄尚未按下送出的輸入框草稿，不會因此多送一則 POST。私訊端點：${AppConfig.apiPrefix}/friends/dm/對方 ID 經編碼後/messages；客服：${AppConfig.apiPrefix}/support/messages。',
  );

  static String get friendsInbox =>
      _p('優先載入 GET ${AppConfig.apiPrefix}/friends/inbox。');

  /// [_FriendsInbox] GET 發生非 API 例外時之 SnackBar 本文。
  static const String friendsInboxLoadFailedMessage = '無法載入好友收件匣，請稍後再試';

  /// 同上之無障礙 hint；列表維持空狀態，可下拉重試。
  static String get friendsInboxLoadFailedSnackHint =>
      _p('GET ${AppConfig.apiPrefix}/friends/inbox 失敗，列表維持空狀態。可下拉重新整理重試。');

  /// [_FriendsInbox] GET 失敗且後端回傳業務訊息時（本體為 [LiubanApiException.message]）。
  static String get friendsInboxGetApiErrorSnackHint =>
      _p('載入收件匣失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/friends/inbox。');

  static String get dmThread => _p(
    '私訊：GET 與 POST ${AppConfig.apiPrefix}/friends/dm/對方 ID 經編碼後/messages。',
  );

  /// [DmChatScreen] 送出訊息 [LiubanApiException]。
  static String get dmSendMessageApiErrorSnackHint => _p(
    '送出私訊失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/friends/dm/對方 ID 經編碼後/messages。',
  );

  /// [DmChatScreen] 送出時非業務例外（網路等）之 SnackBar 本文。
  static const String dmSendMessageGenericFailureMessage = '無法送出訊息，請稍後再試';

  static String get dmSendMessageGenericFailureSnackHint => _p(
    '預期 POST ${AppConfig.apiPrefix}/friends/dm/對方 ID 經編碼後/messages；非業務錯誤或網路失敗。可稍後重試。',
  );

  /// 一般表單欄位超過上限時之 SnackBar 本文（[fieldLabel] 可含尾隨空格以調整排版）。
  static String inputTooLongMessage(String fieldLabel, int maxLength) =>
      '$fieldLabel長度不可超過 $maxLength 字元';

  /// 客戶端長度防禦觸發、且畫面未提供專用 hint 時之通用無障礙說明。
  static String get clientValidationTooLongSnackHint =>
      _p('輸入未送出；內容長度超出 App 客戶端上限，請縮短後重試。');

  /// 私訊／客服單則文字超過上限時之 SnackBar 本文。
  static String chatMessageTooLongMessage(int maxLength) =>
      '訊息過長，請控制在 $maxLength 字以內';

  /// [DmChatScreen] 私訊文字超長（客戶端防禦）SnackBar 無障礙 hint。
  static String dmChatMessageTooLongSnackHint(int maxLength) => _p(
    '私訊未送出；text 須不超過 $maxLength 字（POST ${AppConfig.apiPrefix}/friends/dm/對方 ID 經編碼後/messages）。',
  );

  /// [DmChatScreen] 載入對話 GET 失敗時之 SnackBar 本文。
  static const String dmThreadLoadFailedMessage = '無法載入對話，請稍後再試';

  /// 同上之無障礙 hint。
  static String get dmThreadLoadFailedSnackHint => _p(
    'GET ${AppConfig.apiPrefix}/friends/dm/對方 ID 經編碼後/messages 失敗，畫面維持空狀態。可下拉重新整理。',
  );

  /// [DmChatScreen] 載入私訊 GET 失敗且後端回傳業務訊息時（本體為 [LiubanApiException.message]）。
  static String get dmThreadGetApiErrorSnackHint => _p(
    '載入對話失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/friends/dm/對方 ID 經編碼後/messages。',
  );

  static String get promotionsList =>
      _p('優先載入 GET ${AppConfig.apiPrefix}/promotions。');

  /// 推廣列表頁頂部說明（含 API 與 docs 尾註）。
  static String get promotionListBanner =>
      '合作方提供素材，經審核後由留伴平台代為發佈（與廣場用戶帖分流）。'
      '優先載入 GET ${AppConfig.apiPrefix}/promotions。'
      '長按列表項可分享或複製該則推廣連結。 $docsTrail';

  /// [PromotionListScreen] GET 失敗時之 SnackBar 本文。
  static const String promotionListLoadFailedMessage = '無法載入推廣列表，請稍後再試';

  /// 同上之無障礙 hint。
  static String get promotionListLoadFailedSnackHint =>
      _p('GET ${AppConfig.apiPrefix}/promotions 失敗，列表維持空狀態。可下拉重新整理重試。');

  /// [PromotionListScreen] GET 列表失敗且後端回傳業務訊息時（本體為 [LiubanApiException.message]）。
  static String get promotionListGetApiErrorSnackHint =>
      _p('載入推廣列表失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/promotions。');

  static String get passwordResetComplete => _p(
    'POST ${AppConfig.apiPrefix}/auth/password/reset/complete，body：token、new_password。郵件或 App 連結應帶 token。',
  );

  /// [ResetPasswordConfirmScreen] 未貼入 token。
  static String get resetPasswordTokenMissingSnackHint => _p(
    '重設連結須帶 token；尚未呼叫 POST ${AppConfig.apiPrefix}/auth/password/reset/complete。',
  );

  /// [ResetPasswordConfirmScreen] token 過長。
  static String resetPasswordTokenTooLongSnackHint(int maxLength) => _p(
    '重設憑證最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/password/reset/complete。',
  );

  /// [ResetPasswordConfirmScreen] 新密碼過短。
  static String get resetPasswordTooShortSnackHint =>
      _p('新密碼長度須符合後端策略（至少 8 字）；尚未送出 complete。');

  /// [ResetPasswordConfirmScreen] 新密碼過長。
  static String resetPasswordPasswordTooLongSnackHint(int maxLength) => _p(
    '新密碼最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/password/reset/complete。',
  );

  /// [ResetPasswordConfirmScreen] 兩次密碼不一致。
  static String get resetPasswordMismatchSnackHint => _p(
    '兩次輸入須一致；尚未呼叫 POST ${AppConfig.apiPrefix}/auth/password/reset/complete。',
  );

  /// [ResetPasswordConfirmScreen] 重設成功 SnackBar。
  static String get resetPasswordSuccessSnackHint => _p(
    '密碼已重設成功。POST ${AppConfig.apiPrefix}/auth/password/reset/complete（token、new_password）。',
  );

  /// [ResetPasswordConfirmScreen] [LiubanApiException]。
  static String get resetPasswordApiErrorSnackHint => _p(
    '重設密碼失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/auth/password/reset/complete。',
  );

  static String get friendsBlocks => _p(
    '已屏蔽：GET ${AppConfig.apiPrefix}/friends/blocks；解除：POST ${AppConfig.apiPrefix}/friends/blocks/remove。',
  );

  /// [BlockedUsersScreen] GET 非 API 例外時之 SnackBar 本文。
  static const String blockedUsersListLoadFailedMessage = '無法載入屏蔽列表，請稍後再試';

  /// 同上之無障礙 hint；列表維持空狀態，可下拉重試。
  static String get blockedUsersListLoadFailedSnackHint =>
      _p('GET ${AppConfig.apiPrefix}/friends/blocks 失敗，列表維持空狀態。可下拉重新整理重試。');

  /// [BlockedUsersScreen] GET 失敗且後端回傳業務訊息時（本體為 [LiubanApiException.message]）。
  static String get blockedUsersListGetApiErrorSnackHint =>
      _p('載入屏蔽列表失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/friends/blocks。');

  static String get profileMeGet =>
      _p('GET ${AppConfig.apiPrefix}/auth/me 向伺服器取得個人檔。');

  /// [ProfileScreen] `GET …/auth/me` 非 API 例外時之 SnackBar 本文。
  static const String profileMeLoadFailedMessage = '無法載入個人檔，請稍後再試';

  static String get profileMeLoadFailedSnackHint =>
      _p('GET ${AppConfig.apiPrefix}/auth/me 失敗；畫面維持未載入狀態。可下拉重新整理。');

  /// `GET …/auth/me`（[fetchMe]）失敗且後端回傳業務訊息時之 SnackBar hint（本體為 [LiubanApiException.message]）。
  /// [ProfileScreen]、[_FeedStreamTab]、[FeedPostDetailScreen] 共用。
  static String get authMeLoadApiErrorSnackHint =>
      _p('取得目前帳號失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/auth/me。');

  static String get authChangePassword => _p(
    'POST ${AppConfig.apiPrefix}/auth/password，body：current_password、new_password。',
  );

  /// [ChangePasswordScreen] 欄位未齊。
  static String get changePasswordIncompleteSnackHint =>
      _p('請填齊目前密碼與新密碼；尚未 POST ${AppConfig.apiPrefix}/auth/password。');

  /// [ChangePasswordScreen] 新密碼過短。
  static String get changePasswordTooShortSnackHint =>
      _p('新密碼長度須符合後端策略；尚未送出 POST ${AppConfig.apiPrefix}/auth/password。');

  /// [ChangePasswordScreen] 密碼欄位過長。
  static String changePasswordTooLongSnackHint(int maxLength) => _p(
    '密碼最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/password。',
  );

  /// [ChangePasswordScreen] 兩次新密碼不一致。
  static String get changePasswordMismatchSnackHint =>
      _p('兩次新密碼須一致；尚未呼叫 POST ${AppConfig.apiPrefix}/auth/password。');

  /// [ChangePasswordScreen] 變更成功 SnackBar。
  static String get changePasswordSuccessSnackHint => _p(
    '密碼已更新。POST ${AppConfig.apiPrefix}/auth/password（current_password、new_password）。',
  );

  /// [ChangePasswordScreen] [LiubanApiException]。
  static String get changePasswordApiErrorSnackHint =>
      _p('變更密碼失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/auth/password。');

  static String get friendRequestsIncoming =>
      _p('優先載入 GET ${AppConfig.apiPrefix}/friends/requests/incoming。');

  static String get friendRequestsOutgoing =>
      _p('優先載入 GET ${AppConfig.apiPrefix}/friends/requests/outgoing。');

  static String get passwordResetRequest =>
      _p('POST ${AppConfig.apiPrefix}/auth/password/reset/request，body：email。');

  /// 忘記密碼頁說明首段（與 [passwordResetRequest] 併用）。
  static String get forgotPasswordIntro => '輸入註冊時使用的學校郵箱（或已綁定之信箱）。我們會寄出重設連結。';

  /// [ForgotPasswordScreen] 信箱格式無效（未 POST）。
  static String get forgotPasswordInvalidEmailSnackHint => _p(
    '請輸入有效信箱格式；尚未 POST ${AppConfig.apiPrefix}/auth/password/reset/request。',
  );

  /// [ForgotPasswordScreen] 信箱過長。
  static String forgotPasswordEmailTooLongSnackHint(int maxLength) => _p(
    '信箱最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/password/reset/request。',
  );

  /// [ForgotPasswordScreen] [LiubanApiException]。
  static String get forgotPasswordApiErrorSnackHint => _p(
    '寄送重設信失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/auth/password/reset/request，body：email。',
  );

  static String get supportMessages =>
      _p('POST ${AppConfig.apiPrefix}/support/messages；訪客可直接留言給官方客服。');

  /// [SupportChatScreen] 送出留言 [LiubanApiException]。
  static String get supportSendMessageApiErrorSnackHint =>
      _p('送出客服留言失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/support/messages。');

  /// [SupportChatScreen] 送出時非業務例外（網路等）之 SnackBar 本文。
  static const String supportSendMessageGenericFailureMessage = '無法送出留言，請稍後再試';

  static String get supportSendMessageGenericFailureSnackHint => _p(
    '預期 POST ${AppConfig.apiPrefix}/support/messages；非業務錯誤或網路失敗時顯示此提示。可稍後重試。',
  );

  /// [SupportChatScreen] 客服留言超長（客戶端防禦）SnackBar 無障礙 hint。
  static String supportChatMessageTooLongSnackHint(int maxLength) => _p(
    '客服留言未送出；text 須不超過 $maxLength 字（POST ${AppConfig.apiPrefix}/support/messages）。',
  );

  static String friendRequestSubmitHint({required bool submitting}) {
    if (submitting) return '處理中';
    return '向對方送出好友邀請。POST ${AppConfig.apiPrefix}/friends/requests，body：target_custom_id。 $docsTrail';
  }

  /// [AddFriendScreen] 未輸入 ID。
  static String get addFriendIdEmptySnackHint =>
      _p('請輸入對方自訂 ID；尚未 POST ${AppConfig.apiPrefix}/friends/requests。');

  /// [AddFriendScreen] 對方自訂 ID 過長。
  static String addFriendIdTooLongSnackHint(int maxLength) => _p(
    '目標自訂 ID 最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/friends/requests。',
  );

  /// [AddFriendScreen] 邀請已送出。
  static String get addFriendRequestSentSnackHint => _p(
    '好友邀請已送出。POST ${AppConfig.apiPrefix}/friends/requests，body：target_custom_id。',
  );

  /// [AddFriendScreen] [LiubanApiException]。
  static String get addFriendApiErrorSnackHint =>
      _p('送出好友申請失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/friends/requests。');

  /// [FriendRequestsScreen] 接受或拒絕成功。
  static String get friendRequestRespondSuccessSnackHint => _p(
    '已回覆申請。POST ${AppConfig.apiPrefix}/friends/requests/申請 ID 已編碼/respond，body：accept。',
  );

  /// [FriendRequestsScreen] 回覆 [LiubanApiException]。
  static String get friendRequestRespondApiErrorSnackHint => _p(
    '回覆失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/friends/requests/{id}/respond。',
  );

  /// 加好友、回覆申請、解除屏蔽等 friends 寫入非 [LiubanApiException]。
  static const String friendsWriteGenericFailureMessage = '無法完成操作，請稍後再試';

  static String get friendsWriteGenericFailureSnackHint => _p(
    '預期為 POST ${AppConfig.apiPrefix}/friends/requests、.../respond、blocks、blocks/remove 等；非業務訊息時可能為網路或其他例外。',
  );

  /// [FriendRequestsScreen] incoming 或 outgoing GET 發生非 API 例外時之 SnackBar。
  static const String friendRequestsListsLoadFailedMessage = '無法載入好友申請，請稍後再試';

  static String get friendRequestsListsLoadFailedSnackHint => _p(
    'GET ${AppConfig.apiPrefix}/friends/requests/incoming 或 .../outgoing 失敗時，列表維持空狀態。可下拉重新整理。',
  );

  /// [FriendRequestsScreen] 收到或發出列表 GET 失敗且後端回傳業務訊息時（本體為 [LiubanApiException.message]）。
  static String get friendRequestsListsGetApiErrorSnackHint => _p(
    '載入好友申請失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/friends/requests/incoming 或 .../outgoing。',
  );

  /// [FeedPostDetailScreen] 已登入但無法取得帳號 user id（`GET …/auth/me`）時之 SnackBar 本文（非 [LiubanApiException] 或節流後仍用之簡短提示）。
  static const String feedPostDetailFetchMeFailedMessage =
      '無法確認目前帳號，部分操作選單可能不完整';

  /// [_FeedStreamTab] 已登入但 fetchMe 失敗時之 SnackBar 本文（同上，列表用文案）。
  static const String feedStreamFetchMeFailedMessage = '無法確認目前帳號，本人貼文操作可能未顯示';

  /// 廣場列表／動態詳情於 [fetchMe] 失敗且非後端業務訊息（例如網路）時之 SnackBar 無障礙 hint；與 [authMeLoadApiErrorSnackHint] 成對使用。
  static String get authMeFetchGenericFailureSnackHint => _p(
    'GET ${AppConfig.apiPrefix}/auth/me 失敗（非後端業務訊息時可能為網路等）。廣場列表需用以比對 author_id 以顯示本人編輯／刪除；動態詳情影響是否為本人貼文之選單。可重新整理重試。',
  );

  /// 發佈／編輯頁右上角動作之無障礙 hint。
  static String composePostSubmitHint({
    required bool editing,
    required bool submitting,
  }) {
    if (submitting) return '處理中';
    if (editing) {
      return '儲存目前編輯。API：PATCH ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼，body：body、audience、hide_school。 $docsTrail';
    }
    return '發佈至所選可見範圍。API：POST ${AppConfig.apiPrefix}/feed/posts，body：body、audience、hide_school。 $docsTrail';
  }

  /// [ComposePostScreen] 送出前驗證：正文不可為空。
  static const String composePostBodyEmptyMessage = '請輸入內容';

  /// 同上 SnackBar 之無障礙 hint（尚未呼叫 POST／PATCH）。
  static String get composePostBodyEmptySnackHint =>
      _p('送出須有動態正文；請求 body 含文字欄位。發佈或更新說明見右上角完成按鈕之無障礙提示。');

  /// [ComposePostScreen] 送出前驗證：正文過長。
  static String composePostBodyTooLongMessage(int maxLength) =>
      '內容過長，請控制在 $maxLength 字以內';

  /// 同上 SnackBar 之無障礙 hint（尚未呼叫 POST／PATCH）。
  static String composePostBodyTooLongSnackHint(int maxLength) =>
      _p('送出前會檢查正文長度上限（$maxLength 字）。超出時不會呼叫發佈或更新 API，請先精簡內容。');

  /// [ComposePostScreen] `hide_school` 與本校可見互斥。
  static const String composePostAudienceSchoolConflictMessage = '隱藏學校時不可選「本校」';

  /// 同上 SnackBar 之無障礙 hint。
  static String get composePostAudienceSchoolConflictSnackHint =>
      _p('audience 與 hide_school 不可如此組合；請調整可見範圍再送出（詳 docs 契約與完成鈕說明）。');

  /// [ComposePostScreen] 按下完成送出／更新時 API 錯誤 SnackBar 之無障礙 hint（本體為伺服器訊息）。
  /// 載入草稿之 GET 錯誤請用 [feedPostDetailLoadFailedSemanticsHint]。
  static String get composePostApiErrorSnackHint => _p(
    '錯誤內容由後端回傳。發佈：POST ${AppConfig.apiPrefix}/feed/posts；編輯：PATCH 同路徑已編碼 ID；body：body、audience、hide_school。',
  );

  /// [ComposePostScreen] 送出／更新非 [LiubanApiException]。
  static const String composePostSubmitGenericFailureMessage = '無法發佈動態，請稍後再試';

  static String get composePostSubmitGenericFailureSnackHint => _p(
    '預期 POST ${AppConfig.apiPrefix}/feed/posts 或 PATCH 同路徑已編碼 ID；非業務訊息時可能為連線或其他例外。',
  );

  /// [FeedScreen] 自撰寫頁返回且已成功建立動態時之 SnackBar（本體含可見範圍摘要）。
  static String get feedComposeNewPostSuccessSnackHint => _p(
    '動態已成功建立並關閉撰寫頁；訊息摘要反映可見範圍。API：POST ${AppConfig.apiPrefix}/feed/posts。',
  );

  /// [FeedScreen]／[FeedPostDetailScreen] 自編輯頁返回且已成功更新時（本體為摘要字串）。
  static String get feedComposeEditSavedSnackHint => _p(
    '動態已成功更新並關閉編輯頁；訊息摘要反映可見範圍。API：PATCH ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼。',
  );

  /// 登入頁頂部說明（含 Token／refresh 路徑）。
  static String get loginBanner => _p(
    '使用註冊時的自訂 ID（或學校郵箱）與密碼登入；成功後客戶端儲存 access／refresh 並可於 401 時自動刷新。'
    '登入：POST ${AppConfig.apiPrefix}/auth/login；刷新：POST ${AppConfig.apiPrefix}/auth/refresh（body：refresh_token）。',
  );

  static String loginSubmitHint({required bool loading}) {
    if (loading) return '處理中';
    return '使用帳號與密碼驗證。POST ${AppConfig.apiPrefix}/auth/login。 $docsTrail';
  }

  /// [LoginScreen] 未填帳密（未呼叫 API）。
  static String get loginValidationEmptyFieldsSnackHint =>
      _p('僅客戶端表單檢查；尚未 POST ${AppConfig.apiPrefix}/auth/login。');

  /// [LoginScreen] 帳號過長。
  static String loginAccountTooLongSnackHint(int maxLength) =>
      _p('帳號最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/login。');

  /// [LoginScreen] 密碼過長。
  static String loginPasswordTooLongSnackHint(int maxLength) =>
      _p('密碼最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/login。');

  /// [LoginScreen] 登入成功 SnackBar。
  static String get loginSuccessSnackHint =>
      _p('登入成功，已儲存 tokens。POST ${AppConfig.apiPrefix}/auth/login。');

  /// [LoginScreen] 登入 [LiubanApiException]（本體為後端訊息）。
  static String get loginApiErrorSnackHint =>
      _p('登入失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/auth/login。');

  /// 登入、註冊、忘記／重設密碼、變更密碼等提交時非 [LiubanApiException]。
  static const String authSubmitGenericFailureMessage = '無法完成請求，請檢查網路後再試';

  static String get authSubmitGenericFailureSnackHint => _p(
    '預期為 ${AppConfig.apiPrefix}/auth 路徑下 POST（login、register、password、password/reset 等）；非後端業務訊息時可能為連線或其他例外。',
  );

  /// 註冊頁頂部說明（含 multipart 註冊路徑）。
  static String get registrationBanner => _p(
    '完成資料並擇一上傳 Offer／錄取證明或學生證後進入身分審核；通過前權限同訪客，可瀏覽推廣、公開廣場與聯絡客服。'
    '註冊：POST ${AppConfig.apiPrefix}/auth/register（multipart）。',
  );

  static String registrationSubmitHint({required bool submitting}) {
    if (submitting) return '處理中';
    return '送出表單與審核圖片。POST ${AppConfig.apiPrefix}/auth/register（multipart）。 $docsTrail';
  }

  /// [RegistrationScreen] 欄位未齊。
  static String get registrationIncompleteSnackHint => _p(
    '請補齊欄位後再送出。送出任務為 POST ${AppConfig.apiPrefix}/auth/register（multipart）。',
  );

  /// [RegistrationScreen] 自訂 ID 過長。
  static String registrationCustomIdTooLongSnackHint(int maxLength) => _p(
    '自訂 ID 最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/register。',
  );

  /// [RegistrationScreen] 學校名稱過長。
  static String registrationSchoolTooLongSnackHint(int maxLength) => _p(
    '學校名稱最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/register。',
  );

  /// [RegistrationScreen] 學號過長。
  static String registrationStudentIdTooLongSnackHint(int maxLength) => _p(
    '學號最多 $maxLength 字元；超出時不會送出 POST ${AppConfig.apiPrefix}/auth/register。',
  );

  /// [RegistrationScreen] 未上傳審核圖檔。
  static String get registrationDocumentRequiredSnackHint => _p(
    '須上傳審核圖檔後方可註冊。POST ${AppConfig.apiPrefix}/auth/register（multipart，含檔案）。',
  );

  /// [RegistrationScreen] 相簿選圖或讀取檔案失敗時之 SnackBar 本文。
  static const String registrationPickImageFailedMessage = '無法讀取所選圖片';

  /// 同上之無障礙 hint（image_picker／本機檔案，尚未 POST register）。
  static String get registrationPickImageFailedSnackHint => _p(
    '從相簿挑選與讀入圖片為客戶端 image_picker 與檔案存取；失敗時尚未呼叫 POST ${AppConfig.apiPrefix}/auth/register。可重試或換圖。',
  );

  /// [RegistrationScreen] 註冊提交成功 SnackBar。
  static String get registrationSubmitSuccessSnackHint => _p(
    '註冊已提交，階段為審核中。POST ${AppConfig.apiPrefix}/auth/register 成功後寫入 session；詳見頂部橫幅說明。',
  );

  /// [RegistrationScreen] 註冊 [LiubanApiException]。
  static String get registrationApiErrorSnackHint => _p(
    '註冊失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/auth/register（multipart）。',
  );

  /// 推廣詳情頁頂（與列表 [promotionListBanner] 並列參考）。
  static String get promotionDetailDevNote =>
      _p('推廣詳情以單篇 GET ${AppConfig.apiPrefix}/promotions/推廣 ID 已編碼載入；可下拉重新整理。');

  /// 推廣詳情無資料（非 App 路由錯誤）。
  static const String promotionDetailEmptyTitle = '找不到此推廣內容';

  /// [PromotionDetailScreen] 無資料狀態之無障礙 hint。
  static String get promotionDetailEmptySemanticsHint => _p(
    '伺服器無此 ID 或請求失敗時顯示。請求：GET ${AppConfig.apiPrefix}/promotions/推廣 ID 已編碼。'
    '可於此頁面向下拖曳重新整理，或使用返回鈕離開。',
  );

  /// [PromotionDetailScreen] GET 失敗時之 SnackBar 本文。
  static const String promotionDetailLoadFailedMessage = '無法自伺服器載入推廣內容';

  /// 同上之無障礙 hint。
  static String get promotionDetailLoadFailedSnackHint => _p(
    '單篇：GET ${AppConfig.apiPrefix}/promotions/推廣 ID 已編碼。失敗時畫面維持無資料狀態；可下拉重新整理。',
  );

  /// [PromotionDetailScreen] GET 單篇失敗且後端回傳業務訊息時之 Snack hint（本體為 [LiubanApiException.message]）。
  static String get promotionDetailGetApiErrorSnackHint => _p(
    '載入推廣詳情失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/promotions/推廣 ID 已編碼。',
  );

  /// 動態詳情載入失敗（含編輯頁預載失敗 SnackBar）。
  static const String feedPostDetailLoadFailedTitle = '無法載入此動態';

  /// [FeedPostDetailScreen] 等無法解析帖文時之無障礙 hint。
  static String get feedPostDetailLoadFailedSemanticsHint => _p(
    '後端或網路失敗時顯示。單篇：GET ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼。'
    '可於此頁面向下拖曳重新整理，或使用返回鈕離開。',
  );

  /// [FeedPostDetailScreen]、[ComposePostScreen] 單篇 GET 失敗且後端回傳業務訊息時之 Snack hint（本體為 [LiubanApiException.message]）。
  static String get feedPostGetApiErrorSnackHint =>
      _p('載入動態失敗，訊息由後端回傳。預期：GET ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼。');

  /// 個人頁「同步審核狀態」列表副標。
  static String get verificationSyncSubtitle => _p(
    '從伺服器更新身分審核階段：GET ${AppConfig.apiPrefix}/auth/me/verification；隨後重新載入個人檔 GET ${AppConfig.apiPrefix}/auth/me。',
  );

  /// [_ComposeVerifiedShell] 等同步審核失敗時之簡短 SnackBar 本文（非 API 訊息字串）。
  static const String verificationSyncGenericFailureMessage = '無法同步，請稍後再試';

  /// 同上 snackbar 之無障礙 hint（網路或其他非業務錯誤）。
  static String get verificationSyncGenericFailureSnackHint => _p(
    '無法完成 GET ${AppConfig.apiPrefix}/auth/me/verification，本機審核階段未更新。可稍後在「我的」再試。',
  );

  /// [_ComposeVerifiedShell] 同步審核成功 SnackBar。
  static String get verificationSyncSuccessSnackHint => _p(
    '審核階段已自 GET ${AppConfig.apiPrefix}/auth/me/verification 更新並套用至 session。',
  );

  /// [_ComposeVerifiedShell] 同步審核 [LiubanApiException] SnackBar（本體為後端訊息）。
  static String get verificationSyncApiErrorSnackHint =>
      _p('同步審核狀態失敗。預期：GET ${AppConfig.apiPrefix}/auth/me/verification。');

  /// 個人頁除錯用階段切換器下方灰字說明。
  static String get profilePhasePreviewDisclaimer => _p(
    '下方帳戶階段切換僅供除錯。實際階段以 GET ${AppConfig.apiPrefix}/auth/me/verification 為準；請使用「同步審核狀態」。',
  );

  /// 設定「用戶協議與隱私」摘要全文（含 docs 尾註）。
  static String get settingsLegalPlaceholder =>
      '正式上線前將提供完整《用戶協議》與《隱私政策》連結；目前請以實際營運方公告為準。'
      '註冊時提交的 Offer、錄取證明、學生證與學籍資料僅用於審核與合規，詳見後續正式文案。'
      ' $docsTrail';

  /// [SettingsScreen] 主題、介面語言選擇對話框（僅客戶端偏好）。
  static String get settingsLocalUiPreferenceDialogHint =>
      _p('僅更新本機亮暗與語系，不向伺服器提交設定；與 ${AppConfig.apiPrefix} REST 無關。');

  /// [SettingsScreen] 主題或語系寫入 [SharedPreferences] 失敗時之 SnackBar 本文。
  static const String settingsPersistenceFailedMessage = '無法儲存設定，請重試';

  /// 同上之無障礙 hint。
  static String get settingsPersistenceFailedSnackHint => _p(
    '外觀與介面語言偏好寫入本機 SharedPreferences；失敗時畫面上選項未變更，與 ${AppConfig.apiPrefix} 無關。',
  );

  /// [SettingsScreen] 「協議與隱私」全文對話框外層（內文已含 [settingsLegalPlaceholder]）。
  static String get settingsLegalDialogContainerHint =>
      '捲動瀏覽條款摘要說明。 $docsTrail';

  /// 檢舉動態對話框頂部說明。
  static String get feedReportDialogIntro => _p(
    '請選擇檢舉原因；選「其他」時可於下一步填寫補充說明（選填）。送出時 POST ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼/report，body 可含 reason。',
  );

  /// [_FeedReportDialog] 選擇「其他」後，補充說明步驟之外層無障礙 hint。
  static String get feedReportOtherDetailSemanticsHint => _p(
    '填寫檢舉補充說明（選填）。送出仍為 POST ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼/report。',
  );

  /// [_FeedReportDialog] 補充說明 [TextField] 之無障礙 hint。
  static String get feedReportOtherFieldSemanticsHint =>
      _p('併入單一 reason 字串與代碼 other 一併送出；輸入上限 480 字元。');

  /// [_FeedReportDialog] 「送出檢舉」按鈕（其他／補充說明步驟）。
  static String get feedReportSubmitOtherSemanticsHint => _p(
    '以目前輸入組合 reason 並 POST ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼/report。',
  );

  /// [FeedApi.reportPost] 送出前 `reason` 長度超過上限（見 [LiubanInputLimits.feedReportReasonMaxTotalLength]）。
  static String feedReportReasonTooLongMessage(int maxLength) =>
      '檢舉說明過長，請控制在 $maxLength 字以內';

  /// [runFeedReportFlow] 檢舉原因過長（客戶端防禦）SnackBar 無障礙 hint。
  static String feedReportReasonTooLongSnackHint(int maxLength) => _p(
    '檢舉 reason 未送出；長度須不超過 $maxLength（見 POST ${AppConfig.apiPrefix}/feed/posts/{id}/report）。',
  );

  /// 屏蔽對話框第二段（接在使用者說明之後）。
  static String get blockUserApiNote => _p(
    '確認後 POST ${AppConfig.apiPrefix}/friends/blocks，body：user_id；可於設定已屏蔽列表解除。',
  );

  /// 刪除本人動態對話框第二段。
  static String get deleteOwnPostApiNote =>
      _p('伺服器端：DELETE ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼。');

  /// [runFeedReportFlow] 檢舉成功 SnackBar 無障礙 hint。
  static String get feedReportSuccessSnackHint =>
      _p('檢舉已送往伺服器。POST ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼/report。');

  /// [runFeedReportFlow] 檢舉失敗 SnackBar（本體為後端訊息）。
  static String get feedReportErrorSnackHint =>
      _p('檢舉請求失敗。路徑：POST ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼/report。');

  /// [runBlockUserFlow] 屏蔽成功 SnackBar。
  static String get blockUserSuccessSnackHint =>
      _p('屏蔽已提交。POST ${AppConfig.apiPrefix}/friends/blocks，body：user_id。');

  /// [runBlockUserFlow] 屏蔽失敗 SnackBar（本體為後端訊息）。
  static String get blockUserErrorSnackHint =>
      _p('屏蔽請求失敗。路徑：POST ${AppConfig.apiPrefix}/friends/blocks。');

  /// [runDeleteOwnPostFlow] 刪除成功 SnackBar。
  static String get deleteOwnPostSuccessSnackHint =>
      _p('動態已請求自伺服器刪除。DELETE ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼。');

  /// [runDeleteOwnPostFlow] 刪除失敗 SnackBar（本體為後端訊息）。
  static String get deleteOwnPostErrorSnackHint =>
      _p('刪除請求失敗。路徑：DELETE ${AppConfig.apiPrefix}/feed/posts/動態 ID 已編碼。');

  /// 檢舉、屏蔽、刪除本人動態等流程非 [LiubanApiException]。
  static const String feedModerationGenericFailureMessage = '無法完成操作，請稍後再試';

  static String get feedModerationGenericFailureSnackHint => _p(
    '可能為 POST ${AppConfig.apiPrefix}/feed/posts/…/report、POST …/friends/blocks、DELETE …/feed/posts/…；非業務訊息時為網路或其他例外。',
  );

  /// [BlockedUsersScreen] 解除屏蔽確認對話框（與 [friendsBlocks] 之 remove 路徑一致）。
  static String get unblockUserConfirmDialogHint =>
      _p('確認後 POST ${AppConfig.apiPrefix}/friends/blocks/remove，body：user_id。');

  /// [BlockedUsersScreen] 解除屏蔽成功 SnackBar。
  static String get unblockUserSuccessSnackHint => _p(
    '解除屏蔽已送出。POST ${AppConfig.apiPrefix}/friends/blocks/remove，body：user_id。',
  );

  /// [BlockedUsersScreen] 解除 [LiubanApiException]。
  static String get unblockUserApiErrorSnackHint => _p(
    '解除屏蔽失敗，訊息由後端回傳。預期：POST ${AppConfig.apiPrefix}/friends/blocks/remove。',
  );

  /// [AuthRequiredGate] 畫面上第三段小字（登入／註冊路徑與 Bearer）。
  static String get authRequiredGateApiFootnote => _p(
    '登入：POST ${AppConfig.apiPrefix}/auth/login；新帳戶：POST ${AppConfig.apiPrefix}/auth/register（multipart）。'
    '成功後受保護請求由客戶端帶 Bearer access token。',
  );

  /// 同上頁之完整無障礙標題（含使用者說明與 [authRequiredGateApiFootnote]）。
  static String get authRequiredGateSemanticsLabel =>
      '請先登入以使用此功能。訪客可瀏覽公開廣場與推廣；好友與私聊需帳號。 $authRequiredGateApiFootnote';

  /// 「關於留伴」對話框產品說明（第一段）。
  static String get aboutDialogDescription =>
      '在港留學生的廣場、好友與推廣資訊。具體功能與權限以帳戶審核狀態為準。';

  /// 「關於留伴」對話框第二段（API 前綴與 docs）。
  static String get aboutDialogApiFootnote => _p(
    'REST 相對路徑前綴為 ${AppConfig.apiPrefix}（dart-define API_PREFIX 可覆寫）；契約見專案 docs。',
  );

  /// [aboutDialogDescription] 與 [aboutDialogApiFootnote] 合併，供對話框 [Semantics]。
  static String get aboutDialogSemanticsLabel =>
      '關於留伴。$aboutDialogDescription $aboutDialogApiFootnote';

  /// [GoRouter] 錯誤頁尾註（App 路由／deep link，非 REST 404）。
  static String get routeNotFoundFootnote => _p(
    '此為 App 內路由錯誤或無效 deep link，與後端 REST 404 不同。API 相對前綴仍為 ${AppConfig.apiPrefix}；詳 docs。',
  );

  /// [LiubanApp] 深連結被拒或無法導覽時之 [SnackBar] 無障礙 hint（本體文案仍為簡短使用者訊息）。
  static String get deepLinkNavigationRejectedHint =>
      _p('屬 App 內連結白名單、長度或導覽限制，非後端依 ${AppConfig.apiPrefix} 直接回傳的錯誤。');

  /// 深連結與 [GoRouter] 失敗時的簡短使用者訊息（與錯誤頁 AppBar 對齊）。
  static const String deepLinkUserMessageOpenFailed = '無法開啟此頁面';
  static const String deepLinkUserMessageLinkTooLong = '連結過長，無法開啟';
  static const String deepLinkUserMessageUnrecognized = '無法辨識此連結';
  static const String deepLinkUserMessageDisallowedInApp = '此連結無法在 App 內開啟';

  /// [buildRouter] error 為 null 時之本體主文。
  static const String routeErrorBodyFallbackMessage =
      '此連結無法在 App 內開啟，或尚未註冊對應頁面。';

  /// 將 [GoException.message] 轉成使用者可讀中文（無法辨識則回傳 [raw]）。
  static String userFacingGoRouterMessage(String raw) {
    if (raw.startsWith('no routes for location:')) {
      return '沒有符合此路徑的 App 頁面。';
    }
    if (raw.startsWith('redirect loop detected')) {
      return '重新導向發生循環，已停止。';
    }
    if (raw.startsWith('too many redirects')) {
      return '重新導向次數過多，已停止。';
    }
    if (raw == 'Location cannot be empty.') {
      return '路由位置不可為空。';
    }
    return raw;
  }

  /// 與 [deepLinkUserMessageOpenFailed] 相同（全螢幕路由錯誤頁標題）。
  static const String routeErrorScreenAppBarTitle =
      deepLinkUserMessageOpenFailed;

  /// 路由錯誤頁 AppBar 無障礙標題。
  static const String routeErrorScreenAppBarSemanticsLabel = '無法開啟此頁面或連結';

  /// 路由錯誤頁 AppBar：與 SnackBar 共用之功能／無障礙尾註。
  static String get routeErrorScreenAppBarSemanticsHint =>
      deepLinkNavigationRejectedHint;

  /// 路由錯誤頁無障礙標題：[errorOrFallback]、可選 [attemptedSafeLocation]、[routeNotFoundFootnote]。
  static String routeErrorSemanticsLabel(
    String errorOrFallback, {
    String? attemptedSafeLocation,
  }) {
    final loc = attemptedSafeLocation?.trim();
    final locPart = (loc != null && loc.isNotEmpty) ? '嘗試開啟（已脫敏）：$loc。 ' : '';
    return '$errorOrFallback $locPart$routeNotFoundFootnote';
  }

  /// [showShareLinkSheet] 內說明：網址用途與 REST 有別。
  static String get shareLinkSheetFootnote => _p(
    '此處為可複製／系統分享之網址（H5、deep link 等），非後端 REST path。REST 相對前綴：${AppConfig.apiPrefix}；詳 docs。',
  );

  /// [showShareLinkSheet]「已複製連結」SnackBar。
  static String get shareLinkCopiedSnackHint =>
      _p('連結已複製到剪貼簿，為客戶端操作；未因此呼叫 ${AppConfig.apiPrefix} REST。');

  /// [showShareLinkSheet] 複製失敗時之 SnackBar 本文。
  static const String shareLinkCopyFailedMessage = '無法複製連結';

  /// 同上之無障礙 hint（系統剪貼簿，與 API 無關）。
  static String get shareLinkCopyFailedSnackHint => _p(
    '寫入剪貼簿為客戶端 Flutter Clipboard 行為；失敗可能與權限、模擬器或系統限制有關，並非 ${AppConfig.apiPrefix} 請求錯誤。',
  );

  /// [showShareLinkSheet] 呼叫系統分享失敗時之 SnackBar 本文。
  static const String shareLinkSystemShareFailedMessage = '無法開啟系統分享';

  /// 同上之無障礙 hint（`share_plus`／平台分享面板，非 REST）。
  static String get shareLinkSystemShareFailedSnackHint => _p(
    '系統分享由作業系統與 share_plus 插件處理；失敗時未送出網路至 ${AppConfig.apiPrefix}。可改用手動複製連結。',
  );

  /// 訊息分頁官方客服頂部橫幅（訪客提示 + API）。
  static String get supportGuestBanner => _p(
    '訪客無需註冊即可聯絡平台；建議保留防濫用頻率限制。'
    '留言可走 POST ${AppConfig.apiPrefix}/support/messages（詳見進入對話後說明）。',
  );

  /// [SettingsScreen] 開源許可全螢幕頁（Flutter [LicensePage]）。
  static String get openSourceLicensesPageHint =>
      _p('顯示套件授權全文，資料內嵌於 App，非自 ${AppConfig.apiPrefix} 載入。');
}
