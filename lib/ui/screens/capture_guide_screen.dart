import 'package:flutter/material.dart';

/// Honest explanation of Android's clipboard rules and Copy Box's alternatives.
class CaptureGuideScreen extends StatelessWidget {
  const CaptureGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How capture works')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          _Section(
            icon: Icons.policy_outlined,
            title: 'What Android allows',
            body:
                'Since Android 10, apps can only read the clipboard while they are '
                'on screen and focused (keyboards are the one exception). No normal '
                'app can silently watch everything you copy in the background, and '
                'Copy Box does not try to get around this. It uses no accessibility '
                'service and works with any keyboard.',
          ),
          _Section(
            icon: Icons.auto_mode_outlined,
            title: '1. Auto-save when you open Copy Box',
            body:
                'Copy text anywhere, then switch to Copy Box. New clipboard text is '
                'saved automatically. You can turn auto-save off in Settings. On '
                'Android 12 and newer, Android shows its own "Copy Box pasted from '
                'your clipboard" notice every time the clipboard is read (on open, '
                'from the tile or the notification Save button); apps cannot turn '
                'that notice off.',
          ),
          _Section(
            icon: Icons.grid_view_rounded,
            title: '2. Quick Settings tile (fastest)',
            body:
                'Add the "Save to Copy Box" tile (Settings > Add Quick Settings tile, '
                'or swipe down twice > Edit). After copying, pull down Quick '
                'Settings and tap the tile. Copy Box opens an invisible window for '
                'a moment, reads the clipboard and closes. The toast says "Sent to '
                'Copy Box"; the text is checked and added to your history the next '
                'time you open the app. If the phone is locked, you are asked to '
                'unlock first.',
          ),
          _Section(
            icon: Icons.notifications_active_outlined,
            title: 'Notification Save button',
            body:
                'Turn on Settings > Quick-save notification. A silent notification '
                'with a "Save copied text" button stays in the shade; tap it after '
                'you copy something. Like the tile, it opens an invisible window for '
                'a moment to read the clipboard, then saves the text even if you never '
                'open Copy Box. The notification never shows clip text. On Android 13+ '
                'Copy Box asks for the notification permission only when you turn '
                'this on.',
          ),
          _Section(
            icon: Icons.text_fields_rounded,
            title: '3. "Save to Copy Box" in the text menu',
            body:
                'Select text in any app, open the ⋮ menu in the selection toolbar '
                'and choose "Save to Copy Box". This does not use the clipboard at '
                'all. Some apps do not show this menu.',
          ),
          _Section(
            icon: Icons.share_outlined,
            title: '4. Share to Copy Box',
            body: 'Use Share in any app and pick "Save to Copy Box".',
          ),
          _Section(
            icon: Icons.add_rounded,
            title: '5. New clip',
            body:
                'Tap "New clip" on the History screen to type or paste text yourself. '
                'Copy Box itself only reads the clipboard when it opens (if auto-save '
                'is on) or when you use the Quick Settings tile.',
          ),
          _Section(
            icon: Icons.shield_outlined,
            title: 'Passwords and one-time codes',
            body:
                'Text that the copying app marks as sensitive (password managers do '
                'this) is never saved automatically. With "Skip passwords and codes" '
                'on (the default), auto-save, the tile, Share and text selection all '
                'skip text that looks like a password, OTP, card number or access key. '
                'Skipped items are kept in memory for two minutes only, so you can tap '
                '"Save anyway" if you really want them. When you copy a clip '
                'like that back out of Copy Box, it is marked sensitive so Android 13+ '
                'hides it in the copy preview.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
