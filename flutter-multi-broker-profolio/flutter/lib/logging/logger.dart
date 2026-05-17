import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as pkg;

/// Severity for an [AppLogRecord]. Mirrors the levels we actually use; the
/// underlying `package:logging` levels are richer but flattening simplifies
/// downstream forwarding.
enum AppLogLevel { debug, info, warning, error }

/// A single immutable log record captured by [AppLogger].
@immutable
class AppLogRecord {
  const AppLogRecord({
    required this.level,
    required this.message,
    required this.time,
    this.loggerName,
    this.error,
    this.stackTrace,
  });

  final AppLogLevel level;
  final String message;
  final DateTime time;
  final String? loggerName;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final lvl = level.name.toUpperCase();
    final ts = time.toIso8601String();
    final name = loggerName == null ? '' : ' [$loggerName]';
    final err = error == null ? '' : ' error=$error';
    return '[$ts] $lvl$name $message$err';
  }
}

/// Signature for a sink that receives every log record emitted by
/// [AppLogger]. The default Crashlytics adapter is supplied at bootstrap.
typedef AppLogSink = void Function(AppLogRecord record);

/// Structured logger used throughout the app.
///
/// Wraps `package:logging` so the rest of the app does not depend on it
/// directly. Records can be subscribed to (e.g. for an in-app debug viewer)
/// and a separate [crashlyticsSink] can be installed to forward warnings
/// and errors to Crashlytics. The default sink is a no-op so unit tests
/// don't need Firebase.
class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;

  final pkg.Logger _root = pkg.Logger.root;
  final List<AppLogSink> _sinks = <AppLogSink>[];
  final List<AppLogRecord> _buffer = <AppLogRecord>[];

  /// Maximum number of records retained in memory for the debug viewer.
  static const int bufferLimit = 500;

  bool _initialized = false;

  /// Initializes the underlying logger. Idempotent; safe to call from tests.
  ///
  /// In debug mode all records are kept; in release builds only `info` and
  /// above are processed to avoid noisy output.
  void init({AppLogSink? crashlyticsSink}) {
    if (_initialized) {
      if (crashlyticsSink != null) addSink(crashlyticsSink);
      return;
    }
    _initialized = true;
    pkg.hierarchicalLoggingEnabled = false;
    _root.level = kReleaseMode ? pkg.Level.INFO : pkg.Level.ALL;
    _root.onRecord.listen(_handleRaw);
    if (crashlyticsSink != null) addSink(crashlyticsSink);
  }

  /// Subscribes [sink] to all subsequent records.
  void addSink(AppLogSink sink) => _sinks.add(sink);

  /// Unsubscribes [sink]. Returns true if it was previously registered.
  bool removeSink(AppLogSink sink) => _sinks.remove(sink);

  /// Snapshot of buffered records (most recent last).
  List<AppLogRecord> get buffered => List.unmodifiable(_buffer);

  /// Drops every record currently in the in-memory buffer. Test hook.
  @visibleForTesting
  void clearBuffer() => _buffer.clear();

  /// Removes every registered sink. Test hook.
  @visibleForTesting
  void clearSinks() => _sinks.clear();

  void debug(String message, {String? name}) =>
      _emit(AppLogLevel.debug, message, name: name);

  void info(String message, {String? name}) =>
      _emit(AppLogLevel.info, message, name: name);

  void warning(String message,
          {String? name, Object? error, StackTrace? stackTrace,}) =>
      _emit(AppLogLevel.warning, message,
          name: name, error: error, stackTrace: stackTrace,);

  void error(String message,
          {String? name, Object? error, StackTrace? stackTrace,}) =>
      _emit(AppLogLevel.error, message,
          name: name, error: error, stackTrace: stackTrace,);

  void _emit(
    AppLogLevel level,
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_initialized) init();
    final logger = name == null ? _root : pkg.Logger(name);
    logger.log(_toPkgLevel(level), message, error, stackTrace);
  }

  void _handleRaw(pkg.LogRecord r) {
    final record = AppLogRecord(
      level: _fromPkgLevel(r.level),
      message: r.message,
      time: r.time,
      loggerName: r.loggerName.isEmpty ? null : r.loggerName,
      error: r.error,
      stackTrace: r.stackTrace,
    );
    _buffer.add(record);
    if (_buffer.length > bufferLimit) {
      _buffer.removeRange(0, _buffer.length - bufferLimit);
    }
    for (final sink in _sinks) {
      sink(record);
    }
  }

  static pkg.Level _toPkgLevel(AppLogLevel l) {
    switch (l) {
      case AppLogLevel.debug:
        return pkg.Level.FINE;
      case AppLogLevel.info:
        return pkg.Level.INFO;
      case AppLogLevel.warning:
        return pkg.Level.WARNING;
      case AppLogLevel.error:
        return pkg.Level.SEVERE;
    }
  }

  static AppLogLevel _fromPkgLevel(pkg.Level l) {
    if (l >= pkg.Level.SEVERE) return AppLogLevel.error;
    if (l >= pkg.Level.WARNING) return AppLogLevel.warning;
    if (l >= pkg.Level.INFO) return AppLogLevel.info;
    return AppLogLevel.debug;
  }
}

/// Returns a sink that forwards `warning` and `error` records to the supplied
/// [recordNonFatal] callback (intended to be `FirebaseCrashlytics.instance
/// .recordError`). Kept callback-based so the logging module does not depend
/// on Firebase directly and remains unit-testable.
AppLogSink crashlyticsSink(
  void Function(Object error, StackTrace? stack, {bool fatal}) recordNonFatal,
) {
  return (AppLogRecord r) {
    if (r.level == AppLogLevel.warning || r.level == AppLogLevel.error) {
      recordNonFatal(
        r.error ?? r.message,
        r.stackTrace,
        fatal: false,
      );
    }
  };
}
