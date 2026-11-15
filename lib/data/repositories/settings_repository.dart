import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

/// Persists user preferences (never clip content) in SharedPreferences.
class SettingsRepository {
  SettingsRepository._(this._prefs);

  static Future<SettingsRepository> create() async =>
      SettingsRepository._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _kTheme = 'theme_mode';
  static const _kAutoCapture = 'auto_capture';
  static const _kSkipSensitive = 'skip_sensitive';
  static const _kHistoryLimit = 'history_limit';
  static const _kGuideDismissed = 'guide_dismissed';

  /// Defaults to dark until the user picks something; a saved choice
  /// (including "system") is always restored.
  ThemeMode get themeMode {
    switch (_prefs.getString(_kTheme)) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kTheme, mode.name);

  bool get autoCapture => _prefs.getBool(_kAutoCapture) ?? true;
  Future<void> setAutoCapture(bool v) => _prefs.setBool(_kAutoCapture, v);

  bool get skipSensitive => _prefs.getBool(_kSkipSensitive) ?? true;
  Future<void> setSkipSensitive(bool v) => _prefs.setBool(_kSkipSensitive, v);

  int get historyLimit =>
      _prefs.getInt(_kHistoryLimit) ?? AppInfo.defaultHistoryLimit;
  Future<void> setHistoryLimit(int v) => _prefs.setInt(_kHistoryLimit, v);

  bool get guideDismissed => _prefs.getBool(_kGuideDismissed) ?? false;
  Future<void> setGuideDismissed(bool v) => _prefs.setBool(_kGuideDismissed, v);
}
