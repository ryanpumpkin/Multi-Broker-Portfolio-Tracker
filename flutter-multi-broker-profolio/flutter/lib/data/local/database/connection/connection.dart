import 'package:drift/drift.dart';

import 'stub.dart'
    if (dart.library.io) 'native.dart'
    if (dart.library.html) 'web.dart' as impl;

/// Opens a platform-appropriate Drift connection.
///
/// - Native (iOS/Android): sqlite3-backed file DB.
/// - Web: sql.js via Drift web worker when available, with IndexedDB fallback.
QueryExecutor openDatabaseConnection({
  String filename = 'app.sqlite',
  String webWorkerPath = 'drift_db_worker.dart.js',
}) {
  return impl.openDatabaseConnection(
    filename: filename,
    webWorkerPath: webWorkerPath,
  );
}
