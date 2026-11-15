import '../../core/utils/content_classifier.dart';

enum FilterKind { all, favorites, category, folder }

/// What the history list currently shows.
class ClipFilter {
  const ClipFilter._(this.kind, {this.category, this.folderId});

  static const ClipFilter all = ClipFilter._(FilterKind.all);
  static const ClipFilter favorites = ClipFilter._(FilterKind.favorites);

  const ClipFilter.category(ClipCategory category)
      : this._(FilterKind.category, category: category);

  const ClipFilter.folder(int folderId)
      : this._(FilterKind.folder, folderId: folderId);

  final FilterKind kind;
  final ClipCategory? category;
  final int? folderId;

  @override
  bool operator ==(Object other) =>
      other is ClipFilter &&
      other.kind == kind &&
      other.category == category &&
      other.folderId == folderId;

  @override
  int get hashCode => Object.hash(kind, category, folderId);
}
