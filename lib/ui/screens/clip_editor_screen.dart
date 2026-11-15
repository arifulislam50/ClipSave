import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models/clip_item.dart';
import '../../state/clips_controller.dart';

/// Create a clip by typing/pasting (manual fallback), or edit an existing one.
class ClipEditorScreen extends StatefulWidget {
  const ClipEditorScreen({super.key, this.item});

  /// Null = create a new clip.
  final ClipItem? item;

  @override
  State<ClipEditorScreen> createState() => _ClipEditorScreenState();
}

class _ClipEditorScreenState extends State<ClipEditorScreen> {
  late final TextEditingController _text =
      TextEditingController(text: widget.item?.content ?? '');
  late int? _folderId = widget.item?.folderId;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _text.text;
    if (value.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final controller = context.read<ClipsController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // The chosen folder may have been deleted while this screen was open.
    final folderId =
        controller.folderById(_folderId) == null ? null : _folderId;

    if (_isEditing) {
      final ok = await controller.updateClip(widget.item!, value, folderId: folderId);
      if (!ok) {
        if (mounted) setState(() => _saving = false);
        messenger.showSnackBar(
            const SnackBar(content: Text('An identical clip already exists')));
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Clip updated')));
    } else {
      final result = await controller.addClip(value, folderId: folderId);
      messenger.showSnackBar(SnackBar(
        content: Text(result == null
            ? 'Could not save this text'
            : result.created
                ? 'Clip saved'
                : 'Already saved: moved to the top'),
      ));
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final folders = context.watch<ClipsController>().folders;
    // Guard against a folder deleted while editing.
    final folderValue =
        folders.any((f) => f.id == _folderId) ? _folderId : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit clip' : 'New clip'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _text,
            autofocus: !_isEditing,
            minLines: 6,
            maxLines: 16,
            maxLength: AppInfo.maxClipLength,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Type or paste text to keep',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            // ignore: deprecated_member_use
            value: folderValue,
            decoration: const InputDecoration(
              labelText: 'Folder',
              prefixIcon: Icon(Icons.folder_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('No folder')),
              for (final f in folders)
                DropdownMenuItem<int?>(value: f.id, child: Text(f.name)),
            ],
            onChanged: (v) => setState(() => _folderId = v),
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: anything you paste here is saved as-is, even if it looks like '
            'a password. Only automatic capture filters sensitive text.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
