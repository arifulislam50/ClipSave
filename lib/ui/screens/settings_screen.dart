import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../platform/clipboard_bridge.dart';
import '../../state/clips_controller.dart';
import '../../state/settings_controller.dart';
import '../actions/clip_actions.dart';
import 'capture_guide_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static String _limitLabel(int limit) =>
      limit == 0 ? 'Unlimited' : 'Keep last $limit clips';

  Future<void> _pickLimit(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('History size'),
        children: [
          for (final option in AppInfo.historyLimitOptions)
            ListTile(
              title: Text(_limitLabel(option)),
              trailing:
                  option == settings.historyLimit ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, option),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text('Favourites are never removed automatically.'),
          ),
        ],
      ),
    );
    if (picked != null) await settings.setHistoryLimit(picked);
  }

  Future<void> _addTile(BuildContext context) async {
    final controller = context.read<ClipsController>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.requestAddTile();
    final text = switch (result) {
      TileRequestResult.added => 'Tile added to Quick Settings',
      TileRequestResult.alreadyAdded => 'The tile is already in Quick Settings',
      TileRequestResult.notAdded => 'Tile not added',
      TileRequestResult.unsupported =>
        'Swipe down twice, tap the pencil (Edit) icon and drag "Save clipboard" into your tiles',
      TileRequestResult.error => 'Could not add the tile. Add it from Quick Settings > Edit',
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(text,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('System')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
          ),
          header('Capture'),
          SwitchListTile(
            secondary: const Icon(Icons.auto_mode_outlined),
            title: const Text('Auto-save when Copy Box opens'),
            subtitle: const Text(
                'Saves new clipboard text whenever you open or return to Copy Box'),
            value: settings.autoCapture,
            onChanged: settings.setAutoCapture,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.shield_outlined),
            title: const Text('Skip passwords and codes'),
            subtitle: const Text(
                'Auto-save, the Quick Settings tile, Share and text selection skip text '
                'that looks like a password, one-time code, card number or key'),
            value: settings.skipSensitive,
            onChanged: settings.setSkipSensitive,
          ),
          ListTile(
            leading: const Icon(Icons.add_to_home_screen_outlined),
            title: const Text('Add Quick Settings tile'),
            subtitle: const Text('Save the clipboard from any app with one tap'),
            onTap: () => _addTile(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('How capture works'),
            subtitle: const Text('What Android allows, and every way to save text'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const CaptureGuideScreen())),
          ),
          header('History'),
          ListTile(
            leading: const Icon(Icons.history_toggle_off),
            title: const Text('History size'),
            subtitle: Text(_limitLabel(settings.historyLimit)),
            onTap: () => _pickLimit(context),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear history'),
            subtitle: const Text('Keeps favourites'),
            onTap: () => ClipActions.clearHistory(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
            title: Text('Delete all clips',
                style: TextStyle(color: theme.colorScheme.error)),
            subtitle: const Text('Including favourites'),
            onTap: () => ClipActions.deleteEverything(context),
          ),
          header('About'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            subtitle: const Text('No accounts, no internet, no tracking'),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PrivacyScreen())),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppInfo.name),
            subtitle: Text('Version ${AppInfo.version}'),
          ),
        ],
      ),
    );
  }
}
