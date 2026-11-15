import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/clip_item.dart';
import '../../state/clips_controller.dart';
import '../screens/clip_editor_screen.dart';
import '../widgets/dialogs.dart';

/// User-facing flows shared by several screens. Each shows its own feedback.
class ClipActions {
  ClipActions._();

  /// Takes the messenger (captured before any await) rather than a context,
  /// because the originating tile may be gone by the time we report back.
  static void _snack(ScaffoldMessengerState messenger, String text,
      {SnackBarAction? action}) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  /// "Save clipboard" button: reads now, asks before saving anything sensitive.
  static Future<void> saveClipboard(BuildContext context) async {
    final controller = context.read<ClipsController>();
    final messenger = ScaffoldMessenger.of(context);
    var outcome = await controller.captureClipboard();
    if (!context.mounted) return;
    if (outcome.kind == CaptureKind.sensitive) {
      final ok = await showConfirmDialog(
        context,
        title: 'Save sensitive text?',
        message: '${outcome.reason!.explanation} '
            'It will be stored unencrypted in ClipSave on this device. '
            'Save it anyway?',
        confirmLabel: 'Save anyway',
      );
      if (!ok || !context.mounted) return;
      outcome = await controller.captureClipboard(force: true);
    }
    _snack(messenger, outcome.message);
  }

  static Future<void> copy(BuildContext context, ClipItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final showOwn = await context.read<ClipsController>().copy(item);
    if (showOwn) _snack(messenger, 'Copied');
  }

  static Future<void> delete(BuildContext context, ClipItem item) async {
    final controller = context.read<ClipsController>();
    final messenger = ScaffoldMessenger.of(context);
    await controller.delete(item);
    _snack(
      messenger,
      'Clip deleted',
      action: SnackBarAction(label: 'Undo', onPressed: () => controller.restore(item)),
    );
  }

  static Future<void> moveToFolder(BuildContext context, ClipItem item) async {
    final controller = context.read<ClipsController>();
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showFolderPicker(
      context,
      folders: controller.folders,
      currentFolderId: item.folderId,
    );
    if (choice == null || !context.mounted) return;
    var folderId = choice.id;
    if (folderId == -1) {
      final name = await showTextInputDialog(context,
          title: 'New folder', hint: 'Folder name', confirmLabel: 'Create');
      if (name == null || !context.mounted) return;
      final folder = await controller.createFolder(name);
      if (folder == null) {
        _snack(messenger, 'A folder with that name already exists');
        return;
      }
      folderId = folder.id;
    }
    await controller.moveToFolder(item, folderId);
    final name = controller.folderById(folderId)?.name;
    _snack(messenger, name == null ? 'Removed from folder' : 'Moved to $name');
  }

  static Future<void> openEditor(BuildContext context, {ClipItem? item}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ClipEditorScreen(item: item)),
    );
  }

  static Future<void> clearHistory(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Clear history?',
      message: 'Deletes every clip except favourites. This cannot be undone.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final n = await context.read<ClipsController>().clearHistory(keepFavorites: true);
    _snack(messenger, 'Deleted $n clip${n == 1 ? '' : 's'}');
  }

  static Future<void> deleteEverything(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete all clips?',
      message: 'Deletes every clip, including favourites. Folders are kept. '
          'This cannot be undone.',
      confirmLabel: 'Delete all',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final n = await context.read<ClipsController>().clearHistory(keepFavorites: false);
    _snack(messenger, 'Deleted $n clip${n == 1 ? '' : 's'}');
  }
}
