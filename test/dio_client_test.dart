import "package:flutter_test/flutter_test.dart";
import "package:liuban/core/network/dio_client.dart";

void main() {
  test("sanitizeNetworkLogLine redacts bearer token", () {
    const line = "Authorization: Bearer abc.def.ghi";
    final safe = DioClient.sanitizeNetworkLogLine(line);
    expect(safe, "Authorization: Bearer ***");
    expect(safe.contains("abc.def.ghi"), isFalse);
  });

  test("sanitizeNetworkLogLine redacts token auth header", () {
    const line = "Authorization: Token abc123";
    final safe = DioClient.sanitizeNetworkLogLine(line);
    expect(safe, "Authorization: Token ***");
    expect(safe.contains("abc123"), isFalse);
  });

  test("sanitizeNetworkLogLine redacts proxy authorization headers", () {
    const bearer = "Proxy-Authorization: Bearer abc.def";
    const basic = "Proxy-Authorization: Basic dXNlcjpwYXNz";
    const token = "Proxy-Authorization: Token xyz";
    final safeBearer = DioClient.sanitizeNetworkLogLine(bearer);
    final safeBasic = DioClient.sanitizeNetworkLogLine(basic);
    final safeToken = DioClient.sanitizeNetworkLogLine(token);
    expect(safeBearer, "Proxy-Authorization: Bearer ***");
    expect(safeBasic, "Proxy-Authorization: Basic ***");
    expect(safeToken, "Proxy-Authorization: Token ***");
    expect(safeBearer.contains("abc.def"), isFalse);
    expect(safeBasic.contains("dXNlcjpwYXNz"), isFalse);
    expect(safeToken.contains("xyz"), isFalse);
  });

  test("sanitizeNetworkLogLine redacts digest authorization headers", () {
    const line = 'Authorization: Digest username="Mufasa", realm="testrealm@host.com", nonce="abc"';
    final safe = DioClient.sanitizeNetworkLogLine(line);
    expect(safe, "Authorization: Digest ***");
    expect(safe.contains('username="Mufasa"'), isFalse);
    expect(safe.contains('nonce="abc"'), isFalse);
  });

  test("sanitizeNetworkLogLine redacts token-like custom headers", () {
    const lineA = "X-Auth-Token: aaa";
    const lineB = "X-Access-Token: bbb";
    const lineC = "X-Refresh-Token: ccc";
    const lineD = "X-CSRF-Token: ddd";
    final safeA = DioClient.sanitizeNetworkLogLine(lineA);
    final safeB = DioClient.sanitizeNetworkLogLine(lineB);
    final safeC = DioClient.sanitizeNetworkLogLine(lineC);
    final safeD = DioClient.sanitizeNetworkLogLine(lineD);
    expect(safeA, "X-Auth-Token: ***");
    expect(safeB, "X-Access-Token: ***");
    expect(safeC, "X-Refresh-Token: ***");
    expect(safeD, "X-CSRF-Token: ***");
  });

  test("sanitizeNetworkLogLine redacts generic sensitive header names", () {
    const lineA = "X-Session-Token: abc";
    const lineB = "X-Client-Secret: xyz";
    const lineC = "X-Password-Hint: hidden";
    final safeA = DioClient.sanitizeNetworkLogLine(lineA);
    final safeB = DioClient.sanitizeNetworkLogLine(lineB);
    final safeC = DioClient.sanitizeNetworkLogLine(lineC);
    expect(safeA, "X-Session-Token: ***");
    expect(safeB, "X-Client-Secret: ***");
    expect(safeC, "X-Password-Hint: ***");
  });

  test("sanitizeNetworkLogLine redacts URL userinfo credentials", () {
    const line = "GET https://user:pass@api.liuban.app/feed?x=1";
    final safe = DioClient.sanitizeNetworkLogLine(line);
    expect(safe, "GET https://***@api.liuban.app/feed?x=1");
    expect(safe.contains("user:pass@"), isFalse);
  });

  test("sanitizeNetworkLogLine redacts password and token json values", () {
    const line =
        '{"password":"p@ss","access_token":"aaa","refresh_token":"bbb","id_token":"ccc","token":"ddd","state":"ok"}';
    final safe = DioClient.sanitizeNetworkLogLine(line);
    expect(safe.contains('"password":"***"'), isTrue);
    expect(safe.contains('"access_token":"***"'), isTrue);
    expect(safe.contains('"refresh_token":"***"'), isTrue);
    expect(safe.contains('"id_token":"***"'), isTrue);
    expect(safe.contains('"token":"***"'), isTrue);
    expect(safe.contains('"state":"ok"'), isTrue);
    expect(safe.contains('"password":"p@ss"'), isFalse);
    expect(safe.contains('"access_token":"aaa"'), isFalse);
  });

  test("sanitizeNetworkLogLine truncates oversized log lines", () {
    final huge = List.filled(2200, "x").join();
    final safe = DioClient.sanitizeNetworkLogLine(huge);
    expect(safe.length < huge.length, isTrue);
    expect(safe.contains("truncated"), isTrue);
  });

  test("sanitizeNetworkLogLine redacts sensitive URL query values", () {
    const line =
        "GET https://api.liuban.app/reset-password?token=abc&state=ok&client_secret=shh&api_key=kkk";
    final safe = DioClient.sanitizeNetworkLogLine(line);
    expect(safe.contains("token=***"), isTrue);
    expect(safe.contains("client_secret=***"), isTrue);
    expect(safe.contains("api_key=***"), isTrue);
    expect(safe.contains("state=ok"), isTrue);
    expect(safe.contains("token=abc"), isFalse);
    expect(safe.contains("client_secret=shh"), isFalse);
    expect(safe.contains("api_key=kkk"), isFalse);
  });

  test("sanitizeNetworkLogLine redacts cookie headers", () {
    const lineA = "Cookie: session=abc; refresh=def";
    const lineB = "Set-Cookie: sid=abc123; HttpOnly; Secure";
    final safeA = DioClient.sanitizeNetworkLogLine(lineA);
    final safeB = DioClient.sanitizeNetworkLogLine(lineB);
    expect(safeA, "Cookie: ***");
    expect(safeB, "Set-Cookie: ***");
    expect(safeA.contains("session=abc"), isFalse);
    expect(safeB.contains("sid=abc123"), isFalse);
  });

  test("sanitizeNetworkLogLine redacts basic auth and api key headers", () {
    const lineA = "Authorization: Basic dXNlcjpwYXNz";
    const lineB = "X-API-Key: abc123";
    final safeA = DioClient.sanitizeNetworkLogLine(lineA);
    final safeB = DioClient.sanitizeNetworkLogLine(lineB);
    expect(safeA, "Authorization: Basic ***");
    expect(safeB, "X-API-Key: ***");
    expect(safeA.contains("dXNlcjpwYXNz"), isFalse);
    expect(safeB.contains("abc123"), isFalse);
  });

  test("sanitizeNetworkLogLine redacts form-encoded sensitive pairs", () {
    const line = "password=p@ss&token=abc&state=ok&client_secret=shh";
    final safe = DioClient.sanitizeNetworkLogLine(line);
    expect(safe.contains("password=***"), isTrue);
    expect(safe.contains("token=***"), isTrue);
    expect(safe.contains("client_secret=***"), isTrue);
    expect(safe.contains("state=ok"), isTrue);
    expect(safe.contains("password=p@ss"), isFalse);
    expect(safe.contains("token=abc"), isFalse);
  });
}
