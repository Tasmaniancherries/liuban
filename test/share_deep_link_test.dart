import "package:flutter_test/flutter_test.dart";
import "package:liuban/core/navigation/share_deep_link.dart";

void main() {
  test("parseShareLinkOrigin trims trailing slash and adds scheme if missing",
      () {
    expect(
        parseShareLinkOrigin("https://www.liuban.app/").host, "www.liuban.app");
    expect(
        parseShareLinkOrigin("https://www.liuban.app////").host, "www.liuban.app");
    expect(parseShareLinkOrigin("https://liuban.app.").host, "liuban.app");
    expect(parseShareLinkOrigin("liuban.app...").host, "liuban.app");
    expect(parseShareLinkOrigin("liuban.app").host, "liuban.app");
    expect(parseShareLinkOrigin("https://[::1]/").host, "::1");
  });

  test("isLikelyIpv6LiteralHost shared with deep-link authority checks", () {
    expect(isLikelyIpv6LiteralHost("::1"), isTrue);
    expect(isLikelyIpv6LiteralHost("2001:db8::1"), isTrue);
    expect(
      isLikelyIpv6LiteralHost("2001:0db8:85a3:0000:0000:8a2e:0370:7334"),
      isTrue,
    );
    expect(isLikelyIpv6LiteralHost("liuban.app"), isFalse);
    expect(isLikelyIpv6LiteralHost(":::1"), isFalse);
    expect(isLikelyIpv6LiteralHost("a:b"), isFalse);
  });

  test("parseShareLinkOrigin invalid value falls back safely", () {
    final parsed = parseShareLinkOrigin("https://%");
    expect(parsed.host, isEmpty);
    expect(parsed.scheme, isEmpty);
    final parsed2 = parseShareLinkOrigin("https://liuban app");
    expect(parsed2.host, isEmpty);
    expect(parsed2.scheme, isEmpty);
    final parsed3 = parseShareLinkOrigin("https://bad_host.liuban.app");
    expect(parsed3.host, isEmpty);
    expect(parsed3.scheme, isEmpty);
    final parsed4 = parseShareLinkOrigin("https://-bad.liuban.app");
    expect(parsed4.host, isEmpty);
    expect(parsed4.scheme, isEmpty);
    final parsed5 = parseShareLinkOrigin("https://bad-.liuban.app");
    expect(parsed5.host, isEmpty);
    expect(parsed5.scheme, isEmpty);
    final parsed6 = parseShareLinkOrigin("https://liuban..app");
    expect(parsed6.host, isEmpty);
    expect(parsed6.scheme, isEmpty);
    final tooLongLabel = "${List.filled(64, "a").join()}.liuban.app";
    final parsed7 = parseShareLinkOrigin("https://$tooLongLabel");
    expect(parsed7.host, isEmpty);
    expect(parsed7.scheme, isEmpty);
    final tooLongHost = "${List.filled(250, "a").join()}.app";
    final parsed8 = parseShareLinkOrigin("https://$tooLongHost");
    expect(parsed8.host, isEmpty);
    expect(parsed8.scheme, isEmpty);
    final parsed9 = parseShareLinkOrigin("ftp://liuban.app");
    expect(parsed9.host, isEmpty);
    expect(parsed9.scheme, isEmpty);
    final parsed10 = parseShareLinkOrigin("https://liuban.app/path");
    expect(parsed10.host, isEmpty);
    expect(parsed10.scheme, isEmpty);
    final parsed11 = parseShareLinkOrigin("https://liuban.app?x=1");
    expect(parsed11.host, isEmpty);
    expect(parsed11.scheme, isEmpty);
    final parsed12 = parseShareLinkOrigin("https://liuban.app#sec");
    expect(parsed12.host, isEmpty);
    expect(parsed12.scheme, isEmpty);
    final parsed13 = parseShareLinkOrigin("https://user@liuban.app");
    expect(parsed13.host, isEmpty);
    expect(parsed13.scheme, isEmpty);
    final badIpv6 = parseShareLinkOrigin("https://[:::1]/");
    expect(badIpv6.host, isEmpty);
    expect(badIpv6.scheme, isEmpty);
    final badIpv62 = parseShareLinkOrigin("https://2001:db8::1::1/");
    expect(badIpv62.host, isEmpty);
    expect(badIpv62.scheme, isEmpty);
  });

  test("parseShareLinkOrigin accepts bracketed IPv6 origins", () {
    expect(
      parseShareLinkOrigin("https://[2001:db8::1]/").host,
      "2001:db8::1",
    );
  });

  test("shareUriToAppLocation maps https post path when host matches origin",
      () {
    final loc =
        shareUriToAppLocation(Uri.parse("https://liuban.app/post/hello"));
    expect(loc, "/post/hello");
  });

  test("accepts www host when origin is apex", () {
    final loc = shareUriToAppLocation(
        Uri.parse("https://www.liuban.app/post/abc%2Fdef"));
    expect(loc, "/post/abc%2Fdef");
  });

  test("rejects wrong host", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://evil.com/post/x")),
      isNull,
    );
  });

  test("rejects https deep links with userInfo", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://user:pass@liuban.app/feed")),
      isNull,
    );
  });

  test("rejects liuban deep links with userInfo", () {
    expect(
      shareUriToAppLocation(Uri.parse("liuban://user@post/abc")),
      isNull,
    );
  });

  test("rejects liuban deep links with port", () {
    expect(
      shareUriToAppLocation(Uri.parse("liuban://post:8443/abc")),
      isNull,
    );
  });

  test("liuban scheme with post host", () {
    final loc = shareUriToAppLocation(Uri.parse("liuban://post/hi"));
    expect(loc, "/post/hi");
  });

  test("https promotion path", () {
    final loc =
        shareUriToAppLocation(Uri.parse("https://liuban.app/promotion/42"));
    expect(loc, "/promotion/42");
  });

  test("liuban scheme promotion host", () {
    final loc = shareUriToAppLocation(Uri.parse("liuban://promotion/9"));
    expect(loc, "/promotion/9");
  });

  test("unknown path on right host returns null", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/other/x")),
      isNull,
    );
  });

  test("https dynamic paths reject extra trailing segments", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/post/abc/extra")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/promotion/9/extra")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/dm/u1/extra")),
      isNull,
    );
  });

  test("path segment matching tolerates surrounding spaces", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/%20post%20/abc")),
      "/post/abc",
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://post/%20abc%20")),
      "/post/abc",
    );
  });

  test("https reset-password with token", () {
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/reset-password?token=abc%26x"),
    );
    expect(loc, "/reset-password?token=abc%26x");
  });

  test("https reset-password without token", () {
    final loc =
        shareUriToAppLocation(Uri.parse("https://liuban.app/reset-password"));
    expect(loc, "/reset-password");
  });

  test("https reset-password token trims surrounding whitespace", () {
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/reset-password?token=%20abc%20"),
    );
    expect(loc, "/reset-password?token=abc");
  });

  test("https reset-password oversized token falls back safely", () {
    final long = List.filled(3000, "a").join();
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/reset-password?token=$long"),
    );
    expect(loc, "/reset-password");
  });

  test("liuban reset-password host with query", () {
    final loc = shareUriToAppLocation(
        Uri.parse("liuban://reset-password?token=secret"));
    expect(loc, "/reset-password?token=secret");
  });

  test("https dm with peer and custom query", () {
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/dm/u1?custom=alice"),
    );
    expect(loc, "/dm/u1?custom=alice");
  });

  test("https dm peer only", () {
    final loc =
        shareUriToAppLocation(Uri.parse("https://liuban.app/dm/peer%2Fx"));
    expect(loc, "/dm/peer%2Fx");
  });

  test("dm custom too long is ignored safely", () {
    final long = List.filled(200, "c").join();
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/dm/u1?custom=$long"),
    );
    expect(loc, "/dm/u1");
  });

  test("liuban dm host", () {
    final loc = shareUriToAppLocation(Uri.parse("liuban://dm/abc?custom=z"));
    expect(loc, "/dm/abc?custom=z");
  });

  test("https register login settings forgot", () {
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/register")),
        "/register");
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/settings")),
        "/settings");
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/forgot-password")),
      "/forgot-password",
    );
    expect(
        shareUriToAppLocation(Uri.parse("https://liuban.app/login")), "/login");
    expect(
      shareUriToAppLocation(
          Uri.parse("https://liuban.app/login?redirect=%2Fpost%2Fa")),
      "/login?redirect=%2Fpost%2Fa",
    );
    expect(
      shareUriToAppLocation(
          Uri.parse("https://liuban.app/login?redirect=https%3A%2F%2Fevil")),
      "/login",
    );
  });

  test("https login oversized redirect falls back to plain login", () {
    final long = Uri.encodeComponent("/post/${List.filled(3000, "x").join()}");
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/login?redirect=$long"),
    );
    expect(loc, "/login");
  });

  test("route-managed long query keys are case-insensitive", () {
    final long = List.filled(3000, "x").join();
    final reset = shareUriToAppLocation(
      Uri.parse("https://liuban.app/reset-password?Token=$long"),
    );
    final longRedirect = Uri.encodeComponent("/post/$long");
    final login = shareUriToAppLocation(
      Uri.parse("https://liuban.app/login?Redirect=$longRedirect"),
    );
    expect(reset, "/reset-password");
    expect(login, "/login");
  });

  test("query keys are case-insensitive for token/redirect/custom", () {
    final reset = shareUriToAppLocation(
      Uri.parse("https://liuban.app/reset-password?Token=abc"),
    );
    final login = shareUriToAppLocation(
      Uri.parse("https://liuban.app/login?Redirect=%2Ffeed"),
    );
    final dm = shareUriToAppLocation(
      Uri.parse("https://liuban.app/dm/u1?Custom=alice"),
    );
    expect(reset, "/reset-password?token=abc");
    expect(login, "/login?redirect=%2Ffeed");
    expect(dm, "/dm/u1?custom=alice");
  });

  test("repeated query key picks first non-empty value", () {
    final reset = shareUriToAppLocation(
      Uri.parse("https://liuban.app/reset-password?token=&token=%20%20&token=abc"),
    );
    final login = shareUriToAppLocation(
      Uri.parse(
        "https://liuban.app/login?redirect=&redirect=%20%20&redirect=%2Ffeed",
      ),
    );
    final dm = shareUriToAppLocation(
      Uri.parse("https://liuban.app/dm/u1?custom=&custom=%20%20&custom=alice"),
    );
    expect(reset, "/reset-password?token=abc");
    expect(login, "/login?redirect=%2Ffeed");
    expect(dm, "/dm/u1?custom=alice");
  });

  test("mixed-case repeated query key still picks first non-empty value", () {
    final reset = shareUriToAppLocation(
      Uri.parse("https://liuban.app/reset-password?Token=&token=abc"),
    );
    final login = shareUriToAppLocation(
      Uri.parse("https://liuban.app/login?Redirect=&redirect=%2Ffeed"),
    );
    final dm = shareUriToAppLocation(
      Uri.parse("https://liuban.app/dm/u1?Custom=&custom=alice"),
    );
    expect(reset, "/reset-password?token=abc");
    expect(login, "/login?redirect=%2Ffeed");
    expect(dm, "/dm/u1?custom=alice");
  });

  test("query key matching tolerates surrounding spaces", () {
    final reset = shareUriToAppLocation(
      Uri.parse("https://liuban.app/reset-password?%20Token%20=abc"),
    );
    final login = shareUriToAppLocation(
      Uri.parse("https://liuban.app/login?%20Redirect%20=%2Ffeed"),
    );
    final dm = shareUriToAppLocation(
      Uri.parse("https://liuban.app/dm/u1?%20Custom%20=alice"),
    );
    expect(reset, "/reset-password?token=abc");
    expect(login, "/login?redirect=%2Ffeed");
    expect(dm, "/dm/u1?custom=alice");
  });

  test("https unknown single segment", () {
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/unknownleaf")),
        isNull);
  });

  test("liuban marketing hosts", () {
    expect(shareUriToAppLocation(Uri.parse("liuban://register")), "/register");
    expect(
        shareUriToAppLocation(Uri.parse("liuban://login?redirect=%2Fdm%2Fx")),
        "/login?redirect=%2Fdm%2Fx");
  });

  test("https friends compose settings paths", () {
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/add-friend")),
        "/add-friend");
    expect(
        shareUriToAppLocation(Uri.parse("https://liuban.app/friend-requests")),
        "/friend-requests");
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/compose")),
        "/compose");
    expect(
      shareUriToAppLocation(
          Uri.parse("https://liuban.app/compose/edit/abc%2F1")),
      "/compose/edit/abc%2F1",
    );
    expect(
      shareUriToAppLocation(
          Uri.parse("https://liuban.app/settings/blocked-users")),
      "/settings/blocked-users",
    );
  });

  test("liuban compose host", () {
    expect(shareUriToAppLocation(Uri.parse("liuban://compose")), "/compose");
    expect(shareUriToAppLocation(Uri.parse("liuban://compose/edit/x")),
        "/compose/edit/x");
  });

  test("https support and account password", () {
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/support")),
        "/support");
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/account/password")),
      "/account/password",
    );
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/account/other")),
        isNull);
  });

  test("liuban support and account password", () {
    expect(shareUriToAppLocation(Uri.parse("liuban://support")), "/support");
    expect(
      shareUriToAppLocation(Uri.parse("liuban://account/password")),
      "/account/password",
    );
  });

  test("main shell tab paths (https and liuban)", () {
    expect(
        shareUriToAppLocation(Uri.parse("https://liuban.app/feed")), "/feed");
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/promotion")),
        "/promotion");
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/promotion/9")),
      "/promotion/9",
    );
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/messages")),
        "/messages");
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/profile")),
        "/profile");
    expect(shareUriToAppLocation(Uri.parse("liuban://feed")), "/feed");
    expect(
        shareUriToAppLocation(Uri.parse("liuban://promotion")), "/promotion");
    expect(shareUriToAppLocation(Uri.parse("liuban://promotion/9")),
        "/promotion/9");
    expect(shareUriToAppLocation(Uri.parse("liuban://messages")), "/messages");
    expect(shareUriToAppLocation(Uri.parse("liuban://profile")), "/profile");
  });

  test("http scheme is treated like https for matching paths", () {
    expect(
      shareUriToAppLocation(Uri.parse("http://liuban.app/feed")),
      "/feed",
    );
    expect(
      shareUriToAppLocation(Uri.parse("http://liuban.app/post/a")),
      "/post/a",
    );
  });

  test("scheme match is case-insensitive", () {
    expect(
      shareUriToAppLocation(Uri.parse("HTTPS://liuban.app/feed")),
      "/feed",
    );
    expect(
      shareUriToAppLocation(Uri.parse("LIUBAN://post/abc")),
      "/post/abc",
    );
  });

  test("fixed path segment matching is case-insensitive", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/Post/abc")),
      "/post/abc",
    );
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/DM/u1?custom=a")),
      "/dm/u1?custom=a",
    );
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/Settings/Blocked-Users")),
      "/settings/blocked-users",
    );
  });

  test("single-segment route matching is case-insensitive", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/Feed")),
      "/feed",
    );
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/Login?Redirect=%2Ffeed")),
      "/login?redirect=%2Ffeed",
    );
    expect(
      shareUriToAppLocation(Uri.parse("LIUBAN://Messages")),
      "/messages",
    );
  });

  test("host match is case-insensitive", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://LIUBAN.APP/messages")),
      "/messages",
    );
  });

  test("host match tolerates trailing dot", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app./feed")),
      "/feed",
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://www.liuban.app./post/abc"),
        shareLinkOriginOverride: "https://liuban.app",
      ),
      "/post/abc",
    );
  });

  test("liuban host matching tolerates trailing dot", () {
    expect(
      shareUriToAppLocation(Uri.parse("liuban://post./abc")),
      "/post/abc",
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://messages.")),
      "/messages",
    );
  });

  test("liuban host with invalid characters is rejected", () {
    expect(
      shareUriToAppLocation(Uri.parse("liuban://messages%0A")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://bad_host/abc")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://-post/abc")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://post-/abc")),
      isNull,
    );
    final longLabel = List.filled(64, "a").join();
    expect(
      shareUriToAppLocation(Uri.parse("liuban://$longLabel/abc")),
      isNull,
    );
    final tooLongHost = List.filled(254, "a").join();
    expect(
      shareUriToAppLocation(Uri.parse("liuban://$tooLongHost/abc")),
      isNull,
    );
  });

  test("http(s) deep links enforce expected port", () {
    expect(
      shareUriToAppLocation(
        Uri.parse("https://liuban.app:8443/feed"),
        shareLinkOriginOverride: "https://liuban.app:8443",
      ),
      "/feed",
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://liuban.app/feed"),
        shareLinkOriginOverride: "https://liuban.app:8443",
      ),
      isNull,
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://liuban.app:9443/feed"),
        shareLinkOriginOverride: "https://liuban.app:8443",
      ),
      isNull,
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://liuban.app:8443/feed"),
      ),
      isNull,
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://liuban.app/feed"),
        shareLinkOriginOverride: "https://liuban.app:443",
      ),
      "/feed",
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("http://liuban.app/feed"),
        shareLinkOriginOverride: "http://liuban.app:80",
      ),
      "/feed",
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://[::1]/feed"),
        shareLinkOriginOverride: "https://[::1]",
      ),
      "/feed",
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://[::1]/feed"),
        shareLinkOriginOverride: "https://[0:0:0:0:0:0:0:1]",
      ),
      "/feed",
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://[::2]/feed"),
        shareLinkOriginOverride: "https://[::1]",
      ),
      isNull,
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://[2001:db8::1]/messages"),
        shareLinkOriginOverride:
            "https://[2001:0db8:0000:0000:0000:0000:0000:0001]",
      ),
      "/messages",
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://[::1]:8443/feed"),
        shareLinkOriginOverride: "https://[::1]:8443",
      ),
      "/feed",
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://[::1]:9443/feed"),
        shareLinkOriginOverride: "https://[::1]:8443",
      ),
      isNull,
    );
  });

  test("parseShareLinkOrigin accepts IPv6 origin with explicit port", () {
    final o = parseShareLinkOrigin("https://[::1]:8443/");
    expect(o.scheme, "https");
    expect(o.host, "::1");
    expect(o.port, 8443);
  });

  test("incomplete post path without id returns null", () {
    expect(shareUriToAppLocation(Uri.parse("https://liuban.app/post")), isNull);
  });

  test("path param with only spaces returns null", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/post/%20%20")),
      isNull,
    );
  });

  test("path param with control chars returns null", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/post/%0Aabc")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://post/%09abc")),
      isNull,
    );
  });

  test("overly long path param returns null", () {
    final long = List.filled(300, "x").join();
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/post/$long")),
      isNull,
    );
  });

  test("liuban dm host without peer segment returns null", () {
    expect(shareUriToAppLocation(Uri.parse("liuban://dm")), isNull);
  });

  test("liuban dynamic hosts reject extra trailing segments", () {
    expect(shareUriToAppLocation(Uri.parse("liuban://post/a/b")), isNull);
    expect(shareUriToAppLocation(Uri.parse("liuban://promotion/9/x")), isNull);
    expect(shareUriToAppLocation(Uri.parse("liuban://dm/u1/x")), isNull);
  });

  test("malformed percent-encoding in path segment fails safely", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/post/%E0%A4%A")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://post/%E0%A4%A")),
      isNull,
    );
  });

  test("apex incoming url matches when configured origin is www", () {
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/post/abc"),
      shareLinkOriginOverride: "https://www.liuban.app",
    );
    expect(loc, "/post/abc");
  });

  test("www incoming still matches when configured origin is www", () {
    final loc = shareUriToAppLocation(
      Uri.parse("https://www.liuban.app/feed"),
      shareLinkOriginOverride: "https://www.liuban.app/",
    );
    expect(loc, "/feed");
  });

  test("oversized uri is rejected early", () {
    final huge = List.filled(9000, "x").join();
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/feed?x=$huge"),
    );
    expect(loc, isNull);
  });

  test("too many query keys are rejected early", () {
    final query = List.generate(40, (i) => "k$i=v").join("&");
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/feed?$query"),
    );
    expect(loc, isNull);
  });

  test("too many query pairs are rejected early", () {
    final query = List.generate(17, (i) => "x$i=a&x$i=b&x$i=c&x$i=d").join("&");
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/feed?$query"),
    );
    expect(loc, isNull);
  });

  test("too many path segments are rejected early", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/a/b/c/d/e/f/g/h/i")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://post/a/b/c/d/e/f/g/h/i")),
      isNull,
    );
  });

  test("too long path segment is rejected early", () {
    final longSeg = List.filled(300, "a").join();
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/$longSeg")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("liuban://post/$longSeg")),
      isNull,
    );
  });

  test("too long query key is rejected early", () {
    final longKey = List.filled(140, "k").join();
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/feed?$longKey=v"),
    );
    expect(loc, isNull);
  });

  test("too long query value is rejected early", () {
    final longVal = List.filled(700, "v").join();
    final loc = shareUriToAppLocation(
      Uri.parse("https://liuban.app/feed?x=$longVal"),
    );
    expect(loc, isNull);
  });

  test("query key or value with control chars is rejected early", () {
    expect(
      shareUriToAppLocation(
        Uri.parse("https://liuban.app/feed?x=%0Aabc"),
      ),
      isNull,
    );
    expect(
      shareUriToAppLocation(
        Uri.parse("https://liuban.app/feed?%0Akey=v"),
      ),
      isNull,
    );
  });

  test("single-segment path with control chars is rejected", () {
    expect(
      shareUriToAppLocation(Uri.parse("https://liuban.app/feed%0A")),
      isNull,
    );
    expect(
      shareUriToAppLocation(Uri.parse("LIUBAN://messages%09")),
      isNull,
    );
  });
}
