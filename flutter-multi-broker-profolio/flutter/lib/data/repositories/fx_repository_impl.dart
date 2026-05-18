import 'dart:async';

import '../../domain/domain.dart';
import '../local/database/app_database.dart';
import '../remote/backend_client/backend_client.dart';
import '../remote/backend_client/backend_exception.dart';
import 'mappers.dart';

class FxRepositoryImpl implements FxRepository {
  FxRepositoryImpl({required this.db, required this.backend});

  final AppDatabase db;
  final BackendClient backend;

  final StreamController<FxRate> _ctrl = StreamController<FxRate>.broadcast();

  Future<void> dispose() => _ctrl.close();

  @override
  Future<FxRate?> getRate({required String base, required String quote}) async {
    try {
      final raw = await backend.getFxRate(base: base, quote: quote)
          as Map<String, dynamic>;
      final rate = Mappers.fxFromJson(raw);
      await db.upsertFxRate(FxRatesCacheCompanion.insert(
        base: rate.base,
        quote: rate.quote,
        rate: rate.rate,
        timestamp: rate.timestamp,
      ),);
      _ctrl.add(rate);
      return rate;
    } on BackendException {
      final row = await db.getFxRate(base: base, quote: quote);
      if (row == null) return null;
      return FxRate(
        base: row.base,
        quote: row.quote,
        rate: row.rate,
        timestamp: row.timestamp,
      );
    }
  }

  @override
  Stream<FxRate> watchRates(List<({String base, String quote})> pairs) {
    return _ctrl.stream.where(
      (r) => pairs.any((p) => p.base == r.base && p.quote == r.quote),
    );
  }
}
