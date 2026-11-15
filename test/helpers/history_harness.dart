import 'package:clipsave/core/theme/app_theme.dart';
import 'package:clipsave/data/db/app_database.dart';
import 'package:clipsave/data/repositories/clip_repository.dart';
import 'package:clipsave/data/repositories/settings_repository.dart';
import 'package:clipsave/state/clips_controller.dart';
import 'package:clipsave/state/settings_controller.dart';
import 'package:clipsave/ui/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_bridge.dart';

/// Pumps the real HistoryScreen against an in-memory SQLite database and a
/// fake native bridge. Database work runs inside `tester.runAsync`.
class HistoryHarness {
  HistoryHarness._(this.controller, this.settings, this.bridge, this._db);

  final ClipsController controller;
  final SettingsController settings;
  final FakeBridge bridge;
  final AppDatabase _db;

  static bool _ffiReady = false;

  static Future<HistoryHarness> pump(
    WidgetTester tester, {
    List<String> clips = const [],
    bool autoCapture = true,
  }) async {
    if (!_ffiReady) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiReady = true;
    }
    SharedPreferences.setMockInitialValues({'auto_capture': autoCapture});
    final bridge = FakeBridge();
    late HistoryHarness harness;
    await tester.runAsync(() async {
      final settings = SettingsController(await SettingsRepository.create());
      final db = AppDatabase(path: inMemoryDatabasePath);
      final controller = ClipsController(
          repository: ClipRepository(db), bridge: bridge, settings: settings);
      await controller.init();
      for (final text in clips.reversed) {
        await controller.addClip(text);
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      harness = HistoryHarness._(controller, settings, bridge, db);
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: harness.settings),
        ChangeNotifierProvider<ClipsController>.value(value: harness.controller),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const HistoryScreen()),
    ));
    await tester.pump();
    return harness;
  }

  /// Lets real async work (database, fake bridge) finish, then rebuilds.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(_db.close);
  }
}
