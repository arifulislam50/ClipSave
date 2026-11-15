import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from android/key.properties (never commit that file).
val keystoreProperties = Properties()
// `flutter build apk --target-platform android-arm64` passes -Ptarget-platform.
// When it is exactly arm64, the APK also filters native libs to arm64-v8a.
// App bundles (no target-platform) keep every ABI so Play can serve all devices.
val flutterTargetPlatform = project.findProperty("target-platform") as String?
val arm64OnlyBuild = flutterTargetPlatform == "android-arm64"

val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.clipsave.app"
    // Follow the installed Flutter SDK (AGP 9.1.1 supports compileSdk 37) so
    // plugin AARs never require a newer compileSdk than the app uses.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.clipsave.app"
        // 26 = Android 8.0: adaptive icons + ClipDescription.getTimestamp().
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        if (arm64OnlyBuild) {
            ndk { abiFilters += "arm64-v8a" }
        }
    }

    // English-only resources: drops the translations bundled by AndroidX and
    // Play services (the app UI is English; the UMP consent form is web-based).
    androidResources {
        localeFilters += "en"
    }

    packaging {
        // Store .so files uncompressed and page-aligned (smaller download,
        // no extraction on install).
        jniLibs { useLegacyPackaging = false }
        resources {
            excludes += setOf(
                "META-INF/*.version",
                "META-INF/*.kotlin_module",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "DebugProbesKt.bin",
                "kotlin-tooling-metadata.json",
            )
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // TODO(release): create an upload keystore + android/key.properties
            // (see BUILD.md). Without it, release builds are signed with the
            // DEBUG key: fine for testing an APK, rejected by the Play Store.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Replaces android.kotlinOptions {}, which KGP 2.2+ rejects (Flutter AGP 9 migration guide).
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
