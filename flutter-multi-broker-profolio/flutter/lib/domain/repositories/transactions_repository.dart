import '../entities/transaction.dart';

/// Inclusive date range, both bounds optional.
class DateRange {
  const DateRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime t) {
    if (start != null && t.isBefore(start!)) return false;
    if (end != null && t.isAfter(end!)) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange(start: $start, end: $end)';
}

/// Read access to per-source transaction history.
abstract class TransactionsRepository {
  /// Lists transactions, optionally filtered by source and/or date range.
  Future<List<Transaction>> list({
    String? sourceId,
    DateRange? range,
  });
}
