import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_format.dart';
import '../../data/models/clip_item.dart';
import '../../state/clips_controller.dart';
import '../actions/clip_actions.dart';
import 'category_visuals.dart';

/// One history row: category avatar, 2-line preview, "Type · time · source",
/// and a copy button. Tap = copy (unchanged), long-press = more actions.
class ClipTile extends StatelessWidget {
  const ClipTile({super.key, required this.item});

  final ClipItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = CopyBoxColors.of(context);
    final folder = context.read<ClipsController>().folderById(item.folderId);
    final meta = [
      item.category.singular,
      TimeFormat.relative(item.updatedAt),
      ClipSources.label(item.source),
    ].join(' · ');
    final metaStyle = theme.textTheme.labelMedium?.copyWith(color: colors.muted);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ClipActions.copy(context, item),
          onLongPress: () => showClipActionsSheet(context, item),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                CategoryAvatar(category: item.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(color: colors.text),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.isFavorite) ...[
                            Icon(Icons.star_rounded,
                                size: 16, color: colors.star, semanticLabel: 'Favourite'),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(meta,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: metaStyle),
                          ),
                        ],
                      ),
                      if (folder != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.folder_rounded, size: 14, color: Color(folder.color)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(folder.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: metaStyle),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CopyButton(onPressed: () => ClipActions.copy(context, item)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 44px round copy button shown at the end of every clip tile.
class CopyButton extends StatelessWidget {
  const CopyButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = CopyBoxColors.of(context);
    return IconButton(
      tooltip: 'Copy',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.tint,
        fixedSize: const Size(44, 44),
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
      icon: Icon(Icons.copy_rounded, size: 20, color: colors.link),
    );
  }
}

/// Bottom sheet with every action for a clip.
Future<void> showClipActionsSheet(BuildContext context, ClipItem item) {
  final controller = context.read<ClipsController>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void run(Future<void> Function() action) {
        Navigator.pop(sheetContext);
        action();
      }

      final error = Theme.of(sheetContext).colorScheme.error;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Saved ${TimeFormat.full(item.createdAt)}',
                style: Theme.of(sheetContext).textTheme.labelMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () => run(() => ClipActions.copy(context, item)),
            ),
            ListTile(
              leading: Icon(item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
              title: Text(item.isFavorite ? 'Remove from favourites' : 'Add to favourites'),
              onTap: () => run(() => controller.toggleFavorite(item)),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => run(() => ClipActions.openEditor(context, item: item)),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move to folder'),
              onTap: () => run(() => ClipActions.moveToFolder(context, item)),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: error),
              title: Text('Delete', style: TextStyle(color: error)),
              onTap: () => run(() => ClipActions.delete(context, item)),
            ),
          ],
        ),
      );
    },
  );
}
