import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/clip_item.dart';
import '../../state/clips_controller.dart';

/// Formats 100000 as "100,000".
String formatThousands(int n) {
  final s = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

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
  late bool _favorite = widget.item?.isFavorite ?? false;
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
      final ok = await controller.updateClip(widget.item!, value,
          folderId: folderId, favorite: _favorite);
      if (!ok) {
        if (mounted) setState(() => _saving = false);
        messenger.showSnackBar(
            const SnackBar(content: Text('An identical clip already exists')));
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Clip updated')));
    } else {
      final result =
          await controller.addClip(value, folderId: folderId, favorite: _favorite);
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
    final theme = Theme.of(context);
    final colors = CopyBoxColors.of(context);
    final folders = context.watch<ClipsController>().folders;
    // Guard against a folder deleted while editing.
    final folderValue = folders.any((f) => f.id == _folderId) ? _folderId : null;
    final pinkBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Edit clip' : 'New clip',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _text,
              builder: (_, value, __) => FilledButton(
                onPressed: _saving || value.text.trim().isEmpty ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: _text,
            autofocus: !_isEditing,
            minLines: 6,
            maxLines: 14,
            maxLength: AppInfo.maxClipLength,
            keyboardType: TextInputType.multiline,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Type or paste text to keep',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
              counterText: '',
              enabledBorder: pinkBorder,
              focusedBorder: pinkBorder,
              border: pinkBorder,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _text,
              builder: (_, value, __) => Text(
                '${formatThousands(value.text.length)} / '
                '${formatThousands(AppInfo.maxClipLength)}',
                style: theme.textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
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
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            secondary: Icon(Icons.star_rounded, color: colors.star),
            title: const Text('Mark as favourite'),
            subtitle: const Text('Favourites are never removed automatically'),
            value: _favorite,
            onChanged: (v) => setState(() => _favorite = v),
          ),
          const SizedBox(height: 8),
          const _TipCard(
            text: 'Anything you paste here is saved as-is, even if it looks like '
                'a password. Only automatic capture filters sensitive text.',
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder: (_, value, __) => FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _saving || value.text.trim().isEmpty ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save clip', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber advisory card.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = CopyBoxColors.of(context);
    final background = colors.tipBackground;
    final border = colors.tipBorder;
    final textColor = colors.tipForeground;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: textColor, height: 1.35))),
        ],
      ),
    );
  }
}
