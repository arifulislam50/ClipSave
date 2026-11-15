/// App-wide constants.
class AppInfo {
  AppInfo._();

  static const String name = 'Copy Box';
  static const String version = '1.0.0';

  /// Nominal splash length (the progress bar fills over this time).
  static const Duration splashDuration = Duration(seconds: 2);

  /// The splash ends as soon as initialisation is done AND this has passed...
  static const Duration splashMinDuration = Duration(milliseconds: 1500);

  /// ...and never later than this, even if something is still loading (it
  /// keeps loading in the background).
  static const Duration splashMaxDuration = Duration(seconds: 3);

  /// Minimum splash length when the system asks for reduced motion.
  static const Duration reducedMotionSplashDuration = Duration(seconds: 1);

  /// Clips longer than this are refused, to keep the database small and fast.
  static const int maxClipLength = 100000;

  /// History limits offered in Settings. 0 means unlimited.
  static const List<int> historyLimitOptions = [100, 250, 500, 1000, 0];
  static const int defaultHistoryLimit = 500;
}

/// Where a clip came from. Stored in the `source` column.
class ClipSources {
  ClipSources._();

  static const String auto = 'auto';
  static const String clipboard = 'clipboard';
  static const String manual = 'manual';
  static const String share = 'share';
  static const String select = 'select';
  static const String tile = 'tile';
  static const String notification = 'notification';

  static String label(String source) {
    switch (source) {
      case auto:
        return 'Auto-saved';
      case clipboard:
        return 'Clipboard';
      case manual:
        return 'Typed';
      case share:
        return 'Shared';
      case select:
        return 'Text selection';
      case tile:
        return 'Quick tile';
      case notification:
        return 'Notification';
      default:
        return 'Saved';
    }
  }
}
