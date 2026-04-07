import "package:flutter_test/flutter_test.dart";
import "package:liuban/core/text/account_input_normalize.dart";

void main() {
  test("normalizeLeadingAtCustomId strips only leading @", () {
    expect(normalizeLeadingAtCustomId("@bob"), "bob");
    expect(normalizeLeadingAtCustomId("  @x  "), "x");
    expect(normalizeLeadingAtCustomId("noat"), "noat");
  });

  test("normalizeLoginAccount strips @ for handle-like input only", () {
    expect(normalizeLoginAccount("@alice"), "alice");
    expect(normalizeLoginAccount("me@school.hk"), "me@school.hk");
    expect(normalizeLoginAccount("@weird@"), "@weird@");
  });
}
