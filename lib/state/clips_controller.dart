import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/sensitive_detector.dart';
import '../data/models/clip_filter.dart';
import '../data/models/clip_item.dart';
import '../data/models/folder.dart';
import '../data/repositories/clip_repository.dart';
import '../platform/clipboard_bridge.dart';
import 'app_message.dart';
import 'settings_controller.dart';

enum CaptureKind { saved, alreadySaved, empty, tooLong, sensitive }

/// Outcome of the manual "Save clipboard" action.
class CaptureOutcome {
  const CaptureOutcome(this.kind, {this.reason});
  final CaptureKind kind;
  final SensitiveReason? reason;

  String get message {
    switch (kind) {
      case CaptureKind.saved:
        return 'Clipboard saved';
      case CaptureKind.alreadySaved:
        return 'Already saved: moved to the top';
      case CaptureKind.empty:
        return 'Clipboard is empty or not text';
      case CaptureKind.tooLong:
        return 'Text is too long to save';
      case CaptureKind.sensitive:
        return reason?.explanation ?? 'This looks sensitive.';
    }
  }
}

/// Owns the clip list, search, filters, folders and all capture paths.
///
/// Security invariant: every path that stores text WITHOUT the user seeing it
/// first (focus auto-capture and the native inbox: Quick Settings tile, share,
/// text selection) goes through [_autoFilterReason] before [ClipRepository.saveText].
/// Only explicit in-app actions (typing in the editor, or confirming
/// "Save anyway") bypass it.
class ClipsController extends ChangeNotifier with WidgetsBindingObserver {
  ClipsController({
    required ClipRepository repository,
    required ClipboardBridge bridge,
    required SettingsController settings,
  })  : _repo = repository,
        _bridge = bridge,
        _settings = settings;

  /// Held (unsaved) sensitive inbox items are kept in memory only, for this long.
  static const Duration heldSensitiveLifetime = Duration(minutes: 2);

  final ClipRepository _repo;
  final ClipboardBridge _bridge;
  final SettingsController _settings;

  final StreamController<AppMessage> _messages =
      StreamController<AppMessage>.broadcast();

  /// One-off messages for the UI to show as snackbars.
  Stream<AppMessage> get messages => _messages.stream;

  List<ClipItem> _items = const [];
  List<Folder> _folders = const [];
  String _query = '';
  ClipFilter _filter = ClipFilter.all;
  bool _loading = true;
  int _sdkInt = 0;
  int _lastLimit = -1;

  StreamSubscription<CapturedClip>? _autoSub;
  Timer? _searchDebounce;
  Timer? _heldTimer;
  String? _lastSelfCopy;
  bool _initialized = false;
  bool _disposed = false;
  bool _importing = false;
  final List<CapturedClip> _heldSensitive = [];

  List<ClipItem> get items => _items;
  List<Folder> get folders => _folders;
  String get query => _query;
  ClipFilter get filter => _filter;
  bool get loading => _loading;
  int get sdkInt => _sdkInt;
  int get heldSensitiveCount => _heldSensitive.length;

