import 'package:flutter/widgets.dart';

/// Single source of truth for which locales the app ships with.
///
/// The list is consumed by `MaterialApp.supportedLocales` and by the locale
/// resolution logic that picks the best match for the current device.
class AppLocales {
  AppLocales._();

  static const Locale english = Locale('en');
  static const Locale chineseTraditional = Locale('zh', 'Hant');

  /// Locales that have a translated `.arb` file.
  static const List<Locale> supported = <Locale>[
    english,
    chineseTraditional,
  ];

  /// Default fallback locale when no device locale matches.
  static const Locale fallback = english;

  /// Resolves the best supported locale for [device]. If [device] is null or
  /// no match is found, returns [fallback].
  ///
  /// The matching rules, in order:
  ///   1. Exact languageCode + scriptCode/countryCode match
  ///   2. languageCode-only match
  ///   3. [fallback]
  static Locale resolve(Locale? device) {
    if (device == null) return fallback;
    for (final l in supported) {
      if (l.languageCode == device.languageCode &&
          (l.countryCode ?? '') == (device.countryCode ?? '') &&
          (l.scriptCode ?? '') == (device.scriptCode ?? '')) {
        return l;
      }
    }
    for (final l in supported) {
      if (l.languageCode == device.languageCode) return l;
    }
    return fallback;
  }
}
