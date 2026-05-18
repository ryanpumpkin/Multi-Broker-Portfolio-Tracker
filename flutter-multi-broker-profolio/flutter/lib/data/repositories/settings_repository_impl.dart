import 'dart:async';

import '../../domain/domain.dart';
import '../local/database/app_database.dart';
import '../remote/firestore_client/firestore_client.dart';

/// Settings live in two places:
/// - Drift `userPrefs` for instant cold-start render (client-wins until
///   the next sync, per detailed-design §3.4).
/// - Firestore for cross-device sync.
///
/// Reads return the local value; writes update both stores. A change-on-
/// write stream lets the presentation layer react.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required this.db,
    required this.firestore,
    required this.userId,
  });

  final AppDatabase db;
  final FirestoreClient firestore;
  final String userId;

  static const String _kTheme = 'theme';
  static const String _kLocale = 'locale';
  static const String _kBase = 'baseCurrency';
  static const String _kCurMode = 'currencyMode';

  final StreamController<void> _ctrl = StreamController<void>.broadcast();

  Future<void> dispose() => _ctrl.close();

  void _notify() => _ctrl.add(null);

  Future<void> _writeBoth(String key, String value) async {
    await db.setPref(key, value);
    try {
      await firestore.setUserSettings(userId, <String, dynamic>{key: value});
    } catch (_) {
      // Client-wins until the next sync; we keep the local write.
    }
    _notify();
  }

  @override
  Future<AppThemeMode> getThemeMode() async {
    final v = await db.getPref(_kTheme);
    return AppThemeMode.values.firstWhere(
      (m) => m.name == v,
      orElse: () => AppThemeMode.system,
    );
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) =>
      _writeBoth(_kTheme, mode.name);

  @override
  Future<String?> getLocale() => db.getPref(_kLocale);

  @override
  Future<void> setLocale(String? locale) async {
    if (locale == null) {
      await db.deletePref(_kLocale);
      try {
        await firestore.setUserSettings(userId, <String, dynamic>{_kLocale: null});
      } catch (_) {/* ignore */}
      _notify();
      return;
    }
    await _writeBoth(_kLocale, locale);
  }

  @override
  Future<String> getBaseCurrency() async =>
      (await db.getPref(_kBase)) ?? 'USD';

  @override
  Future<void> setBaseCurrency(String currency) =>
      _writeBoth(_kBase, currency);

  @override
  Future<CurrencyMode> getCurrencyMode() async {
    final v = await db.getPref(_kCurMode);
    return CurrencyMode.values.firstWhere(
      (m) => m.name == v,
      orElse: () => CurrencyMode.base,
    );
  }

  @override
  Future<void> setCurrencyMode(CurrencyMode mode) =>
      _writeBoth(_kCurMode, mode.name);

  @override
  Stream<void> watchChanges() => _ctrl.stream;
}
