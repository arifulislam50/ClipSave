import 'package:clipsave/platform/quick_save_bridge.dart';

/// Stands in for MainActivity's quick-save methods.
/// [nextResult] is what turning ON returns (simulating the permission dialog).
class FakeQuickSaveBridge extends QuickSaveBridge {
  FakeQuickSaveBridge({this.nativeEnabled = false, this.nextResult = QuickSaveResult.enabled});

  bool nativeEnabled;
  QuickSaveResult nextResult;
  final List<bool> calls = [];
  int settingsOpened = 0;

  @override
  Future<bool> isEnabled() async => nativeEnabled;

  @override
  Future<QuickSaveResult> setEnabled(bool enabled) async {
    calls.add(enabled);
    if (!enabled) {
      nativeEnabled = false;
      return QuickSaveResult.disabled;
    }
    nativeEnabled = nextResult == QuickSaveResult.enabled;
    return nextResult;
  }

  @override
  Future<void> openNotificationSettings() async => settingsOpened++;
}
