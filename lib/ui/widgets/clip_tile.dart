import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/utils/time_format.dart';
import '../../data/models/clip_item.dart';
import '../../state/clips_controller.dart';
import '../actions/clip_actions.dart';
import 'category_visuals.dart';

/// One history row. Tap = copy, star = favourite, long-press = more actions.
class ClipTile extends StatelessWidget {
  const ClipTile({super.key, required this.item});

  final ClipItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = context.read<ClipsController>();
    final folder = controller.folderById(item.folderId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ClipActions.copy(context, item),
        onLongPress: () => showClipActionsSheet(context, item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(item.category.icon, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          TimeFormat.relative(item.updatedAt),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        Text(
                          ClipSources.label(item.source),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (folder != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder, size: 14, color: Color(folder.color)),
                              const SizedBox(width: 2),
                              Text(folder.name, style: theme.textTheme.labelSmall),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: item.isFavorite ? 'Remove from favourites' : 'Add to favourites',
                icon: Icon(
                  item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: item.isFavorite ? Colors.amber.shade600 : scheme.onSurfaceVariant,
                ),
                onPressed: () => controller.toggleFavorite(item),
              ),
            ],
          ),
        ),
      ),
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
              leading: Icon(Icons.delete_outline, color: Theme.of(sheetContext).colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(color: Theme.of(sheetContext).colorScheme.error)),
              onTap: () => run(() => ClipActions.delete(context, item)),
            ),
          ],
        ),
      );
    },
  );
}
