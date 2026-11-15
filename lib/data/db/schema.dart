/// SQLite schema. Version history:
///   1 - initial schema (clips, folders).
class DbSchema {
  DbSchema._();

  static const String fileName = 'clipsave.db';
  static const int version = 1;

  static const String clips = 'clips';
  static const String folders = 'folders';

  static const String createFolders = '''
CREATE TABLE folders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE COLLATE NOCASE,
  color INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)''';

  static const String createClips = '''
CREATE TABLE clips (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'text',
  folder_id INTEGER REFERENCES folders(id) ON DELETE SET NULL,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL DEFAULT 'manual',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''';

  static const List<String> createIndexes = [
    'CREATE UNIQUE INDEX idx_clips_content ON clips(content)',
    'CREATE INDEX idx_clips_updated ON clips(updated_at DESC)',
    'CREATE INDEX idx_clips_folder ON clips(folder_id)',
    'CREATE INDEX idx_clips_favorite ON clips(is_favorite)',
  ];

  static const String foldersWithCounts = '''
SELECT f.id, f.name, f.color, f.created_at, COUNT(c.id) AS clip_count
FROM folders f
LEFT JOIN clips c ON c.folder_id = f.id
GROUP BY f.id
ORDER BY f.name COLLATE NOCASE''';

  /// Deletes the oldest non-favourite clips beyond [limit]. Arg: limit.
  static const String prune = '''
DELETE FROM clips
WHERE is_favorite = 0
  AND id NOT IN (
    SELECT id FROM clips WHERE is_favorite = 0
    ORDER BY updated_at DESC, id DESC
    LIMIT ?
  )''';
}
