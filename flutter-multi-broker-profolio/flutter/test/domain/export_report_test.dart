import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

PortfolioSnapshot _snap() {
  final p = Position.computed(
    sourceId: 'lb',
    symbol: 'AAPL',
    name: 'Apple, Inc.',
    assetClass: AssetClass.stock,
    quantity: 10,
    avgCost: 100,
    currentPrice: 150,
    currency: 'USD',
  );
  return PortfolioSnapshot(
    asOf: DateTime.utc(2026, 1, 1),
    baseCurrency: 'USD',
    positions: [p],
    cashBalances: const [],
    totalsBySource: const {'lb': 1500},
    totalsByCurrency: const {'USD': 1500},
    totalBaseValue: 1500,
    totalUnrealizedPnlBase: 500,
  );
}

List<Transaction> _txs() => [
      Transaction(
        id: 't1',
        sourceId: 'lb',
        time: DateTime.utc(2026, 1, 1),
        type: TransactionType.buy,
        symbol: 'AAPL',
        quantity: 10,
        price: 100,
        currency: 'USD',
        fee: 1,
      ),
      Transaction(
        id: 't2,with-comma',
        sourceId: 'lb',
        time: DateTime.utc(2026, 1, 2),
        type: TransactionType.sell,
        symbol: 'AAPL',
        quantity: 5,
        price: 150,
        currency: 'USD',
        fee: 0,
      ),
    ];

void main() {
  const ex = ExportReport();
  final now = DateTime.utc(2026, 5, 18, 12);

  group('CSV', () {
    test('portfolio CSV has header + position row, comma in name is quoted', () {
      final r = ex(
        format: ReportFormat.csv,
        scope: ReportScope.portfolio,
        snapshot: _snap(),
        now: now,
      );
      expect(r.mimeType, 'text/csv');
      expect(r.filename, contains('portfolio'));
      expect(r.filename, endsWith('.csv'));
      final text = utf8.decode(r.bytes);
      expect(text, startsWith('source_id,symbol,'));
      expect(text, contains('"Apple, Inc."'));
      expect(text, contains('AAPL'));
      expect(text, contains('1500.0'));
    });

    test('portfolio CSV with null snapshot is header-only', () {
      final r = ex(
        format: ReportFormat.csv,
        scope: ReportScope.portfolio,
        now: now,
      );
      final text = utf8.decode(r.bytes);
      expect(text.split('\n').where((l) => l.isNotEmpty), hasLength(1));
    });

    test('transactions CSV escapes commas and emits cash_impact column', () {
      final r = ex(
        format: ReportFormat.csv,
        scope: ReportScope.transactions,
        transactions: _txs(),
        now: now,
      );
      final text = utf8.decode(r.bytes);
      expect(text, contains('id,source_id,'));
      expect(text, contains('"t2,with-comma"'));
      expect(text, contains('-1001.0')); // buy cash impact
      expect(text, contains('750.0')); // sell cash impact
    });

    test('transactions CSV defaults to empty list', () {
      final r = ex(
        format: ReportFormat.csv,
        scope: ReportScope.transactions,
        now: now,
      );
      expect(utf8.decode(r.bytes), startsWith('id,source_id'));
    });
  });

  group('PDF', () {
    test('produces a parseable minimal PDF', () {
      final r = ex(
        format: ReportFormat.pdf,
        scope: ReportScope.portfolio,
        snapshot: _snap(),
        now: now,
      );
      expect(r.mimeType, 'application/pdf');
      expect(r.filename, endsWith('.pdf'));
      // Decode as latin-1 so we can search header/footer bytes.
      final bytes = String.fromCharCodes(r.bytes);
      expect(bytes, startsWith('%PDF-1.4'));
      expect(bytes, contains('%%EOF'));
      expect(bytes, contains('/Type /Catalog'));
      expect(bytes, contains('xref'));
    });

    test('PDF for transactions scope works with empty list', () {
      final r = ex(
        format: ReportFormat.pdf,
        scope: ReportScope.transactions,
        now: now,
      );
      expect(r.bytes, isNotEmpty);
      expect(r.filename, contains('transactions'));
    });

    test('PDF escapes parentheses and backslashes in content', () {
      final tx = Transaction(
        id: r'edge (case) \ test',
        sourceId: 'lb',
        time: DateTime.utc(2026),
        type: TransactionType.buy,
        symbol: 'A',
        quantity: 1,
        price: 1,
        currency: 'USD',
        fee: 0,
      );
      final r = ex(
        format: ReportFormat.pdf,
        scope: ReportScope.transactions,
        transactions: [tx],
        now: now,
      );
      final bytes = String.fromCharCodes(r.bytes);
      // Escaped sequences must be present, raw paren-pair must NOT confuse the PDF parser.
      expect(bytes, contains(r'\('));
      expect(bytes, contains(r'\)'));
      expect(bytes, contains(r'\\'));
    });
  });

  test('uses DateTime.now() when none supplied', () {
    final r = ex(
      format: ReportFormat.csv,
      scope: ReportScope.portfolio,
      snapshot: _snap(),
    );
    expect(r.filename, startsWith('report-portfolio-'));
  });
}
