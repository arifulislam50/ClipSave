import 'package:sqflite/sqflite.dart';

import '../../core/utils/content_classifier.dart';
import '../db/app_database.dart';
import '../db/schema.dart';
import '../models/clip_filter.dart';
import '../models/clip_item.dart';
import '../models/folder.dart';

/// Thrown when an edit would create an exact duplicate of another clip.
class DuplicateClipException implements Exception {
  const DuplicateClipException();
}

/// All SQLite access for clips and folders.
class ClipRepository {
  ClipRepository(this._appDb);

  final AppDatabase _appDb;

  Future<Database> get _db => _appDb.database;

  // ---------------------------------------------------------------- clips --

  /// Saves [content]. An exact duplicate is moved to the top instead of
  /// being stored twice.
  Future<SaveResult> saveText(
    String content, {
    required String source,
    int? folderId,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    return db.transaction<SaveResult>((txn) async {
      final existing = await txn.query(
        DbSchema.clips,
        where: 'content = ?',
        whereArgs: [content],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final item = ClipItem.fromMap(existing.first);
        final values = <String, Object?>{'updated_at': now.millisecondsSinceEpoch};
        if (folderId != null) values['folder_id'] = folderId;
        await txn.update(DbSchema.clips, values,
            where: 'id = ?', whereArgs: [item.id]);
        return SaveResult(
          item.copyWith(updatedAt: now, folderId: folderId ?? item.folderId),
          created: false,
        );
      }
      final item = ClipItem(
        content: content,
        category: ContentClassifier.classify(content),
        folderId: folderId,
        source: source,
        createdAt: now,
        updatedAt: now,
      );
      final id = await txn.insert(DbSchema.clips, item.toMap());
      return SaveResult(item.copyWith(id: id), created: true);
    });
  }

  Future<List<ClipItem>> query({
    String search = '',
    ClipFilter filter = ClipFilter.all,
    int limit = 2000,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    switch (filter.kind) {
      case FilterKind.all:
        break;
      case FilterKind.favorites:
        where.add('is_favorite = 1');
      case FilterKind.category:
        where.add('category = ?');
        args.add(filter.category!.key);
      case FilterKind.folder:
        where.add('folder_id = ?');
        args.add(filter.folderId);
    }

    final term = search.trim();
    if (term.isNotEmpty) {
      where.add(r"content LIKE ? ESCAPE '\'");
      args.add('%${escapeLike(term)}%');
    }

    final rows = await db.query(
      DbSchema.clips,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'updated_at DESC, id DESC',
      limit: limit,
    );
    return rows.map(ClipItem.fromMap).toList(growable: false);
  }

  /// Escapes LIKE wildcards so searches match literally.
  static String escapeLike(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  Future<void> setFavorite(int id, bool favorite) async {
    final db = await _db;
    await db.update(DbSchema.clips, {'is_favorite': favorite ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> moveToFolder(int id, int? folderId) async {
    final db = await _db;
    await db.update(DbSchema.clips, {'folder_id': folderId},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Updates the text (and re-detects its category).
  /// Throws [DuplicateClipException] if another clip already has that text.
  Future<void> updateContent(int id, String content, {int? folderId}) async {
    final db = await _db;
    await db.transaction((txn) async {
      final dup = await txn.query(DbSchema.clips,
          columns: ['id'],
          where: 'content = ? AND id != ?',
          whereArgs: [content, id],
          limit: 1);
      if (dup.isNotEmpty) throw const DuplicateClipException();
      await txn.update(
        DbSchema.clips,
        {
          'content': content,
          'category': ContentClassifier.classify(content).key,
          'folder_id': folderId,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(DbSchema.clips, where: 'id = ?', whereArgs: [id]);
  }

  /// Re-inserts a deleted clip (undo). Ignored if the text was saved again meanwhile.
  Future<void> restore(ClipItem item) async {
    final db = await _db;
    final map = item.toMap();
    // The folder may have been deleted since; avoid a foreign-key failure.
    if (item.folderId != null) {
      final f = await db.query(DbSchema.folders,
          columns: ['id'], where: 'id = ?', whereArgs: [item.folderId]);
      if (f.isEmpty) map['folder_id'] = null;
    }
    await db.insert(DbSchema.clips, map,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Deletes history. Favourites survive unless [keepFavorites] is false.
  Future<int> clear({required bool keepFavorites}) async {
    final db = await _db;
    return db.delete(DbSchema.clips,
        where: keepFavorites ? 'is_favorite = 0' : null);
  }

  /// Keeps at most [limit] non-favourite clips. 0 = unlimited.
  Future<void> prune(int limit) async {
    if (limit <= 0) return;
    final db = await _db;
    await db.rawDelete(DbSchema.prune, [limit]);
  }

  /// Clip count per automatic category (categories with no clips are absent).
  Future<Map<ClipCategory, int>> categoryCounts() async {
    final db = await _db;
    final rows = await db.rawQuery(DbSchema.categoryCounts);
    return {
      for (final row in rows)
        ClipCategory.fromKey(row['category'] as String?): row['clip_count'] as int,
    };
  }

  Future<int> count() async {
    final db = await _db;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM ${DbSchema.clips}')) ??
        0;
  }

  // -------------------------------------------------------------- folders --

  Future<List<Folder>> folders() async {
    final db = await _db;
    final rows = await db.rawQuery(DbSchema.foldersWithCounts);
    return rows.map(Folder.fromMap).toList(growable: false);
  }

  /// Returns null if a folder with that name (case-insensitive) exists.
  Future<Folder?> createFolder(String name, int color) async {
    final db = await _db;
    final folder = Folder(name: name, color: color, createdAt: DateTime.now());
    try {
      final id = await db.insert(DbSchema.folders, folder.toMap());
      return Folder(
          id: id, name: name, color: color, createdAt: folder.createdAt);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return null;
      rethrow;
    }
  }

  /// Returns false if the new name is already taken.
  Future<bool> renameFolder(int id, String name) async {
    final db = await _db;
    try {
      await db.update(DbSchema.folders, {'name': name},
          where: 'id = ?', whereArgs: [id]);
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  /// Deletes the folder; its clips stay in history (folder_id -> NULL).
  Future<void> deleteFolder(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Explicit, in case foreign keys were not enabled on this connection.
      await txn.update(DbSchema.clips, {'folder_id': null},
          where: 'folder_id = ?', whereArgs: [id]);
      await txn.delete(DbSchema.folders, where: 'id = ?', whereArgs: [id]);
    });
  }
}
