import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'repository_providers.dart';

final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.locale,
    required this.baseCurrency,
    required this.currencyMode,
  });

  final AppThemeMode themeMode;
  final String? locale;
  final String baseCurrency;
  final CurrencyMode currencyMode;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    Object? locale = _unset,
    String? baseCurrency,
    CurrencyMode? currencyMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: identical(locale, _unset) ? this.locale : locale as String?,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      currencyMode: currencyMode ?? this.currencyMode,
    );
  }

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          locale == other.locale &&
          baseCurrency == other.baseCurrency &&
          currencyMode == other.currencyMode;

  @override
  int get hashCode =>
      Object.hash(themeMode, locale, baseCurrency, currencyMode);
}

class SettingsController extends AsyncNotifier<AppSettings> {
  StreamSubscription<void>? _subscription;

  @override
  Future<AppSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    _subscription?.cancel();
    _subscription = repo.watchChanges().listen((_) {
      unawaited(refresh());
    });
    ref.onDispose(() => _subscription?.cancel());
    return _loadFromRepository(repo);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadFromRepository(ref.read(settingsRepositoryProvider)),
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(themeMode: mode));
    } else {
      await refresh();
    }
  }

  Future<void> setLocale(String? locale) async {
    await ref.read(settingsRepositoryProvider).setLocale(locale);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(locale: locale));
    } else {
      await refresh();
    }
  }

  Future<void> setBaseCurrency(String currency) async {
    await ref.read(settingsRepositoryProvider).setBaseCurrency(currency);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(baseCurrency: currency));
    } else {
      await refresh();
    }
  }

  Future<void> setCurrencyMode(CurrencyMode mode) async {
    await ref.read(settingsRepositoryProvider).setCurrencyMode(mode);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(currencyMode: mode));
    } else {
      await refresh();
    }
  }

  Future<AppSettings> _loadFromRepository(SettingsRepository repo) async {
    final themeMode = await repo.getThemeMode();
    final locale = await repo.getLocale();
    final baseCurrency = await repo.getBaseCurrency();
    final currencyMode = await repo.getCurrencyMode();
    return AppSettings(
      themeMode: themeMode,
      locale: locale,
      baseCurrency: baseCurrency,
      currencyMode: currencyMode,
    );
  }
}
