import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/content_classifier.dart';
import '../../data/models/folder.dart';
import '../../state/clips_controller.dart';
import '../widgets/category_visuals.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_header.dart';

enum _FolderMenu { rename, delete }

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({
    super.key,
    required this.onOpenFolder,
    required this.onOpenCategory,
  });

  /// Opens the History tab filtered to this folder.
  final ValueChanged<int> onOpenFolder;

  /// Opens the History tab filtered to this automatic category.
  final ValueChanged<ClipCategory> onOpenCategory;

  static const List<ClipCategory> _gridCategories = [
    ClipCategory.link,
    ClipCategory.email,
    ClipCategory.phone,
    ClipCategory.number,
  ];

  Future<void> _create(BuildContext context) async {
    final controller = context.read<ClipsController>();
    final messenger = ScaffoldMessenger.of(context);
    final name = await showTextInputDialog(context,
        title: 'New folder', hint: 'e.g. Work, Addresses', confirmLabel: 'Create');
    if (name == null) return;
    final folder = await controller.createFolder(name);
    if (folder == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('A folder with that name already exists')));
    }
  }

  Future<void> _rename(BuildContext context, Folder folder) async {
    final controller = context.read<ClipsController>();
    final messenger = ScaffoldMessenger.of(context);
    final name = await showTextInputDialog(context,
        title: 'Rename folder', initialValue: folder.name, confirmLabel: 'Rename');
    if (name == null) return;
    final ok = await controller.renameFolder(folder, name);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
          content: Text('A folder with that name already exists')));
    }
  }

  Future<void> _delete(BuildContext context, Folder folder) async {
    final controller = context.read<ClipsController>();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete "${folder.name}"?',
      message: 'The folder is removed. Its ${folder.clipCount} clip(s) stay in your history.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await controller.deleteFolder(folder);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClipsController>();
    final folders = controller.folders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          const SectionHeader('YOUR FOLDERS'),
          if (folders.isEmpty)
            _NoFoldersCard(onCreate: () => _create(context))
          else
            for (final f in folders)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FolderCard(
                  folder: f,
                  onOpen: f.id == null ? null : () => onOpenFolder(f.id!),
                  onRename: () => _rename(context, f),
                  onDelete: () => _delete(context, f),
                ),
              ),
          const SizedBox(height: 8),
          const SectionHeader('AUTOMATIC CATEGORIES'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              for (final c in _gridCategories)
                _CategoryCard(
                  category: c,
                  count: controller.categoryCount(c),
                  onTap: () => onOpenCategory(c),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New folder', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// White card with a hairline border, used for folder and category tiles.
class _BorderedCard extends StatelessWidget {
  const _BorderedCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CopyBoxColors.of(context);
    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

String _countLabel(int n) => '$n clip${n == 1 ? '' : 's'}';

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final Folder folder;
  final VoidCallback? onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = CopyBoxColors.of(context);
    final color = Color(folder.color);
    return _BorderedCard(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: Icon(Icons.folder_rounded, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(color: colors.text)),
                  Text(_countLabel(folder.clipCount),
                      style: theme.textTheme.labelMedium?.copyWith(color: colors.muted)),
                ],
              ),
            ),
            PopupMenuButton<_FolderMenu>(
              tooltip: 'More options for ${folder.name}',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                switch (v) {
                  case _FolderMenu.rename:
                    onRename();
                  case _FolderMenu.delete:
                    onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: _FolderMenu.rename, child: Text('Rename')),
                PopupMenuItem(value: _FolderMenu.delete, child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFoldersCard extends StatelessWidget {
  const _NoFoldersCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = CopyBoxColors.of(context);
    return _BorderedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No folders yet',
                style: theme.textTheme.titleMedium?.copyWith(color: colors.text)),
            const SizedBox(height: 4),
            Text(
              'Folders keep related clips together, like addresses, work snippets '
              'or links to read later.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create folder'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.count, required this.onTap});

  final ClipCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = CopyBoxColors.of(context);
    return Semantics(
      button: true,
      label: '${category.label}, ${_countLabel(count)}',
      excludeSemantics: true,
      child: _BorderedCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryAvatar(category: category, size: 40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label,
                      style: theme.textTheme.titleSmall?.copyWith(color: colors.text)),
                  Text(_countLabel(count),
                      style: theme.textTheme.labelMedium?.copyWith(color: colors.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
