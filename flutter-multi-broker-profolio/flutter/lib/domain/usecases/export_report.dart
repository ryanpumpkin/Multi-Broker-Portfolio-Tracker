import 'dart:convert';
import 'dart:typed_data';

import '../entities/portfolio_snapshot.dart';
import '../entities/transaction.dart';

/// Output format for [ExportReport].
enum ReportFormat { csv, pdf }

/// What slice of data the report covers.
enum ReportScope { portfolio, transactions }

/// Bytes plus content metadata, returned by [ExportReport].
class ReportBytes {
  const ReportBytes({
    required this.bytes,
    required this.mimeType,
    required this.filename,
  });

  final Uint8List bytes;
  final String mimeType;
  final String filename;
}

/// Builds CSV / PDF exports of the current portfolio snapshot or
/// transaction history.
///
/// PDF rendering proper requires a Flutter-side `pdf` package and is
/// implemented in the data layer. This domain use case emits a minimal,
/// valid single-page PDF document with the report text embedded, so the
/// pipeline (file save, share-sheet, etc.) can be wired and tested without
/// a Flutter dependency.
class ExportReport {
  const ExportReport();

  ReportBytes call({
    required ReportFormat format,
    required ReportScope scope,
    PortfolioSnapshot? snapshot,
    List<Transaction>? transactions,
    DateTime? now,
  }) {
    final stamp = (now ?? DateTime.now().toUtc())
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final scopeTag = scope == ReportScope.portfolio ? 'portfolio' : 'transactions';
    final extension = format == ReportFormat.csv ? 'csv' : 'pdf';
    final filename = 'report-$scopeTag-$stamp.$extension';

    final text = scope == ReportScope.portfolio
        ? _portfolioText(snapshot)
        : _transactionsText(transactions ?? const <Transaction>[]);

    switch (format) {
      case ReportFormat.csv:
        return ReportBytes(
          bytes: Uint8List.fromList(utf8.encode(text)),
          mimeType: 'text/csv',
          filename: filename,
        );
      case ReportFormat.pdf:
        return ReportBytes(
          bytes: _renderMinimalPdf(text),
          mimeType: 'application/pdf',
          filename: filename,
        );
    }
  }

  // ------ CSV bodies --------------------------------------------------

  String _portfolioText(PortfolioSnapshot? s) {
    final buf = StringBuffer();
    buf.writeln(
      'source_id,symbol,name,asset_class,quantity,avg_cost,current_price,'
      'currency,market_value,unrealized_pnl',
    );
    if (s == null) return buf.toString();
    for (final p in s.positions) {
      buf.writeln([
        _csv(p.sourceId),
        _csv(p.symbol),
        _csv(p.name),
        _csv(p.assetClass.name),
        p.quantity,
        p.avgCost,
        p.currentPrice,
        _csv(p.currency),
        p.marketValue,
        p.unrealizedPnl,
      ].join(','),);
    }
    return buf.toString();
  }

  String _transactionsText(List<Transaction> txs) {
    final buf = StringBuffer();
    buf.writeln(
      'id,source_id,time,type,symbol,quantity,price,currency,fee,cash_impact',
    );
    for (final t in txs) {
      buf.writeln([
        _csv(t.id),
        _csv(t.sourceId),
        _csv(t.time.toIso8601String()),
        _csv(t.type.name),
        _csv(t.symbol),
        t.quantity,
        t.price,
        _csv(t.currency),
        t.fee,
        t.cashImpact,
      ].join(','),);
    }
    return buf.toString();
  }

  String _csv(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  // ------ Minimal PDF -------------------------------------------------

  /// Builds a deterministic single-page PDF whose visible content is
  /// `text` (newlines preserved as separate text-show operators).
  ///
  /// This is intentionally minimal — enough to satisfy the export contract
  /// at the domain layer without dragging in a renderer dependency.
  Uint8List _renderMinimalPdf(String text) {
    final escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
    final lines = escaped.split('\n');
    final content = StringBuffer()
      ..writeln('BT')
      ..writeln('/F1 10 Tf')
      ..writeln('12 TL')
      ..writeln('36 760 Td');
    for (final line in lines) {
      content
        ..writeln('(${line.isEmpty ? ' ' : line}) Tj')
        ..writeln('T*');
    }
    content.writeln('ET');
    final stream = content.toString();

    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
          '/Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
      '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ];

    final buf = StringBuffer()..writeln('%PDF-1.4');
    final offsets = <int>[];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(buf.length);
      buf
        ..write('${i + 1} 0 obj\n')
        ..write(objects[i])
        ..write('\nendobj\n');
    }
    final xrefStart = buf.length;
    buf
      ..write('xref\n')
      ..write('0 ${objects.length + 1}\n')
      ..write('0000000000 65535 f \n');
    for (final off in offsets) {
      buf.write('${off.toString().padLeft(10, '0')} 00000 n \n');
    }
    buf
      ..write('trailer\n')
      ..write('<< /Size ${objects.length + 1} /Root 1 0 R >>\n')
      ..write('startxref\n$xrefStart\n%%EOF\n');

    return Uint8List.fromList(utf8.encode(buf.toString()));
  }
}
