import "package:flutter_test/flutter_test.dart";
import "package:liuban/core/locale/app_locale_preference.dart";
import "package:liuban/core/network/auth_session_tokens.dart";
import "package:liuban/core/persistence/app_persistence.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  test("readAppLocalePreference defaults to system when key absent", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final p = AppPersistence(prefs, AuthSessionTokens(), "test_guest");
    expect(p.readAppLocalePreference(), AppLocalePreference.system);
  });

  test("readAppLocalePreference respects stored values", () async {
    SharedPreferences.setMockInitialValues({"liuban_app_locale": "system"});
    final prefs = await SharedPreferences.getInstance();
    final p = AppPersistence(prefs, AuthSessionTokens(), "test_guest");
    expect(p.readAppLocalePreference(), AppLocalePreference.system);

    await p.writeAppLocalePreference(AppLocalePreference.english);
    expect(p.readAppLocalePreference(), AppLocalePreference.english);
  });

  test("readFeedTabIndex defaults to 0", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final p = AppPersistence(prefs, AuthSessionTokens(), "test_guest");
    expect(p.readFeedTabIndex(), 0);
  });

  test("readFeedTabIndex clamps and writeFeedTabIndex", () async {
    SharedPreferences.setMockInitialValues({"liuban_feed_tab_index": 99});
    final prefs = await SharedPreferences.getInstance();
    final p = AppPersistence(prefs, AuthSessionTokens(), "test_guest");
    expect(p.readFeedTabIndex(), 2);
    await p.writeFeedTabIndex(-3);
    expect(p.readFeedTabIndex(), 0);
    await p.writeFeedTabIndex(1);
    expect(p.readFeedTabIndex(), 1);
  });

  test("readMessagesTabIndex defaults to 0", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final p = AppPersistence(prefs, AuthSessionTokens(), "test_guest");
    expect(p.readMessagesTabIndex(), 0);
  });

  test("readMessagesTabIndex clamps and writeMessagesTabIndex", () async {
    SharedPreferences.setMockInitialValues({"liuban_messages_tab_index": 9});
    final prefs = await SharedPreferences.getInstance();
    final p = AppPersistence(prefs, AuthSessionTokens(), "test_guest");
    expect(p.readMessagesTabIndex(), 1);
    await p.writeMessagesTabIndex(-1);
    expect(p.readMessagesTabIndex(), 0);
  });
}
