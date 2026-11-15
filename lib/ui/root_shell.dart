import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/models/clip_filter.dart';
import '../state/app_message.dart';
import '../state/clips_controller.dart';
import 'screens/folders_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

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
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _openFolder(int folderId) {
    context.read<ClipsController>().setFilter(ClipFilter.folder(folderId));
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
                FoldersScreen(onOpenFolder: _openFolder),
                const SettingsScreen(),
              ],
            ),
          ),
        ),
        NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Folders',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ],
    );
  }
}
