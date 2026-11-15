import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/settings_controller.dart';
import '../actions/quick_save_actions.dart';

/// Small History card suggesting the quick-save notification. Shown while it
/// is off and the user has not chosen "Not now" before (remembered).
class QuickSavePromptCard extends StatelessWidget {
  const QuickSavePromptCard({super.key});

  static const String message =
      'Save without opening the app. Turn on the quick-save notification.';

  @override
  Widget build(BuildContext context) {
    final show = context.select<SettingsController, bool>((s) => s.showQuickSavePrompt);
    if (!show) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final colors = CopyBoxColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Material(
        color: colors.card, // #121214 in dark mode
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant), // #26262A in dark mode
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notifications_active_outlined, color: colors.link, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message, style: TextStyle(color: scheme.onSurface)),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () =>
                          context.read<SettingsController>().dismissQuickSavePrompt(),
                      child: const Text('Not now'),
                    ),
                    TextButton(
                      onPressed: () => QuickSaveActions.setEnabled(context, true),
                      child: const Text('Turn on'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
