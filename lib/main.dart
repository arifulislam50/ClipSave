import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/repositories/clip_repository.dart';
import 'platform/clipboard_bridge.dart';
import 'state/clips_controller.dart';
import 'state/settings_controller.dart';

/// Start-up order (fast first frame):
///  1. main(): only binding + cheap object construction, then runApp.
///  2. Splash (first frame): loads settings and opens the database in
///     parallel; ads consent + Mobile Ads start in the background, never
///     awaited by the splash.
///  3. RootShell (history shown): ClipsController.init() imports the inbox,
///     loads the first 50 clips and only then enables auto-capture, so the
///     clipboard is never read before the history screen is visible.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsController(); // preferences load during the splash
  final clips = ClipsController(
    repository: ClipRepository(AppDatabase()), // opened lazily, during the splash
    bridge: ClipboardBridge(),
    settings: settings,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<ClipsController>.value(value: clips),
      ],
      child: const CopyBoxApp(),
    ),
  );

  // Draw behind transparent system bars (the default on Android 15+).
  // Not awaited: it must not delay the first frame.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
}
