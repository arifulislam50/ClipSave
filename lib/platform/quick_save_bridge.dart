import 'package:flutter/services.dart';

/// Outcome of turning the quick-save notification on or off.
enum QuickSaveResult {
  /// Notification posted and setting stored on.
  enabled,

  /// Setting stored off and notification cancelled.
  disabled,

  /// The user denied POST_NOTIFICATIONS (Android 13+); the setting is off.
  denied,

  /// Denied with "don't ask again" (or blocked); only system settings can fix it.
  permanentlyDenied,

  /// No native side (tests, other platforms).
  unsupported,
}

/// Dart side of the quick-save notification methods in MainActivity.kt.
/// The on/off state is stored natively so BootReceiver can read it.
class QuickSaveBridge {
  static const MethodChannel _methods = MethodChannel('com.clipsave.app/native');

  /// Real state: setting on AND notifications allowed.
  Future<bool> isEnabled() async {
    try {
      final status = await _methods.invokeMapMethod<String, Object?>('quickSaveStatus');
      return status?['enabled'] == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Turning on may show the Android 13+ notification permission dialog.
  Future<QuickSaveResult> setEnabled(bool enabled) async {
    try {
      final r = await _methods
          .invokeMapMethod<String, Object?>('setQuickSave', <String, Object>{'enabled': enabled});
      if (r?['enabled'] == true) return QuickSaveResult.enabled;
      if (r?['permanentlyDenied'] == true) return QuickSaveResult.permanentlyDenied;
      if (r?['denied'] == true) return QuickSaveResult.denied;
      return QuickSaveResult.disabled;
    } on MissingPluginException {
      return QuickSaveResult.unsupported;
    } on PlatformException {
      return QuickSaveResult.disabled;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _methods.invokeMethod<void>('openNotificationSettings');
    } on MissingPluginException {
      // Nothing to open in tests.
    } on PlatformException {
      // Settings app unavailable: nothing else to do.
    }
  }
}
