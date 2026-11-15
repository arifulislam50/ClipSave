# R8 rules for release builds (isMinifyEnabled + isShrinkResources).
# Flutter's Gradle plugin adds the engine's rules; the Google Mobile Ads SDK,
# UMP and AndroidX ship their own consumer rules inside their AARs.

# Copy Box's own Android components. They are referenced from the manifest
# (activities, tile service) and the method/event channels are looked up by
# string name, so nothing here is reflective; keeping the package whole is a
# cheap safety net (a handful of small classes).
-keep class com.clipsave.app.** { *; }

# google_mobile_ads Flutter plugin: platform-view factories and message
# codecs are registered by the plugin and called from Dart through channels.
-keep class io.flutter.plugins.googlemobileads.** { *; }

# Optional Play Core (deferred components) classes referenced by Flutter.
-dontwarn com.google.android.play.core.**
