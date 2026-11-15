import 'package:flutter/material.dart';

import '../data/repositories/settings_repository.dart';

/// Exposes user preferences to the UI and notifies listeners on change.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repo);

  final SettingsRepository _repo;

  ThemeMode get themeMode => _repo.themeMode;
  bool get autoCapture => _repo.autoCapture;
  bool get skipSensitive => _repo.skipSensitive;
  int get historyLimit => _repo.historyLimit;
  bool get guideDismissed => _repo.guideDismissed;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setAutoCapture(bool value) async {
    await _repo.setAutoCapture(value);
    notifyListeners();
  }

  Future<void> setSkipSensitive(bool value) async {
    await _repo.setSkipSensitive(value);
    notifyListeners();
  }

  Future<void> setHistoryLimit(int value) async {
    await _repo.setHistoryLimit(value);
    notifyListeners();
  }

  Future<void> setGuideDismissed(bool value) async {
    await _repo.setGuideDismissed(value);
    notifyListeners();
  }
}
