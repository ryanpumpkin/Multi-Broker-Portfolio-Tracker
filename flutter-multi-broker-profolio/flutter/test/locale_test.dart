import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/i18n/app_locales.dart';

void main() {
  group('AppLocales', () {
    test('supported list contains en and zh_Hant', () {
      expect(AppLocales.supported, contains(AppLocales.english));
      expect(AppLocales.supported, contains(AppLocales.chineseTraditional));
    });

    test('resolve picks exact match when available', () {
      expect(
        AppLocales.resolve(const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hant',),),
        AppLocales.chineseTraditional,
      );
    });

    test('resolve falls back to language-only match', () {
      // Simplified Chinese isn't directly supported; falls back to the
      // first zh entry (Traditional).
      expect(
        AppLocales.resolve(const Locale('zh', 'CN')),
        AppLocales.chineseTraditional,
      );
    });

    test('resolve returns fallback for unknown languages and null', () {
      expect(AppLocales.resolve(null), AppLocales.fallback);
      expect(AppLocales.resolve(const Locale('fr')), AppLocales.fallback);
    });

    test('resolve picks en for English variants', () {
      expect(AppLocales.resolve(const Locale('en', 'GB')),
          AppLocales.english,);
      expect(AppLocales.resolve(const Locale('en')), AppLocales.english);
    });
  });
}
