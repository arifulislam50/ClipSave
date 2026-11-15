import 'package:flutter/material.dart';

/// In-app copy of the privacy policy (keep in sync with PRIVACY_POLICY.md).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<(String, String)> _sections = [
    (
      'Summary',
      'ClipSave stores the text you choose to save only on your device. It has '
          'no accounts, no ads, no analytics and no internet permission, so your '
          'clips cannot be sent anywhere by the app.'
    ),
    (
      'What is stored',
      'Clip text, its detected type (link, email, phone, number, text), the '
          'folder you chose, whether it is a favourite, how it was saved, and when. '
          'Your settings are stored separately. Everything lives in the app\'s '
          'private storage.'
    ),
    (
      'When the clipboard is read',
      'Only while ClipSave is open and focused (if auto-save is on), when you tap '
          '"Save clipboard", or when you tap the Quick Settings tile. Share and '
          'text-selection saves receive only the text you sent. Text from the tile, '
          'Share or text selection waits in a small private queue until ClipSave '
          'next opens and checks it.'
    ),
    (
      'Sensitive data',
      'Items marked sensitive by the copying app are never saved automatically. '
          'By default, auto-save, the Quick Settings tile, Share and text selection '
          'also skip text that looks like a password, one-time code, card number or '
          'key. Skipped items are held in memory for two minutes only and are never '
          'written to storage unless you tap "Save anyway".'
    ),
    (
      'Backups and sharing',
      'Android cloud backup and device-to-device transfer are disabled for '
          'ClipSave. No data is shared with third parties.'
    ),
    (
      'Deleting your data',
      'Delete single clips, clear history in Settings, or uninstall the app to '
          'remove everything.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final (title, body) in _sections) ...[
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
