import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/repositories/settings_repository.dart';
import '../platform/quick_save_bridge.dart';

/// Exposes user preferences to the UI and notifies listeners on change.
///
/// Can be created before SharedPreferences is loaded (so `runApp` is not
/// delayed): until [load] completes, getters return the defaults (dark theme,
/// auto-save on, skip sensitive on, default history size, quick-save off).
///
/// The quick-save notification state is owned by the native side (so
/// BootReceiver can read it); [quickSaveEnabled] mirrors its REAL state
/// (setting on AND notification permission granted), refreshed on load and
/// whenever the app resumes (e.g. back from system notification settings).
class SettingsController extends ChangeNotifier with WidgetsBindingObserver {
  SettingsController([SettingsRepository? repository, QuickSaveBridge? quickSave])
      : _repo = repository,
        _quickSave = quickSave ?? QuickSaveBridge();

  SettingsRepository? _repo;
  final QuickSaveBridge _quickSave;
  Future<void>? _loading;
  bool _loaded = false;
  bool _quickSaveEnabled = false;

  bool get isLoaded => _loaded;

  /// Loads preferences and the quick-save state once; safe to call repeatedly.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    _repo ??= await SettingsRepository.create();
    _quickSaveEnabled = await _quickSave.isEnabled();
    _loaded = true;
    WidgetsBinding.instance.addObserver(this);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshQuickSave();
  }

  @override
  void dispose() {
    if (_loaded) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ------------------------------------------------- quick-save notification --

  bool get quickSaveEnabled => _quickSaveEnabled;
  bool get quickSavePromptDismissed => _repo?.quickSavePromptDismissed ?? false;

  /// History card: only once loaded, while the notification is off and the
  /// user has not chosen "Not now" before.
  bool get showQuickSavePrompt =>
      _loaded && !_quickSaveEnabled && !quickSavePromptDismissed;

  Future<void> refreshQuickSave() async {
    final enabled = await _quickSave.isEnabled();
    if (enabled != _quickSaveEnabled) {
      _quickSaveEnabled = enabled;
      notifyListeners();
    }
  }

  /// Turning on may show the Android 13+ permission dialog; if it is denied,
  /// the switch stays/turns off and the caller offers system settings.
  Future<QuickSaveResult> setQuickSave(bool enabled) async {
    final result = await _quickSave.setEnabled(enabled);
    _quickSaveEnabled = result == QuickSaveResult.enabled;
    notifyListeners();
    return result;
  }

  Future<void> openNotificationSettings() => _quickSave.openNotificationSettings();

  Future<void> dismissQuickSavePrompt() async {
    await (await _ready()).setQuickSavePromptDismissed(true);
    notifyListeners();
  }

  Future<SettingsRepository> _ready() async {
    if (_repo != null) return _repo!;
    await load();
    return _repo!;
  }

  ThemeMode get themeMode => _repo?.themeMode ?? ThemeMode.dark;
  bool get autoCapture => _repo?.autoCapture ?? true;
  bool get skipSensitive => _repo?.skipSensitive ?? true;
  int get historyLimit => _repo?.historyLimit ?? AppInfo.defaultHistoryLimit;
  bool get guideDismissed => _repo?.guideDismissed ?? false;

  Future<void> setThemeMode(ThemeMode mode) async {
    await (await _ready()).setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setAutoCapture(bool value) async {
    await (await _ready()).setAutoCapture(value);
    notifyListeners();
  }

  Future<void> setSkipSensitive(bool value) async {
    await (await _ready()).setSkipSensitive(value);
    notifyListeners();
  }

  Future<void> setHistoryLimit(int value) async {
    await (await _ready()).setHistoryLimit(value);
    notifyListeners();
  }

  Future<void> setGuideDismissed(bool value) async {
    await (await _ready()).setGuideDismissed(value);
    notifyListeners();
  }
}
