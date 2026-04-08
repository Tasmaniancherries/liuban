import "package:flutter/material.dart";

/// 使用者選擇的介面語言（[system] 時交由裝置 locale 解析 [supportedLocales]）。
enum AppLocalePreference {
  system,
  zhHK,
  zhTW,
  english;

  String get persistenceKey => switch (this) {
    AppLocalePreference.system => "system",
    AppLocalePreference.zhHK => "zh_HK",
    AppLocalePreference.zhTW => "zh_TW",
    AppLocalePreference.english => "en",
  };

  /// `null` 表示不覆寫，由裝置 locale 與 [supportedLocales] 解析。
  Locale? get materialLocale => switch (this) {
    AppLocalePreference.system => null,
    AppLocalePreference.zhHK => const Locale.fromSubtags(
      languageCode: "zh",
      scriptCode: "Hant",
      countryCode: "HK",
    ),
    AppLocalePreference.zhTW => const Locale.fromSubtags(
      languageCode: "zh",
      scriptCode: "Hant",
      countryCode: "TW",
    ),
    AppLocalePreference.english => const Locale("en"),
  };

  static AppLocalePreference parseStored(String? raw) => switch (raw) {
    "zh_HK" => AppLocalePreference.zhHK,
    "zh_TW" => AppLocalePreference.zhTW,
    "en" => AppLocalePreference.english,
    _ => AppLocalePreference.system,
  };
}
