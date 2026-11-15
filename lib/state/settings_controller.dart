import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/repositories/settings_repository.dart';

/// Exposes user preferences to the UI and notifies listeners on change.
///
/// Can be created before SharedPreferences is loaded (so `runApp` is not
/// delayed): until [load] completes, getters return the defaults (dark theme,
/// auto-save on, skip sensitive on, default history size).
class SettingsController extends ChangeNotifier {
  SettingsController([SettingsRepository? repository]) : _repo = repository;

  SettingsRepository? _repo;
  Future<void>? _loading;

  bool get isLoaded => _repo != null;

  /// Loads preferences once; safe to call from several places.
  Future<void> load() {
    if (_repo != null) return Future<void>.value();
    return _loading ??= SettingsRepository.create().then((repo) {
      _repo = repo;
      notifyListeners();
    });
  }

  Future<SettingsRepository> _ready() async {
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
