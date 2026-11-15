import 'package:clipsave/core/theme/app_theme.dart';
import 'package:clipsave/platform/quick_save_bridge.dart';
import 'package:clipsave/state/settings_controller.dart';
import 'package:clipsave/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_quick_save_bridge.dart';

Future<SettingsController> _pump(WidgetTester tester, FakeQuickSaveBridge bridge) async {
  SharedPreferences.setMockInitialValues({});
  final settings = SettingsController(null, bridge);
  await tester.runAsync(settings.load);
  await tester.pumpWidget(ChangeNotifierProvider<SettingsController>.value(
    value: settings,
    child: MaterialApp(theme: AppTheme.dark(), home: const SettingsScreen()),
  ));
  await tester.pump();
  return settings;
}

SwitchListTile _row(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byKey(const ValueKey<String>('quick-save-switch')));

void main() {
  testWidgets('Quick-save notification row exists in CAPTURE and is off by default',
      (tester) async {
    await _pump(tester, FakeQuickSaveBridge());
    expect(find.text('CAPTURE'), findsOneWidget);
    expect(find.text('Quick-save notification'), findsOneWidget);
    expect(
        find.text('Shows a Save button in the notification shade. Tap it after you copy something.'),
        findsOneWidget);
    expect(_row(tester).value, isFalse);
  });

  testWidgets('turning it on (granted) shows it on', (tester) async {
    final bridge = FakeQuickSaveBridge();
    await _pump(tester, bridge);
    await tester.tap(find.byKey(const ValueKey<String>('quick-save-switch')));
    await tester.pump();
    await tester.pump();
    expect(bridge.calls, [true]);
    expect(_row(tester).value, isTrue);
  });

  testWidgets('permission denied: switch stays off, snackbar offers Open settings',
      (tester) async {
    final bridge = FakeQuickSaveBridge(nextResult: QuickSaveResult.denied);
    await _pump(tester, bridge);
    await tester.tap(find.byKey(const ValueKey<String>('quick-save-switch')));
    await tester.pump();
    await tester.pump();
    expect(_row(tester).value, isFalse);
    expect(find.widgetWithText(SnackBarAction, 'Open settings'), findsOneWidget);
    await tester.tap(find.widgetWithText(SnackBarAction, 'Open settings'));
    await tester.pump();
    expect(bridge.settingsOpened, 1);
  });

  testWidgets('switch reflects the real (native) state', (tester) async {
    await _pump(tester, FakeQuickSaveBridge(nativeEnabled: true));
    expect(_row(tester).value, isTrue);
  });
}
