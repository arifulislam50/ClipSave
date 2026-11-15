import 'package:flutter/services.dart';

/// Text received from the native side.
class CapturedClip {
  const CapturedClip({
    required this.text,
    required this.systemSensitive,
    required this.source,
    required this.capturedAt,
  });

  final String text;

  /// True when the copying app set ClipDescription.EXTRA_IS_SENSITIVE.
  final bool systemSensitive;
  final String source;
  final DateTime capturedAt;

  static CapturedClip? fromNative(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    if (text is! String) return null;
    final ts = raw['timestamp'];
    return CapturedClip(
      text: text,
      systemSensitive: raw['sensitive'] == true,
      source: raw['source'] is String ? raw['source'] as String : 'clipboard',
      capturedAt: ts is int
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.now(),
    );
  }
}

/// Result of asking Android to add the Quick Settings tile.
enum TileRequestResult { added, alreadyAdded, notAdded, unsupported, error }

/// Thin wrapper over the platform channels in MainActivity.kt.
class ClipboardBridge {
  static const MethodChannel _methods = MethodChannel('com.clipsave.app/native');
  static const EventChannel _events =
      EventChannel('com.clipsave.app/clipboard_events');

  /// Clipboard contents delivered when Copy Box gains focus or the clip changes
  /// while Copy Box is in the foreground. Listening enables native reads;
  /// cancelling the subscription disables them.
  Stream<CapturedClip> clipboardChanges() => _events
      .receiveBroadcastStream()
      .map(CapturedClip.fromNative)
      .where((c) => c != null)
      .cast<CapturedClip>();

  Future<CapturedClip?> readClipboard() async {
    try {
      return CapturedClip.fromNative(
          await _methods.invokeMethod<Object?>('readClipboard'));
    } on MissingPluginException {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.trim().isEmpty) return null;
      return CapturedClip(
        text: text,
        systemSensitive: false,
        source: 'clipboard',
        capturedAt: DateTime.now(),
      );
    } on PlatformException {
      return null;
    }
  }

  Future<List<CapturedClip>> drainInbox() async {
    try {
      final raw = await _methods.invokeMethod<List<Object?>>('drainInbox');
      if (raw == null) return const [];
      return raw
          .map(CapturedClip.fromNative)
          .whereType<CapturedClip>()
          .toList(growable: false);
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  Future<TileRequestResult> requestAddTile() async {
    try {
      switch (await _methods.invokeMethod<String>('requestAddTile')) {
        case 'added':
          return TileRequestResult.added;
        case 'already_added':
          return TileRequestResult.alreadyAdded;
        case 'not_added':
          return TileRequestResult.notAdded;
        case 'unsupported':
          return TileRequestResult.unsupported;
        default:
          return TileRequestResult.error;
      }
    } on MissingPluginException {
      return TileRequestResult.unsupported;
    } on PlatformException {
      return TileRequestResult.error;
    }
  }

  Future<int> sdkInt() async {
    try {
      return await _methods.invokeMethod<int>('sdkInt') ?? 0;
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }
  }

  /// Copies to the clipboard. With [sensitive] the native side sets
  /// EXTRA_IS_SENSITIVE so Android 13+ hides the preview and clipboard tools
  /// (including Copy Box's own auto-capture) skip it.
  Future<void> copy(String text, {bool sensitive = false}) async {
    try {
      await _methods.invokeMethod<void>(
          'copyText', <String, Object>{'text': text, 'sensitive': sensitive});
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: text));
    } on PlatformException {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }
}
