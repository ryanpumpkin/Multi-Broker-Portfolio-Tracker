import 'package:drift/drift.dart';

QueryExecutor openDatabaseConnection({
  String filename = 'app.sqlite',
  String webWorkerPath = 'drift_db_worker.dart.js',
}) {
  throw UnsupportedError(
    'No Drift connection available for this platform '
    '(filename=$filename, worker=$webWorkerPath).',
  );
}
