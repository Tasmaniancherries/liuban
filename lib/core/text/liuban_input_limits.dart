/// 客戶端輸入長度上限（與各畫面 [TextField.maxLength] 及 API 防禦對齊）。
abstract final class LiubanInputLimits {
  /// 私訊與官方客服單則文字上限。
  static const int chatMessageMaxLength = 500;

  /// 動態正文上限。
  static const int feedPostBodyMaxLength = 2000;

  /// 檢舉「其他」補充說明欄上限（併入 `other — {說明}` 前）。
  static const int feedReportOtherDetailMaxLength = 480;

  /// 檢舉 `reason` 送出前總長上限（含分類代碼與分隔符）。
  static const int feedReportReasonMaxTotalLength = 512;

  /// 自訂 ID（註冊、加好友等）。
  static const int customIdMaxLength = 32;

  /// 註冊學校名稱。
  static const int schoolNameMaxLength = 80;

  /// 註冊學號。
  static const int studentIdMaxLength = 32;

  /// 登入帳號欄。
  static const int loginAccountMaxLength = 128;

  /// 登入／修改／重設密碼欄。
  static const int passwordMaxLength = 128;

  /// 忘記密碼信箱。
  static const int emailMaxLength = 254;

  /// 郵件重設連結 token。
  static const int resetTokenMaxLength = 512;

  /// [LiubanApiException.code]：聊天文字超長（未送出 HTTP）。
  static const String messageTextTooLongCode = 'message_text_too_long';

  /// [LiubanApiException.code]：檢舉 reason 超長（未送出 HTTP）。
  static const String reportReasonTooLongCode = 'report_reason_too_long';

  /// [LiubanApiException.code]：一般欄位超長（未送出 HTTP）。
  static const String inputTooLongCode = 'input_too_long';
}
