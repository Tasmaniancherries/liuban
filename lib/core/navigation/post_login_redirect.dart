/// 登入成功後 `go()` 之用：僅允許應用內相對路徑，阻擋明顯的 open-redirect。
String? sanitizePostLoginRedirect(String? raw) {
  if (raw == null) return null;
  final t = Uri.decodeComponent(raw).trim();
  if (t.isEmpty) return null;
  if (t.length > 768) return null;
  if (!t.startsWith('/')) return null;
  if (t.startsWith('//')) return null;
  if (t.contains('://') || t.contains(r'\')) return null;
  if (t.toLowerCase().startsWith('/login')) return null;
  return t;
}
