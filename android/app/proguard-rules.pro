# Flutter's Gradle plugin adds the rules the engine needs. These cover Copy Box's
# own Android components (referenced from the manifest, so R8 keeps them anyway)
# and silence warnings for optional Play Core classes Flutter references.
-keep class com.clipsave.app.** { *; }
-dontwarn com.google.android.play.core.**
