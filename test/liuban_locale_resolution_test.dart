import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/locale/liuban_supported_locales.dart';

void main() {
  const hk = Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
    countryCode: 'HK',
  );
  const tw = Locale.fromSubtags(
    languageCode: 'zh',
    scriptCode: 'Hant',
    countryCode: 'TW',
  );

  test('resolveLiubanLocale null uses first supported', () {
    expect(resolveLiubanLocale(null, kLiubanSupportedLocales), hk);
  });

  test('resolveLiubanLocale zh_CN maps to Hant', () {
    expect(
      resolveLiubanLocale(const Locale('zh', 'CN'), kLiubanSupportedLocales),
      hk,
    );
  });

  test('resolveLiubanLocale prefers script when ambiguous', () {
    expect(resolveLiubanLocale(tw, kLiubanSupportedLocales), tw);
    expect(resolveLiubanLocale(hk, kLiubanSupportedLocales), hk);
  });

  test('resolveLiubanLocale en_US maps to en', () {
    expect(
      resolveLiubanLocale(const Locale('en', 'US'), kLiubanSupportedLocales),
      const Locale('en'),
    );
  });

  test('resolveLiubanLocale unknown language falls back to first', () {
    expect(
      resolveLiubanLocale(const Locale('ja'), kLiubanSupportedLocales),
      hk,
    );
  });
}
