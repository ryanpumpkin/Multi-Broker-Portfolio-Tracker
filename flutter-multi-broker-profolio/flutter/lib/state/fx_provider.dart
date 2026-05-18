import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'repository_providers.dart';

final fxProvider = NotifierProvider<FxController, FxState>(FxController.new);

class FxPair {
  const FxPair({required this.base, required this.quote});

  final String base;
  final String quote;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FxPair &&
          runtimeType == other.runtimeType &&
          base == other.base &&
          quote == other.quote;

  @override
  int get hashCode => Object.hash(base, quote);

  @override
  String toString() => '$base/$quote';
}

class FxState {
  const FxState({required this.cache});

  final Map<FxPair, FxRate?> cache;

  FxRate? rateFor(String base, String quote) =>
      cache[FxPair(base: base, quote: quote)];
}

class FxController extends Notifier<FxState> {
  StreamSubscription<FxRate>? _subscription;
  Set<FxPair> _watchedPairs = const <FxPair>{};

  @override
  FxState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const FxState(cache: <FxPair, FxRate?>{});
  }

  Future<FxRate?> lookup({required String base, required String quote}) async {
    final key = FxPair(base: base, quote: quote);
    if (state.cache.containsKey(key)) {
      return state.cache[key];
    }
    final rate =
        await ref.read(fxRepositoryProvider).getRate(base: base, quote: quote);
    _put(key, rate);
    if (rate != null) {
      final inverse = rate.inverse();
      _put(FxPair(base: inverse.base, quote: inverse.quote), inverse);
    }
    return rate;
  }

  void watchPairs(Iterable<FxPair> pairs) {
    _watchedPairs = <FxPair>{..._watchedPairs, ...pairs};
    _subscription?.cancel();
    final records = _watchedPairs
        .map((pair) => (base: pair.base, quote: pair.quote))
        .toList(growable: false);
    _subscription =
        ref.read(fxRepositoryProvider).watchRates(records).listen((rate) {
      _put(FxPair(base: rate.base, quote: rate.quote), rate);
      final inverse = rate.inverse();
      _put(FxPair(base: inverse.base, quote: inverse.quote), inverse);
    });
  }

  void clearCache() {
    state = const FxState(cache: <FxPair, FxRate?>{});
  }

  void _put(FxPair key, FxRate? rate) {
    state = FxState(cache: <FxPair, FxRate?>{...state.cache, key: rate});
  }
}
