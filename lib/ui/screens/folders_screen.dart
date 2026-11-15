import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/folder.dart';
import '../../state/clips_controller.dart';
import '../widgets/dialogs.dart';
import '../widgets/empty_state.dart';

enum _FolderMenu { rename, delete }

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key, required this.onOpenFolder});

  /// Opens the History tab filtered to this folder.
  final ValueChanged<int> onOpenFolder;

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
    final folders = context.watch<ClipsController>().folders;
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: folders.isEmpty
          ? EmptyState(
              icon: Icons.create_new_folder_outlined,
              title: 'No folders yet',
              message: 'Folders keep related clips together, like addresses, '
                  'work snippets or links to read later.',
              action: FilledButton.icon(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add),
                label: const Text('Create folder'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: folders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, i) {
                final f = folders[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(f.color).withValues(alpha: 0.18),
                    child: Icon(Icons.folder, color: Color(f.color)),
                  ),
                  title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${f.clipCount} clip${f.clipCount == 1 ? '' : 's'}'),
                  onTap: f.id == null ? null : () => onOpenFolder(f.id!),
                  trailing: PopupMenuButton<_FolderMenu>(
                    onSelected: (v) {
                      switch (v) {
                        case _FolderMenu.rename:
                          _rename(context, f);
                        case _FolderMenu.delete:
                          _delete(context, f);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: _FolderMenu.rename, child: Text('Rename')),
                      PopupMenuItem(value: _FolderMenu.delete, child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: folders.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _create(context),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('New folder'),
            ),
    );
  }
}
