import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/logger.dart';

List<ProviderObserver> buildProviderObservers({
  AppLogger? logger,
  bool releaseMode = kReleaseMode,
}) {
  if (releaseMode) return const <ProviderObserver>[];
  return <ProviderObserver>[
    RiverpodLoggingObserver(logger ?? AppLogger.instance),
  ];
}

class RiverpodLoggingObserver extends ProviderObserver {
  RiverpodLoggingObserver(this._logger);

  final AppLogger _logger;

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    if (newValue is AsyncError<Object?>) {
      _logger.warning(
        'Provider error: $name',
        name: 'riverpod',
        error: newValue.error,
        stackTrace: newValue.stackTrace,
      );
      return;
    }
    _logger.debug('Provider update: $name', name: 'riverpod');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    _logger.error(
      'Provider failed: $name',
      name: 'riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
