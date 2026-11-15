/// A user-created folder that groups clips.
class Folder {
  const Folder({
    this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.clipCount = 0,
  });

  final int? id;
  final String name;

  /// ARGB colour value.
  final int color;
  final DateTime createdAt;

  /// Number of clips in the folder (filled by queries, not stored).
  final int clipCount;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'color': color,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Folder.fromMap(Map<String, Object?> map) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      clipCount: map['clip_count'] as int? ?? 0,
    );
  }
}
