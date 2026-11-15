import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/utils/content_classifier.dart';
import '../data/models/clip_filter.dart';
import '../platform/window_bridge.dart';
import '../state/app_message.dart';
import '../state/clips_controller.dart';
import 'screens/folders_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/ad_banner.dart';

/// Bottom navigation: History, Folders, Settings.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  StreamSubscription<AppMessage>? _messageSub;

  @override
  void initState() {
    super.initState();
    // First touch of the database and clipboard happens here, after the splash.
    // Auto-capture starts listening inside init(), so auto-save still runs
    // as soon as the history screen is shown.
    unawaited(context.read<ClipsController>().init());
    _messageSub = context.read<ClipsController>().messages.listen((message) {
      rootMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(message.text),
          duration: Duration(seconds: message.hasAction ? 8 : 4),
          action: message.hasAction
              ? SnackBarAction(
                  label: message.actionLabel!, onPressed: message.onAction!)
              : null,
        ));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The native window starts pink (no flash at start-up). From here on it
    // follows the app theme (black in dark mode), so nothing light can show
    // behind Flutter, e.g. while the keyboard resizes the window.
    WindowBridge.setBackground(Theme.of(context).colorScheme.surface);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _showHistory(ClipFilter filter) {
    context.read<ClipsController>().setFilter(filter);
    setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    // Each tab has its own Scaffold so snackbars sit above that tab's FAB.
    // The navigation bar handles the bottom system inset for them.
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: IndexedStack(
              index: _index,
              children: [
                const HistoryScreen(),
                FoldersScreen(
                  onOpenFolder: (id) => _showHistory(ClipFilter.folder(id)),
                  onOpenCategory: (ClipCategory c) => _showHistory(ClipFilter.category(c)),
                ),
                const SettingsScreen(),
              ],
            ),
          ),
        ),
        // Banner on History (0) and Folders (1) only, between the tab content
        // and the navigation bar, so each tab's FAB always sits above it.
        // Not on Settings, the editor (a pushed route), splash or capture.
        if (_index != 2) const AdaptiveBanner(key: ValueKey<String>('banner')),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: 'Folders',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
