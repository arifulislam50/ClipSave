import 'package:clipsave/data/db/app_database.dart';
import 'package:clipsave/data/repositories/clip_repository.dart';
import 'package:clipsave/data/repositories/settings_repository.dart';
import 'package:clipsave/state/app_message.dart';
import 'package:clipsave/state/clips_controller.dart';
import 'package:clipsave/state/settings_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/fake_bridge.dart';

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late FakeBridge bridge;
  late SettingsController settings;
  late ClipsController controller;
  late List<AppMessage> messages;

  Future<void> start({bool skipSensitive = true}) async {
    SharedPreferences.setMockInitialValues({'skip_sensitive': skipSensitive});
    settings = SettingsController(await SettingsRepository.create());
    db = AppDatabase(path: inMemoryDatabasePath);
    controller = ClipsController(
        repository: ClipRepository(db), bridge: bridge, settings: settings);
    messages = [];
    controller.messages.listen(messages.add);
    await controller.init();
  }

  setUp(() => bridge = FakeBridge());

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  List<String> saved() => controller.items.map((c) => c.content).toList();

  test('inbox import filters OTPs, passwords, cards and keys from every source', () async {
    bridge.inbox = [
      clip('hello from tile'),
      clip('482913'),
      clip('Your verification code is 739201', source: 'share'),
      clip('P@ssw0rd!', source: 'select'),
      clip('4111 1111 1111 1111', source: 'tile'),
      clip('ghp_abcdefghijklmnopqrstuvwxyz0123456789', source: 'share'),
    ];
    await start();
    expect(saved(), ['hello from tile']);
    expect(controller.heldSensitiveCount, 5);
    final hold = messages.lastWhere((m) => m.hasAction);
    expect(hold.actionLabel, 'Save anyway');
  });

  test('"Save anyway" stores held items only when explicitly requested', () async {
    bridge.inbox = [clip('482913')];
    await start();
    expect(saved(), isEmpty);
    expect(await controller.saveHeldSensitive(), 1);
    expect(saved(), ['482913']);
    expect(controller.heldSensitiveCount, 0);
  });

  test('system-flagged items are held even with the heuristic filter off', () async {
    bridge.inbox = [
      clip('plain words', systemSensitive: true),
      clip('482913'),
    ];
    await start(skipSensitive: false);
    expect(saved(), ['482913']); // heuristics off, so the OTP passes
    expect(controller.heldSensitiveCount, 1); // system flag always wins
  });

  test('resume import uses the same filter', () async {
    await start();
    bridge.inbox = [clip('P@ssw0rd!'), clip('note to self', source: 'share')];
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await until(() => saved().isNotEmpty);
    expect(saved(), ['note to self']);
    expect(controller.heldSensitiveCount, 1);
  });

  test('focus auto-capture applies the same filter', () async {
    await start();
    bridge.events.add(clip('739201', source: 'auto'));
    bridge.events.add(clip('secret', source: 'auto', systemSensitive: true));
    bridge.events.add(clip('buy milk', source: 'auto'));
    await until(() => saved().isNotEmpty);
    expect(saved(), ['buy milk']);
  });

  test('auto-save skip offers "Save anyway" and stores only on request', () async {
    await start();
    bridge.events.add(clip('482913', source: 'auto'));
    await until(() => controller.heldSensitiveCount == 1);
    final held = messages.lastWhere((m) => m.hasAction);
    expect(held.actionLabel, 'Save anyway');
    expect(saved(), isEmpty);
    held.onAction!();
    await until(() => saved().isNotEmpty);
    expect(saved(), ['482913']);
  });

  test('manual save asks before storing sensitive text', () async {
    await start();
    bridge.clipboard = clip('482913', source: 'clipboard');
    final first = await controller.captureClipboard();
    expect(first.kind, CaptureKind.sensitive);
    expect(saved(), isEmpty);
    final forced = await controller.captureClipboard(force: true);
    expect(forced.kind, CaptureKind.saved);
    expect(saved(), ['482913']);
  });

  test('copying a secret marks the clip sensitive', () async {
    bridge.inbox = [clip('shopping list', source: 'share')];
    await start();
    await controller.copy(controller.items.single);
    await controller.addClip('P@ssw0rd!');
    await controller.copy(controller.items.firstWhere((c) => c.content == 'P@ssw0rd!'));
    expect(bridge.copies, [('shopping list', false), ('P@ssw0rd!', true)]);
  });
}
