import 'dart:async';

import 'package:clipsave/platform/clipboard_bridge.dart';

/// Stands in for the Kotlin side so capture paths can be tested on the host.
class FakeBridge extends ClipboardBridge {
  final StreamController<CapturedClip> events =
      StreamController<CapturedClip>.broadcast();
  List<CapturedClip> inbox = [];
  CapturedClip? clipboard;
  final List<(String, bool)> copies = [];

  @override
  Stream<CapturedClip> clipboardChanges() => events.stream;

  @override
  Future<List<CapturedClip>> drainInbox() async {
    final out = inbox;
    inbox = [];
    return out;
  }

  @override
  Future<CapturedClip?> readClipboard() async => clipboard;

  @override
  Future<void> copy(String text, {bool sensitive = false}) async =>
      copies.add((text, sensitive));

  @override
  Future<int> sdkInt() async => 34;

  @override
  Future<TileRequestResult> requestAddTile() async => TileRequestResult.added;
}

CapturedClip clip(String text, {String source = 'tile', bool systemSensitive = false}) =>
    CapturedClip(
      text: text,
      systemSensitive: systemSensitive,
      source: source,
      capturedAt: DateTime.now(),
    );

