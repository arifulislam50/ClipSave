import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'state/settings_controller.dart';
import 'ui/root_shell.dart';

/// Global messenger so controller messages can show snackbars anywhere.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class ClipSaveApp extends StatelessWidget {
  const ClipSaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsController, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const RootShell(),
    );
  }
}
