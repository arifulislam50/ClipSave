import 'package:flutter/services.dart';

/// Sets the native Android window background behind the Flutter UI.
class WindowBridge {
  WindowBridge._();

  static const MethodChannel _methods = MethodChannel('com.clipsave.app/native');
  static int? _last;

  static Future<void> setBackground(Color color) async {
    final argb = color.toARGB32();
    if (argb == _last) return;
    _last = argb;
    try {
      await _methods.invokeMethod<void>('setWindowBackground', <String, Object>{'color': argb});
    } on MissingPluginException {
      // Not on Android (tests): nothing to do.
    } on PlatformException {
      _last = null;
    }
  }
}
