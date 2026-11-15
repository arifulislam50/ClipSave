import 'package:flutter/material.dart';


/// In-app summary of the privacy policy (keep in sync with PRIVACY_POLICY.md).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const String adsPolicyUrl = 'https://policies.google.com/technologies/ads';

  static const List<(String, String)> _sections = [
    (
      'Summary',
      'Your clips are stored only on this device and are never uploaded by Copy Box. '
          'Copy Box has no accounts and no servers of its own. The app shows ads '
          'provided by Google AdMob, and you can manage your ad consent in Settings.'
    ),
    (
      'What is stored on your device',
      'Clip text, its detected type (link, email, phone, number, text), the folder '
          'you chose, whether it is a favourite, how it was saved, and when. Your '
          'settings are stored separately. Everything lives in the app\'s private '
          'storage, and cloud backup and device transfer are disabled for it.'
    ),
    (
      'Ads by Google AdMob',
      'Copy Box shows a banner ad on the History and Folders screens. Google AdMob '
          'may collect device identifiers (such as the advertising ID) and usage '
          'data under Google\'s policy: $adsPolicyUrl. Copy Box never passes your '
          'clips or clipboard content to the ad SDK, and ad requests contain no '
          'content from the app.'
    ),
    (
      'Your ad choices',
      'Where consent is required, Google\'s consent form appears before any ad is '
          'requested. You can review or change your choice in Settings > Privacy and '
          'ad choices, and reset your advertising ID in Android settings.'
    ),
    (
      'When the clipboard is read',
      'Only when Copy Box opens or returns to the screen (if auto-save is on), or '
          'when you tap the Quick Settings tile. Share and '
          'text-selection saves receive only the text you sent. Text from the tile, '
          'Share or text selection waits in a small private queue until Copy Box '
          'next opens and checks it. The splash screen never reads the clipboard.'
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
      'Deleting your data',
      'Delete single clips, clear history in Settings, or uninstall the app to '
          'remove everything Copy Box stored on the device.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy policy', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final (title, body) in _sections) ...[
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            SelectableText(body,
                style: theme.textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ],
      ),
    );
  }
}
