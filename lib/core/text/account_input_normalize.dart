/// 自訂 ID 欄位：去掉使用者誤貼的開頭 `@`。
String normalizeLeadingAtCustomId(String raw) {
  var s = raw.trim();
  if (s.startsWith("@")) {
    s = s.substring(1).trim();
  }
  return s;
}

/// 登入帳號：若整段只在開頭有一個 `@`（其餘無 `@`），視為自訂 ID 並去掉前綴；含 `@` 的郵箱不變。
String normalizeLoginAccount(String raw) {
  var s = raw.trim();
  if (s.startsWith("@") && !s.substring(1).contains("@")) {
    s = s.substring(1).trim();
  }
  return s;
}
