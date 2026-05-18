// coverage:ignore-file
// Justification: platform-IO glue (path_provider + sqlite3 native libs);
// exercised only on a real device/emulator.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the application database file under the platform's documents dir.
LazyDatabase openDatabaseConnection({
  String filename = 'app.sqlite',
  String webWorkerPath = 'drift_db_worker.dart.js',
}) {
  return LazyDatabase(() async {
    // Not used on native platforms; kept for a shared signature.
    assert(webWorkerPath.isNotEmpty);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    return NativeDatabase.createInBackground(file);
  });
}
