import 'package:drift/drift.dart';

/// Cached positions, one row per (source, symbol).
@DataClassName('PositionRow')
class PositionsCache extends Table {
  TextColumn get sourceId => text()();
  TextColumn get symbol => text()();
  TextColumn get name => text()();
  TextColumn get assetClass => text()();
  RealColumn get quantity => real()();
  RealColumn get avgCost => real()();
  RealColumn get currentPrice => real()();
  TextColumn get currency => text()();
  RealColumn get marketValue => real()();
  RealColumn get unrealizedPnl => real()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {sourceId, symbol};
}

/// Cached transactions; primary key is the broker-supplied transaction id.
@DataClassName('TransactionRow')
class TransactionsCache extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text()();
  DateTimeColumn get time => dateTime()();
  TextColumn get type => text()();
  TextColumn get symbol => text()();
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  TextColumn get currency => text()();
  RealColumn get fee => real()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// FX rates, one row per (base, quote).
@DataClassName('FxRateRow')
class FxRatesCache extends Table {
  TextColumn get base => text()();
  TextColumn get quote => text()();
  RealColumn get rate => real()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {base, quote};
}

/// Most-recent quote per symbol.
@DataClassName('QuoteRow')
class QuotesCache extends Table {
  TextColumn get symbol => text()();
  RealColumn get price => real()();
  TextColumn get currency => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {symbol};
}

/// Lightweight metadata about user-configured connections.
///
/// Authoritative copy lives in Firestore; this is a local cache so the
/// dashboard can render instantly while a refresh is in flight.
@DataClassName('ConnectionMetaRow')
class ConnectionsMeta extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get label => text()();
  TextColumn get status => text()();
  TextColumn get credentialMode => text()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Tiny user-preferences cache for fast cold-start render. Authoritative
/// copy is in Firestore but we don't want to wait on it.
@DataClassName('UserPrefRow')
class UserPrefs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
