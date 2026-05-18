// coverage:ignore-file
// Justification: browser-only drift/sqlite3 wasm wiring; exercised in web
// integration runs, not unit tests.

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a Drift connection on web using the modern WasmDatabase API.
///
/// Loads `sqlite3.wasm` from the app's web/ folder; if the optional
/// `drift_worker.js` is present, SQL runs off the main thread. Otherwise
/// drift transparently falls back to a shared in-page sqlite3 instance.
QueryExecutor openDatabaseConnection({
  String filename = 'app.sqlite',
  String webWorkerPath = 'drift_worker.js',
}) {
  return DatabaseConnection.delayed(_open(filename, webWorkerPath));
}

Future<DatabaseConnection> _open(
  String filename,
  String webWorkerPath,
) async {
  final result = await WasmDatabase.open(
    databaseName: filename.replaceAll('.sqlite', ''),
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse(webWorkerPath),
  );
  return DatabaseConnection(result.resolvedExecutor);
}
