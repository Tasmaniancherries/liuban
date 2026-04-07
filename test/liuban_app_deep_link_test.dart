import "package:flutter_test/flutter_test.dart";
import "package:liuban/app/liuban_app.dart";

void main() {
  test("looksLikeSchemeRelativeAuthority detects host-like authority", () {
    expect(looksLikeSchemeRelativeAuthority("liuban.app"), isTrue);
    expect(looksLikeSchemeRelativeAuthority("localhost"), isTrue);
    expect(looksLikeSchemeRelativeAuthority("127.0.0.1:8080"), isTrue);
    expect(looksLikeSchemeRelativeAuthority("user@liuban"), isTrue);
  });

  test("looksLikeSchemeRelativeAuthority keeps app-style segment false", () {
    expect(looksLikeSchemeRelativeAuthority("feed"), isFalse);
  });

  test("isValidComparableAuthorityHost accepts valid hosts", () {
    expect(isValidComparableAuthorityHost("liuban.app"), isTrue);
    expect(isValidComparableAuthorityHost("localhost"), isTrue);
    expect(isValidComparableAuthorityHost("api-v2.liuban.app"), isTrue);
    expect(isValidComparableAuthorityHost("LIUBAN.APP."), isTrue);
    expect(isValidComparableAuthorityHost("::1"), isTrue);
    expect(isValidComparableAuthorityHost("[::1]"), isTrue);
    expect(isValidComparableAuthorityHost("2001:db8::1"), isTrue);
    expect(
      isValidComparableAuthorityHost("2001:0db8:85a3:0000:0000:8a2e:0370:7334"),
      isTrue,
    );
  });

  test("isValidComparableAuthorityHost rejects invalid hosts", () {
    expect(isValidComparableAuthorityHost(""), isFalse);
    expect(isValidComparableAuthorityHost("bad host.com"), isFalse);
    expect(isValidComparableAuthorityHost("bad_host.com"), isFalse);
    expect(isValidComparableAuthorityHost("-bad.liuban.app"), isFalse);
    expect(isValidComparableAuthorityHost("bad-.liuban.app"), isFalse);
    expect(isValidComparableAuthorityHost("liuban..app"), isFalse);
    expect(isValidComparableAuthorityHost(":::1"), isFalse);
    expect(isValidComparableAuthorityHost("a:b"), isFalse);
    expect(isValidComparableAuthorityHost(":"), isFalse);
    expect(isValidComparableAuthorityHost("2001:db8::1::1"), isFalse);
    expect(isValidComparableAuthorityHost("2001:db8:zzzz::1"), isFalse);
    expect(isValidComparableAuthorityHost("[2001:db8::1"), isFalse);
  });

  test("normalizeAppLocationForDeepLinkCompare falls back for invalid host", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//bad host.com/feed?x=1"),
      "/bad%20host.com/feed?x=1",
    );
    expect(
      normalizeAppLocationForDeepLinkCompare("//-bad.liuban.app/feed"),
      "/-bad.liuban.app/feed",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare accepts trailing-dot host", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//liuban.app./feed?x=1"),
      "/feed?x=1",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare accepts IPv6 authority host", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//[::1]/feed?x=1"),
      "/feed?x=1",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare strips scheme and host", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("https://liuban.app/feed?x=1#frag"),
      "/feed?x=1",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare defaults to root for host-only URI",
      () {
    expect(
      normalizeAppLocationForDeepLinkCompare("https://liuban.app"),
      "/",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare handles non-http URI schemes", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("wss://liuban.app/messages?x=1"),
      "/messages?x=1",
    );
  });

  test(
      "normalizeAppLocationForDeepLinkCompare normalizes scheme-only URI path shape",
      () {
    expect(
      normalizeAppLocationForDeepLinkCompare("mailto:foo@bar.com"),
      "/foo@bar.com",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare parses scheme-relative host URI",
      () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//liuban.app/feed?x=1"),
      "/feed?x=1",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare keeps app-style //path", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//feed///"),
      "/feed",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare parses //localhost as authority",
      () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//localhost/feed?x=1"),
      "/feed?x=1",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare parses //userinfo@authority", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//user@liuban.app/feed?x=1"),
      "/feed?x=1",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare host-only localhost to root", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//localhost"),
      "/",
    );
  });

  test(
      "normalizeAppLocationForDeepLinkCompare falls back when authority has no host",
      () {
    expect(
      normalizeAppLocationForDeepLinkCompare("//:8080/feed"),
      "/:8080/feed",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare keeps relative location", () {
    expect(normalizeAppLocationForDeepLinkCompare("/messages"), "/messages");
  });

  test("normalizeAppLocationForDeepLinkCompare adds leading slash to raw path",
      () {
    expect(
      normalizeAppLocationForDeepLinkCompare("feed?x=1"),
      "/feed?x=1",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare normalizes query-only input", () {
    expect(
      normalizeAppLocationForDeepLinkCompare("?x=1&b=2"),
      "/?b=2&x=1",
    );
  });

  test("normalizeAppLocationForDeepLinkCompare maps fragment-only input to root",
      () {
    expect(
      normalizeAppLocationForDeepLinkCompare("#top"),
      "/",
    );
  });

  test("isSameAppLocationForDeepLink matches normalized equivalent paths", () {
    expect(
      isSameAppLocationForDeepLink(
        currentLocation: "//feed///",
        targetLocation: "/feed",
      ),
      isTrue,
    );
  });

  test("isSameAppLocationForDeepLink matches normalized query ordering", () {
    expect(
      isSameAppLocationForDeepLink(
        currentLocation: "/login?b=2&a=1",
        targetLocation: "/login?a=1&b=2",
      ),
      isTrue,
    );
  });

  test("isSameAppLocationForDeepLink normalizes repeated query values", () {
    expect(
      isSameAppLocationForDeepLink(
        currentLocation: "/feed?x=2&x=1",
        targetLocation: "/feed?x=1&x=2",
      ),
      isTrue,
    );
  });

  test("isSameAppLocationForDeepLink ignores fragment differences", () {
    expect(
      isSameAppLocationForDeepLink(
        currentLocation: "/feed?x=1#top",
        targetLocation: "/feed?x=1",
      ),
      isTrue,
    );
  });

  test("isSameAppLocationForDeepLink returns false for different route", () {
    expect(
      isSameAppLocationForDeepLink(
        currentLocation: "/feed",
        targetLocation: "/messages",
      ),
      isFalse,
    );
  });

  test("isSameAppLocationForDeepLink matches absolute current URI", () {
    expect(
      isSameAppLocationForDeepLink(
        currentLocation: "https://liuban.app/feed?x=1#top",
        targetLocation: "/feed?x=1",
      ),
      isTrue,
    );
  });

  test("isSameAppLocationForDeepLink matches missing-leading-slash variant", () {
    expect(
      isSameAppLocationForDeepLink(
        currentLocation: "feed?x=1",
        targetLocation: "/feed?x=1",
      ),
      isTrue,
    );
  });

  test("isWithinDeepLinkDedupWindow handles forward time within boundary", () {
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 2000, lastMs: 1000, windowMs: 1500),
      isTrue,
    );
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 2500, lastMs: 1000, windowMs: 1500),
      isFalse,
    );
  });

  test("isWithinDeepLinkDedupWindow handles small clock rollback", () {
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 995, lastMs: 1000, windowMs: 1500),
      isTrue,
    );
    expect(
      isWithinDeepLinkDedupWindow(nowMs: -600, lastMs: 1000, windowMs: 1500),
      isFalse,
    );
  });

  test("isWithinDeepLinkDedupWindow excludes exact window boundary", () {
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 2500, lastMs: 1000, windowMs: 1500),
      isFalse,
    );
    expect(
      isWithinDeepLinkDedupWindow(nowMs: -500, lastMs: 1000, windowMs: 1500),
      isFalse,
    );
  });

  test("isWithinDeepLinkDedupWindow treats same timestamp as within window", () {
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 1000, lastMs: 1000, windowMs: 1500),
      isTrue,
    );
  });

  test("isWithinDeepLinkDedupWindow honors minimal positive window", () {
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 1000, lastMs: 1000, windowMs: 1),
      isTrue,
    );
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 1001, lastMs: 1000, windowMs: 1),
      isFalse,
    );
  });

  test("isWithinDeepLinkDedupWindow returns false when window is non-positive",
      () {
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 1001, lastMs: 1000, windowMs: 0),
      isFalse,
    );
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 999, lastMs: 1000, windowMs: -1),
      isFalse,
    );
  });

  test("isWithinDeepLinkDedupWindow returns false when last timestamp invalid",
      () {
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 1000, lastMs: 0, windowMs: 1500),
      isFalse,
    );
    expect(
      isWithinDeepLinkDedupWindow(nowMs: 1000, lastMs: -10, windowMs: 1500),
      isFalse,
    );
  });

  test("buildDeepLinkDedupSignature keeps short input unchanged", () {
    expect(
      buildDeepLinkDedupSignature("/feed?x=1", maxChars: 1024),
      "/feed?x=1",
    );
  });

  test("buildDeepLinkDedupSignature clamps long input to configured max", () {
    final longLoc = "/feed?q=${"a" * 5000}";
    final sig = buildDeepLinkDedupSignature(longLoc, maxChars: 64);
    expect(sig.length, 64);
    expect(sig.contains("..."), isTrue);
    expect(RegExp(r"#[0-9a-f]{8}$").hasMatch(sig), isTrue);
  });

  test("buildDeepLinkDedupSignature differs for different long inputs", () {
    final sigA = buildDeepLinkDedupSignature("/feed?q=${"a" * 5000}", maxChars: 64);
    final sigB = buildDeepLinkDedupSignature("/feed?q=${"b" * 5000}", maxChars: 64);
    expect(sigA, isNot(sigB));
  });

  test("buildDeepLinkDedupSignature is deterministic across calls", () {
    final input = "/feed?q=${"x" * 5000}";
    final sig1 = buildDeepLinkDedupSignature(input, maxChars: 64);
    final sig2 = buildDeepLinkDedupSignature(input, maxChars: 64);
    expect(sig1, sig2);
  });

  test("stableFnv1a32 matches known standard vector", () {
    expect(stableFnv1a32("hello"), int.parse("4f9f2cab", radix: 16));
  });

  test("stableFnv1a32 stays deterministic for unicode input", () {
    final input = "留伴🙂";
    final hash1 = stableFnv1a32(input);
    final hash2 = stableFnv1a32(input);
    expect(hash1, hash2);
    expect(hash1.toRadixString(16).padLeft(8, "0"), "bfa6bf1e");
  });

  test("buildDeepLinkDedupSignature returns empty when maxChars non-positive",
      () {
    expect(buildDeepLinkDedupSignature("/feed?x=1", maxChars: 0), "");
    expect(buildDeepLinkDedupSignature("/feed?x=1", maxChars: -1), "");
  });

  test("buildDeepLinkDedupSignature uses prefix-only mode for tiny maxChars", () {
    final sig = buildDeepLinkDedupSignature("/feed?q=${"a" * 100}", maxChars: 8);
    expect(sig.length, 8);
    expect(sig, "/feed?q=");
  });
}
