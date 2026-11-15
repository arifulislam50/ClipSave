import '../../core/utils/content_classifier.dart';

const Object _unset = Object();

/// One saved clipboard entry.
class ClipItem {
  const ClipItem({
    this.id,
    required this.content,
    required this.category,
    this.folderId,
    this.isFavorite = false,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String content;
  final ClipCategory category;
  final int? folderId;
  final bool isFavorite;
  final String source;
  final DateTime createdAt;

  /// Last time this text was saved or copied again; history is sorted by it.
  final DateTime updatedAt;

  /// Single-line preview for list rows.
  String get preview {
    final collapsed = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.length > 400 ? '${collapsed.substring(0, 400)}…' : collapsed;
  }

  ClipItem copyWith({
    int? id,
    String? content,
    ClipCategory? category,
    Object? folderId = _unset,
    bool? isFavorite,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClipItem(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      folderId: identical(folderId, _unset) ? this.folderId : folderId as int?,
      isFavorite: isFavorite ?? this.isFavorite,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'content': content,
        'category': category.key,
        'folder_id': folderId,
        'is_favorite': isFavorite ? 1 : 0,
        'source': source,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ClipItem.fromMap(Map<String, Object?> map) {
    return ClipItem(
      id: map['id'] as int?,
      content: map['content'] as String,
      category: ClipCategory.fromKey(map['category'] as String?),
      folderId: map['folder_id'] as int?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      source: map['source'] as String? ?? 'manual',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}

/// Result of saving text: the stored item and whether it is new.
class SaveResult {
  const SaveResult(this.item, {required this.created});
  final ClipItem item;
  final bool created;
}
