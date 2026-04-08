import 'package:flutter/material.dart';

/// 與 [MaterialApp.supportedLocales] 一致；單一來源避免與解析邏輯漂移。
const List<Locale> kLiubanSupportedLocales = [
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
  Locale('en'),
];

/// 裝置語言解析：簡體或無 script 的 `zh` 對到新馬／留學生常用之繁體（優先清單首項香港）。
Locale resolveLiubanLocale(Locale? locale, Iterable<Locale> supported) {
  final list = List<Locale>.from(supported);
  if (locale == null) {
    return list.first;
  }
  for (final s in list) {
    if (s.languageCode == locale.languageCode &&
        s.scriptCode == locale.scriptCode &&
        s.countryCode == locale.countryCode) {
      return s;
    }
  }
  for (final s in list) {
    if (s.languageCode == locale.languageCode &&
        s.scriptCode == locale.scriptCode) {
      return s;
    }
  }
  for (final s in list) {
    if (s.languageCode == locale.languageCode) {
      return s;
    }
  }
  if (locale.languageCode == 'zh') {
    for (final s in list) {
      if (s.scriptCode == 'Hant') return s;
    }
  }
  return list.first;
}
