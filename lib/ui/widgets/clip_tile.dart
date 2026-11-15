import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_format.dart';
import '../../data/models/clip_item.dart';
import '../../state/clips_controller.dart';
import '../actions/clip_actions.dart';
import 'category_visuals.dart';

/// One history row.
///
/// - No left avatar; text starts at 16px. The type word in the meta line uses
///   the category colour.
/// - One tap toggles collapsed (2 lines) / expanded (full text, selectable,
///   capped at [maxExpandedChars]) with a ~200 ms AnimatedSize. The state lives
///   in [expanded], owned by the list per clip id, so only this tile rebuilds.
/// - Tapping does NOT copy. Copy only via the copy button (or the long-press
///   menu), which still marks sensitive-looking clips EXTRA_IS_SENSITIVE.
class ClipTile extends StatelessWidget {
  const ClipTile({super.key, required this.item, required this.expanded});

  final ClipItem item;
  final ValueNotifier<bool> expanded;

  static const int maxExpandedChars = 10000;
  static const String truncatedNote =
      'Showing the first 10,000 characters. Open Edit to see the rest.';
  static const String collapseHint = 'Tap to collapse';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: expanded,
      builder: (context, isExpanded, _) => _buildTile(context, isExpanded),
    );
  }

  void _toggle() => expanded.value = !expanded.value;

  Widget _buildTile(BuildContext context, bool isExpanded) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = CopyBoxColors.of(context);
    final folder = context.read<ClipsController>().folderById(item.folderId);
    final muted12 = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final metaStyle = theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final truncated = item.content.length > maxExpandedChars;

    final textBlock = isExpanded
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                truncated ? item.content.substring(0, maxExpandedChars) : item.content,
                style: bodyStyle,
                onTap: _toggle,
              ),
              if (truncated) ...[
                const SizedBox(height: 6),
                Text(truncatedNote, style: muted12),
              ],
            ],
          )
        : Text(item.preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: bodyStyle);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Semantics(
        container: true,
        button: true,
        value: isExpanded ? 'Expanded' : 'Collapsed',
        onTap: _toggle,
        onTapHint: isExpanded ? 'Collapse' : 'Expand',
        onLongPress: () => showClipActionsSheet(context, item),
        onLongPressHint: 'More actions',
        child: Material(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: _toggle,
            onLongPress: () => showClipActionsSheet(context, item),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnimatedSize(
                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            textBlock,
                            const SizedBox(height: 6),
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: item.category.singular,
                                  style: TextStyle(
                                    color: item.category.color(theme.brightness),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                    text: ' · ${TimeFormat.relative(item.updatedAt)}'
                                        ' · ${ClipSources.label(item.source)}'),
                              ]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: metaStyle,
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
                            if (isExpanded) ...[
                              const SizedBox(height: 6),
                              Text(collapseHint, style: muted12),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (item.isFavorite)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, right: 2),
                        child: Icon(Icons.star_rounded,
                            size: 20, color: colors.star, semanticLabel: 'Favourite'),
                      ),
                    CopyButton(onPressed: () => ClipActions.copy(context, item)),
                  ],
                ),
              ),
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
        backgroundColor: colors.fill,
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
