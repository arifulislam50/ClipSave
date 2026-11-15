/// AdMob configuration: the only place ad IDs are defined in Dart.
///
/// These are Google's official TEST IDs. They always serve test ads and earn
/// nothing.
///
/// TODO(release): replace with my real AdMob IDs before release:
///   1. [androidAppId] below AND the matching
///      `com.google.android.gms.ads.APPLICATION_ID` meta-data in
///      android/app/src/main/AndroidManifest.xml. Android reads the App ID
///      from the manifest; `tool/check_structure.py` fails if the two differ.
///   2. [bannerAdUnitId] below.
/// Never click your own live ads while testing (AdMob may flag the account).
class AdConfig {
  AdConfig._();

  /// Google's sample AdMob App ID for Android.
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Google's sample adaptive banner ad unit for Android.
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/9214589741';

  static const String _googleTestPublisher = 'ca-app-pub-3940256099942544';

  /// True while the test IDs above are still in place.
  static bool get usingTestIds =>
      androidAppId.startsWith(_googleTestPublisher) ||
      bannerAdUnitId.startsWith(_googleTestPublisher);
}
