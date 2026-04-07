Map<String, dynamic> asJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw FormatException("預期 JSON 物件，實際為 ${data.runtimeType}");
}

List<Map<String, dynamic>> asJsonObjectList(dynamic data) {
  if (data is List) {
    return data.map((e) => asJsonMap(e)).toList();
  }
  if (data is Map && data["items"] is List) {
    return (data["items"] as List).map((e) => asJsonMap(e)).toList();
  }
  if (data is Map && data["data"] is List) {
    return (data["data"] as List).map((e) => asJsonMap(e)).toList();
  }
  throw FormatException("預期 JSON 陣列或 {items:[]}，實際為 ${data.runtimeType}");
}