  Folder? folderById(int? id) {
    if (id == null) return null;
    for (final f in _folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  // ------------------------------------------------------------ lifecycle --

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _lastLimit = _settings.historyLimit;
    _settings.addListener(_onSettingsChanged);
    _sdkInt = await _bridge.sdkInt();
    try {
      await _repo.prune(_settings.historyLimit);
      await _importInbox();
      await refresh();
    } catch (_) {
      _loading = false;
      _notify();
      _say(const AppMessage('Could not open clip history. Restart ClipSave to retry.'));
      return; // Don't auto-capture into a database that failed to open.
    }
    _syncAutoCapture();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_importInbox());
    }
  }

  void _onSettingsChanged() {
    _syncAutoCapture();
    final limit = _settings.historyLimit;
    if (limit != _lastLimit) {
      _lastLimit = limit;
      unawaited(_repo.prune(limit).then((_) => refresh()));
    }
  }

  /// Listening to the event channel is what enables native reads, so turning
  /// auto-capture off really stops ClipSave from touching the clipboard.
  void _syncAutoCapture() {
    final wanted = _settings.autoCapture;
    if (wanted && _autoSub == null) {
      _autoSub = _bridge.clipboardChanges().listen(
            _onAutoCaptured,
            onError: (Object _) {},
          );
    } else if (!wanted && _autoSub != null) {
      unawaited(_autoSub!.cancel());
      _autoSub = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    _autoSub?.cancel();
    _searchDebounce?.cancel();
    _heldTimer?.cancel();
    _heldSensitive.clear();
    _messages.close();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _say(AppMessage message) {
    if (!_messages.isClosed) _messages.add(message);
  }

  Future<void> refresh() async {
    final folders = await _repo.folders();
    // If the filtered folder was deleted, fall back to everything.
    if (_filter.kind == FilterKind.folder &&
        !folders.any((f) => f.id == _filter.folderId)) {
      _filter = ClipFilter.all;
    }
    final items = await _repo.query(search: _query, filter: _filter);
    _folders = folders;
    _items = items;
    _loading = false;
    _notify();
  }

  // -------------------------------------------------------------- capture --

  /// The single sensitivity gate for automatic storage.
  /// System-flagged clips are always refused; heuristics follow the setting.
  SensitiveReason? _autoFilterReason(CapturedClip clip) {
    if (clip.systemSensitive) return SensitiveReason.flaggedBySystem;
    if (_settings.skipSensitive) return SensitiveDetector.detect(clip.text);
    return null;
  }

  Future<void> _onAutoCaptured(CapturedClip clip) async {
    final text = clip.text;
    if (text.trim().isEmpty || text == _lastSelfCopy) return;
    if (text.length > AppInfo.maxClipLength) return;
    final reason = _autoFilterReason(clip);
    if (reason != null) {
      // Still on the clipboard; the user can save it deliberately.
      _say(AppMessage('Not saved automatically. ${reason.explanation} '
          'Tap "Save clipboard" to keep it.'));
      return;
    }
    final result = await _store(text, source: ClipSources.auto);
    if (result != null && result.created) {
      _say(const AppMessage('Saved from clipboard'));
    }
  }

  /// Manual "Save clipboard". With [force] the sensitivity check is skipped
  /// after the user confirmed.
  Future<CaptureOutcome> captureClipboard({bool force = false}) async {
    final clip = await _bridge.readClipboard();
    if (clip == null || clip.text.trim().isEmpty) {
      return const CaptureOutcome(CaptureKind.empty);
    }
    if (clip.text.length > AppInfo.maxClipLength) {
      return const CaptureOutcome(CaptureKind.tooLong);
    }
    if (!force) {
      // Manual saves always ask, regardless of the skip setting.
      final reason = clip.systemSensitive
          ? SensitiveReason.flaggedBySystem
          : SensitiveDetector.detect(clip.text);
      if (reason != null) {
        return CaptureOutcome(CaptureKind.sensitive, reason: reason);
      }
    }
    final result = await _store(clip.text, source: ClipSources.clipboard);
    if (result == null) return const CaptureOutcome(CaptureKind.empty);
    return CaptureOutcome(
        result.created ? CaptureKind.saved : CaptureKind.alreadySaved);
  }

  /// Imports items queued natively by the tile, share sheet and selection
  /// menu, applying the same sensitivity gate as focus auto-capture.
  Future<void> _importInbox() async {
    if (_importing) return;
    _importing = true;
    try {
      final queued = await _bridge.drainInbox();
      if (queued.isEmpty) return;

      final savedSources = <String>[];
      final held = <CapturedClip>[];
      for (final clip in queued) {
        if (clip.text.trim().isEmpty ||
            clip.text.length > AppInfo.maxClipLength) {
          continue;
        }
        if (_autoFilterReason(clip) != null) {
          held.add(clip);
          continue;
        }
        await _repo.saveText(clip.text, source: clip.source);
        savedSources.add(clip.source);
      }

      if (savedSources.isNotEmpty) {
        await _repo.prune(_settings.historyLimit);
        await refresh();
        _say(AppMessage(savedSources.length == 1
            ? 'Saved 1 item from ${ClipSources.label(savedSources.first).toLowerCase()}'
            : 'Saved ${savedSources.length} items'));
      }
      if (held.isNotEmpty) _holdSensitive(held);
    } finally {
      _importing = false;
    }
  }

  /// Keeps skipped inbox items in memory (never on disk) briefly, so the user
  /// can deliberately save them from the snackbar.
  void _holdSensitive(List<CapturedClip> clips) {
    _heldSensitive
      ..clear()
      ..addAll(clips);
    _heldTimer?.cancel();
    _heldTimer = Timer(heldSensitiveLifetime, _heldSensitive.clear);
    final String text;
    if (clips.length == 1) {
      final first = clips.first;
      final reason = first.systemSensitive
          ? SensitiveReason.flaggedBySystem
          : SensitiveDetector.detect(first.text);
      text = 'Not saved. ${reason?.explanation ?? 'This looks sensitive.'}';
    } else {
      text = 'Not saved: ${clips.length} items look like passwords or codes';
    }
    _say(AppMessage(
      text,
      actionLabel: 'Save anyway',
      onAction: () => unawaited(saveHeldSensitive()),
    ));
  }

  /// Saves items held by [_holdSensitive]. Only called from an explicit tap.
  Future<int> saveHeldSensitive() async {
    if (_heldSensitive.isEmpty) return 0;
    final clips = List<CapturedClip>.of(_heldSensitive);
    _heldSensitive.clear();
    _heldTimer?.cancel();
    for (final clip in clips) {
      await _repo.saveText(clip.text, source: clip.source);
    }
    await _repo.prune(_settings.historyLimit);
    await refresh();
    return clips.length;
  }

  Future<SaveResult?> _store(String text,
      {required String source, int? folderId}) async {
    if (text.trim().isEmpty) return null;
    final result = await _repo.saveText(text,
        source: source, folderId: _validFolder(folderId));
    await _repo.prune(_settings.historyLimit);
    await refresh();
    return result;
  }

  /// Drops a folder id that no longer exists (avoids a foreign-key failure).
  int? _validFolder(int? folderId) =>
      folderId != null && folderById(folderId) != null ? folderId : null;

  // ---------------------------------------------------------- clip edits --

  /// Adds typed text. Returns null if empty or too long.
  Future<SaveResult?> addClip(String text, {int? folderId}) async {
    if (text.length > AppInfo.maxClipLength) return null;
    return _store(text, source: ClipSources.manual, folderId: folderId);
  }

  /// Returns false if another clip already has exactly this text.
  Future<bool> updateClip(ClipItem item, String text, {int? folderId}) async {
    if (item.id == null ||
        text.trim().isEmpty ||
        text.length > AppInfo.maxClipLength) {
      return false;
    }
    try {
      await _repo.updateContent(item.id!, text, folderId: _validFolder(folderId));
    } on DuplicateClipException {
      return false;
    }
    await refresh();
    return true;
  }

  Future<void> toggleFavorite(ClipItem item) async {
    if (item.id == null) return;
    await _repo.setFavorite(item.id!, !item.isFavorite);
    await refresh();
  }

  Future<void> moveToFolder(ClipItem item, int? folderId) async {
    if (item.id == null) return;
    await _repo.moveToFolder(item.id!, _validFolder(folderId));
    await refresh();
  }

  Future<void> delete(ClipItem item) async {
    if (item.id == null) return;
    // Remove from the visible list synchronously (Dismissible requires it).
    _items = _items.where((c) => c.id != item.id).toList(growable: false);
    _notify();
    await _repo.delete(item.id!);
    await refresh();
  }

  Future<void> restore(ClipItem item) async {
    await _repo.restore(item);
    await refresh();
  }

  Future<int> clearHistory({required bool keepFavorites}) async {
    final n = await _repo.clear(keepFavorites: keepFavorites);
    await refresh();
    return n;
  }

  /// Copies to the clipboard, flagging likely secrets as sensitive.
  /// Returns true when the app should show its own confirmation
  /// (Android 13+ already shows a system one).
  Future<bool> copy(ClipItem item) async {
    _lastSelfCopy = item.content;
    await _bridge.copy(item.content,
        sensitive: SensitiveDetector.detect(item.content) != null);
    return _sdkInt < 33;
  }

  // ------------------------------------------------------ search & filter --

  void setQuery(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), refresh);
  }

  void setFilter(ClipFilter value) {
    if (value == _filter) return;
    _filter = value;
    unawaited(refresh());
  }

  // -------------------------------------------------------------- folders --

  Future<Folder?> createFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final color = AppTheme
        .folderColors[_folders.length % AppTheme.folderColors.length]
        .toARGB32();
    final folder = await _repo.createFolder(trimmed, color);
    await refresh();
    return folder;
  }

  Future<bool> renameFolder(Folder folder, String name) async {
    final trimmed = name.trim();
    if (folder.id == null || trimmed.isEmpty) return false;
    final ok = await _repo.renameFolder(folder.id!, trimmed);
    await refresh();
    return ok;
  }

  Future<void> deleteFolder(Folder folder) async {
    if (folder.id == null) return;
    await _repo.deleteFolder(folder.id!);
    await refresh();
  }

  // ------------------------------------------------------- quick settings --

  Future<TileRequestResult> requestAddTile() => _bridge.requestAddTile();
}
