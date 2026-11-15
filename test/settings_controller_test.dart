import 'package:clipsave/core/constants.dart';
import 'package:clipsave/data/repositories/settings_repository.dart';
import 'package:clipsave/platform/quick_save_bridge.dart';
import 'package:clipsave/state/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_quick_save_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsController> controller(FakeQuickSaveBridge bridge,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final c = SettingsController(null, bridge);
    await c.load();
    return c;
  }

  group('quick-save notification setting', () {
    test('off by default', () async {
      final c = await controller(FakeQuickSaveBridge());
      expect(c.quickSaveEnabled, isFalse);
    });

    test('turning on (permission granted) posts it; off cancels it', () async {
      final bridge = FakeQuickSaveBridge();
      final c = await controller(bridge);
      expect(await c.setQuickSave(true), QuickSaveResult.enabled);
      expect(c.quickSaveEnabled, isTrue);
      expect(await c.setQuickSave(false), QuickSaveResult.disabled);
      expect(c.quickSaveEnabled, isFalse);
      expect(bridge.calls, [true, false]);
    });

    test('permission denied turns it back off', () async {
      final c = await controller(FakeQuickSaveBridge(nextResult: QuickSaveResult.denied));
      expect(await c.setQuickSave(true), QuickSaveResult.denied);
      expect(c.quickSaveEnabled, isFalse);
    });

    test('"don\'t ask again" is handled the same way', () async {
      final bridge = FakeQuickSaveBridge(nextResult: QuickSaveResult.permanentlyDenied);
      final c = await controller(bridge);
      expect(await c.setQuickSave(true), QuickSaveResult.permanentlyDenied);
      expect(c.quickSaveEnabled, isFalse);
      await c.openNotificationSettings();
      expect(bridge.settingsOpened, 1);
    });

    test('shows the real native state on load and after resume', () async {
      final bridge = FakeQuickSaveBridge(nativeEnabled: true);
      final c = await controller(bridge);
      expect(c.quickSaveEnabled, isTrue);
      bridge.nativeEnabled = false; // e.g. permission revoked in system settings
      await c.refreshQuickSave();
      expect(c.quickSaveEnabled, isFalse);
    });
  });

  group('History quick-save card', () {
    test('shown while off and not dismissed; hidden once on', () async {
      final c = await controller(FakeQuickSaveBridge());
      expect(c.showQuickSavePrompt, isTrue);
      await c.setQuickSave(true);
      expect(c.showQuickSavePrompt, isFalse);
    });

    test('"Not now" is remembered across restarts', () async {
      final c = await controller(FakeQuickSaveBridge());
      await c.dismissQuickSavePrompt();
      expect(c.showQuickSavePrompt, isFalse);
      // A fresh controller reading the same stored preferences.
      final repo = await SettingsRepository.create();
      expect(repo.quickSavePromptDismissed, isTrue);
      final again = SettingsController(repo, FakeQuickSaveBridge());
      await again.load();
      expect(again.showQuickSavePrompt, isFalse);
    });

    test('not shown before settings are loaded', () {
      final c = SettingsController(null, FakeQuickSaveBridge());
      expect(c.showQuickSavePrompt, isFalse);
    });
  });

  test('source label "Notification"', () {
    expect(ClipSources.notification, 'notification');
    expect(ClipSources.label(ClipSources.notification), 'Notification');
    expect(ClipSources.label(ClipSources.tile), 'Quick tile');
  });
}
