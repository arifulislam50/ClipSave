import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// Opens (and lazily creates) the local SQLite database.
/// The database lives in the app's private storage and never leaves the device.
class AppDatabase {
  /// [path] overrides the on-device location (tests pass `inMemoryDatabasePath`).
  AppDatabase({String? path}) : _path = path;

  final String? _path;
  Future<Database>? _database;

  /// Opens once and caches. A failed open is not cached, so a later call can retry.
  Future<Database> get database => _database ??= _open().then(
        (db) => db,
        onError: (Object error, StackTrace stack) {
          _database = null;
          Error.throwWithStackTrace(error, stack);
        },
      );

  Future<Database> _open() async {
    final path = _path ?? p.join(await getDatabasesPath(), DbSchema.fileName);
    return openDatabase(
      path,
      version: DbSchema.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        final batch = db.batch();
        batch.execute(DbSchema.createFolders);
        batch.execute(DbSchema.createClips);
        for (final sql in DbSchema.createIndexes) {
          batch.execute(sql);
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Additive migrations only; existing data is never touched.
        if (oldVersion < 2) {
          await db.execute(DbSchema.createdIndex);
        }
      },
    );
  }

  Future<void> close() async {
    final db = await _database;
    await db?.close();
    _database = null;
  }
}
