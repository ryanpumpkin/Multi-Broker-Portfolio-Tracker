import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/logging/logger.dart';

void main() {
  group('AppLogger', () {
    setUp(() {
      AppLogger.instance.init();
      AppLogger.instance.clearBuffer();
      AppLogger.instance.clearSinks();
    });

    test('emits debug/info/warning/error to subscribed sinks', () {
      final received = <AppLogRecord>[];
      AppLogger.instance.addSink(received.add);

      AppLogger.instance.debug('d');
      AppLogger.instance.info('i', name: 'svc');
      AppLogger.instance.warning('w', error: Exception('e1'));
      AppLogger.instance.error('e',
          error: StateError('boom'), stackTrace: StackTrace.current,);

      expect(received.map((r) => r.level), <AppLogLevel>[
        AppLogLevel.debug,
        AppLogLevel.info,
        AppLogLevel.warning,
        AppLogLevel.error,
      ]);
      expect(received[1].loggerName, 'svc');
      expect(received[2].error, isA<Exception>());
      expect(received[3].stackTrace, isNotNull);
    });

    test('buffers records in memory for the debug viewer', () {
      AppLogger.instance.info('hello');
      expect(AppLogger.instance.buffered, hasLength(1));
      expect(AppLogger.instance.buffered.single.message, 'hello');
      expect(AppLogger.instance.buffered.single.toString(),
          contains('INFO'),);
    });

    test('caps the in-memory buffer at bufferLimit', () {
      for (var i = 0; i < AppLogger.bufferLimit + 50; i++) {
        AppLogger.instance.info('msg-$i');
      }
      expect(AppLogger.instance.buffered.length, AppLogger.bufferLimit);
      expect(AppLogger.instance.buffered.last.message,
          'msg-${AppLogger.bufferLimit + 49}',);
    });

    test('removeSink stops further delivery', () {
      final received = <AppLogRecord>[];
      void sink(AppLogRecord r) => received.add(r);
      AppLogger.instance.addSink(sink);
      AppLogger.instance.info('one');
      expect(AppLogger.instance.removeSink(sink), isTrue);
      AppLogger.instance.info('two');
      expect(received, hasLength(1));
    });

    test('init is idempotent and accepts a later sink', () {
      final received = <AppLogRecord>[];
      AppLogger.instance.init();
      AppLogger.instance.init(crashlyticsSink: received.add);
      AppLogger.instance.warning('w');
      expect(received, hasLength(1));
    });

    test('crashlyticsSink forwards only warning + error as non-fatal', () {
      final reported = <Object>[];
      final sink = crashlyticsSink(
        (error, stack, {bool fatal = false}) {
          expect(fatal, isFalse);
          reported.add(error);
        },
      );
      AppLogger.instance.addSink(sink);

      AppLogger.instance.debug('d');
      AppLogger.instance.info('i');
      AppLogger.instance.warning('w', error: 'warn-payload');
      AppLogger.instance.error('e', error: 'err-payload');

      expect(reported, <Object>['warn-payload', 'err-payload']);
    });

    test('crashlyticsSink uses message when no error is attached', () {
      final reported = <Object>[];
      final sink = crashlyticsSink(
        (error, stack, {bool fatal = false}) => reported.add(error),
      );
      AppLogger.instance.addSink(sink);
      AppLogger.instance.warning('only-message');
      expect(reported, <Object>['only-message']);
    });

    test('record toString includes timestamp, level, name and error', () {
      final r = AppLogRecord(
        level: AppLogLevel.error,
        message: 'boom',
        time: DateTime.utc(2026, 1, 2, 3, 4, 5),
        loggerName: 'svc',
        error: 'oops',
      );
      final s = r.toString();
      expect(s, contains('ERROR'));
      expect(s, contains('[svc]'));
      expect(s, contains('boom'));
      expect(s, contains('error=oops'));
      expect(s, contains('2026-01-02'));
    });
  });
}
