/// App theme mode (mirrors Flutter's ThemeMode without importing Flutter).
enum AppThemeMode { system, light, dark }

/// How multi-currency values are displayed.
enum CurrencyMode {
  /// Convert everything into the user's chosen base currency.
  base,

  /// Show each holding in its native currency with per-currency subtotals.
  native,
}

/// User preferences. All getters/setters are async because the underlying
/// store is platform-async (SharedPreferences, secure storage, etc.).
abstract class SettingsRepository {
  Future<AppThemeMode> getThemeMode();
  Future<void> setThemeMode(AppThemeMode mode);

  /// BCP-47 locale tag (e.g. `en`, `zh-Hant`), or null = follow system.
  Future<String?> getLocale();
  Future<void> setLocale(String? locale);

  /// ISO 4217 currency code.
  Future<String> getBaseCurrency();
  Future<void> setBaseCurrency(String currency);

  Future<CurrencyMode> getCurrencyMode();
  Future<void> setCurrencyMode(CurrencyMode mode);

  /// Streams all settings as a single change-on-write event.
  Stream<void> watchChanges();
}
