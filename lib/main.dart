import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/repositories/clip_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'platform/clipboard_bridge.dart';
import 'state/clips_controller.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsController(await SettingsRepository.create());
  final clips = ClipsController(
    repository: ClipRepository(AppDatabase()),
    bridge: ClipboardBridge(),
    settings: settings,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<ClipsController>.value(value: clips),
      ],
      child: const ClipSaveApp(),
    ),
  );

  unawaited(clips.init());
}
