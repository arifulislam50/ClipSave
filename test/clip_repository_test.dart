import 'package:clipsave/core/utils/content_classifier.dart';
import 'package:clipsave/data/db/app_database.dart';
import 'package:clipsave/data/models/clip_filter.dart';
import 'package:clipsave/data/repositories/clip_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Runs the real repository against desktop SQLite via sqflite_common_ffi.
/// Requires the SQLite shared library on the host (bundled on macOS/Windows;
/// on Linux install libsqlite3-dev).
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late ClipRepository repo;

  setUp(() {
    db = AppDatabase(path: inMemoryDatabasePath);
    repo = ClipRepository(db);
  });

  tearDown(() => db.close());

  test('saves and classifies, newest first', () async {
    final a = await repo.saveText('hello', source: 'manual');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.saveText('https://flutter.dev', source: 'manual');
    expect(a.created, isTrue);
    final all = await repo.query();
    expect(all.map((c) => c.content), ['https://flutter.dev', 'hello']);
    expect(all.first.category, ClipCategory.link);
  });

  test('duplicate text moves to top instead of duplicating', () async {
    await repo.saveText('one', source: 'manual');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.saveText('two', source: 'manual');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final again = await repo.saveText('one', source: 'auto');
    expect(again.created, isFalse);
    final all = await repo.query();
    expect(all.map((c) => c.content), ['one', 'two']);
  });

  test('search escapes LIKE wildcards and ignores case', () async {
    await repo.saveText('100% done', source: 'manual');
    await repo.saveText('100 done', source: 'manual');
    await repo.saveText('Snake_case', source: 'manual');
    await repo.saveText('snakeXcase', source: 'manual');
    expect((await repo.query(search: '%')).map((c) => c.content), ['100% done']);
    expect((await repo.query(search: 'E_C')).map((c) => c.content), ['Snake_case']);
  });

  test('favourites filter and clear keeps favourites', () async {
    final keep = await repo.saveText('keep me', source: 'manual');
    await repo.saveText('drop me', source: 'manual');
    await repo.setFavorite(keep.item.id!, true);
    expect((await repo.query(filter: ClipFilter.favorites)).length, 1);
    expect(await repo.clear(keepFavorites: true), 1);
    expect((await repo.query()).single.content, 'keep me');
  });

  test('prune keeps newest N non-favourites', () async {
    final fav = await repo.saveText('fav', source: 'manual');
    await repo.setFavorite(fav.item.id!, true);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.saveText('item $i', source: 'manual');
    }
    await repo.prune(2);
    final contents = (await repo.query()).map((c) => c.content).toSet();
    expect(contents, {'fav', 'item 4', 'item 3'});
  });

  test('folders: unique names, counts, delete keeps clips', () async {
    final work = await repo.createFolder('Work', 0xFF3D5AFE);
    expect(work, isNotNull);
    expect(await repo.createFolder('work', 0xFF000000), isNull);
    final clip = await repo.saveText('agenda', source: 'manual');
    await repo.moveToFolder(clip.item.id!, work!.id);
    expect((await repo.folders()).single.clipCount, 1);
    expect((await repo.query(filter: ClipFilter.folder(work.id!))).length, 1);
    await repo.deleteFolder(work.id!);
    final remaining = await repo.query();
    expect(remaining.single.folderId, isNull);
    expect(await repo.folders(), isEmpty);
  });

  test('edit rejects duplicates and re-classifies', () async {
    final a = await repo.saveText('first', source: 'manual');
    await repo.saveText('second', source: 'manual');
    await expectLater(repo.updateContent(a.item.id!, 'second'),
        throwsA(isA<DuplicateClipException>()));
    await repo.updateContent(a.item.id!, 'me@example.com');
    final edited = (await repo.query(search: 'example')).single;
    expect(edited.category, ClipCategory.email);
  });

  test('delete then restore (undo)', () async {
    final r = await repo.saveText('oops', source: 'manual');
    await repo.delete(r.item.id!);
    expect(await repo.count(), 0);
    await repo.restore(r.item);
    expect((await repo.query()).single.content, 'oops');
  });
}
