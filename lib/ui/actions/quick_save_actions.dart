import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../platform/quick_save_bridge.dart';
import '../../state/settings_controller.dart';

/// Turning the quick-save notification on/off, shared by Settings and the
/// History card. If Android 13+ denies the notification permission (including
/// "don't ask again"), the switch stays off and a snackbar offers the system
/// notification settings.
class QuickSaveActions {
  QuickSaveActions._();

  static Future<void> setEnabled(BuildContext context, bool enabled) async {
    final settings = context.read<SettingsController>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await settings.setQuickSave(enabled);

    void snack(String text, {SnackBarAction? action}) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));

    switch (result) {
      case QuickSaveResult.enabled:
        snack('Quick-save notification is on. Pull down the shade and tap Save after you copy.');
      case QuickSaveResult.disabled:
        if (enabled) snack('Could not turn on the quick-save notification.');
      case QuickSaveResult.denied:
      case QuickSaveResult.permanentlyDenied:
        snack(
          'Notifications are off for Copy Box, so the quick-save notification cannot be shown.',
          action: SnackBarAction(
            label: 'Open settings',
            onPressed: settings.openNotificationSettings,
          ),
        );
      case QuickSaveResult.unsupported:
        snack('The quick-save notification is not available here.');
    }
  }
}
