import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';
import '../screens/capture_guide_screen.dart';

/// First-run card that sets honest expectations about Android's limits.
class CaptureInfoCard extends StatelessWidget {
  const CaptureInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      elevation: 0,
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'How ClipSave captures text',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Android only lets apps read the clipboard while they are open. '
              'ClipSave saves new copies when you open it. From other apps, use '
              'the Quick Settings tile, "Save to ClipSave" in the text menu, or Share.',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () =>
                        context.read<SettingsController>().setGuideDismissed(true),
                    child: const Text('Got it'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const CaptureGuideScreen()),
                    ),
                    child: const Text('Learn more'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
