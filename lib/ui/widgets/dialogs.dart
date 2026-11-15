import 'package:flutter/material.dart';

import '../../data/models/folder.dart';

/// Yes/no confirmation. Resolves to false when dismissed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Single-line text input. Resolves to null when cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String hint = '',
  String confirmLabel = 'Save',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(
      title: title,
      initialValue: initialValue,
      hint: hint,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.initialValue,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final String hint;
  final String confirmLabel;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// Picks a folder. Resolves to null when cancelled; `(id: null)` means
/// "no folder"; `(id: -1)` means "create a new folder".
Future<({int? id})?> showFolderPicker(
  BuildContext context, {
  required List<Folder> folders,
  int? currentFolderId,
}) {
  return showDialog<({int? id})>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Move to folder'),
      children: [
        _FolderOption(
          icon: Icons.inbox_outlined,
          label: 'No folder',
          selected: currentFolderId == null,
          onTap: () => Navigator.pop(context, (id: null)),
        ),
        for (final f in folders)
          _FolderOption(
            icon: Icons.folder,
            color: Color(f.color),
            label: f.name,
            selected: f.id == currentFolderId,
            onTap: () => Navigator.pop(context, (id: f.id)),
          ),
        const Divider(),
        _FolderOption(
          icon: Icons.create_new_folder_outlined,
          label: 'New folder…',
          selected: false,
          onTap: () => Navigator.pop(context, (id: -1)),
        ),
      ],
    ),
  );
}

class _FolderOption extends StatelessWidget {
  const _FolderOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}
