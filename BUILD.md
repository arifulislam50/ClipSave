# Building Copy Box for release

## 1. Check your toolchain

```bash
flutter --version      # current stable (3.44+, with AGP 9 support)
flutter doctor -v      # Android toolchain must be ✓, licences accepted
java -version          # 17 or newer (required by Gradle 9 / AGP 9)
```

Android build toolchain pinned in this repo, matching Flutter's minimum supported versions:

| Component | Version | File |
|-----------|---------|------|
| Gradle wrapper | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 9.1.1 (requires Gradle ≥ 9.3.1; AGP 9.2+ would need Gradle 9.4.1) | `android/settings.gradle.kts` |
| Kotlin Gradle Plugin | 2.4.10 | `android/settings.gradle.kts` |
| AGP 9 flags | `android.newDsl=false`, `android.builtInKotlin=false` | `android/gradle.properties` |

When a future Flutter raises these minimums again, `flutter build` reports the required version. Bump the same three files, and follow docs.flutter.dev → *Migrating to AGP 9* and *built-in Kotlin*.

If Gradle complains that `local.properties` is missing, run `flutter pub get` once. If it's still missing, run
`flutter create . --platforms=android --org com.clipsave --project-name clipsave`. Both only add missing files.

## 2. Create an upload key (once)

```bash
keytool -genkey -v -keystore ~/clipsave-upload.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload
```

Back up this file and its passwords. If you lose them, you'll need Play Console support to reset the upload key.

Create `android/key.properties`. It's git-ignored, so never commit it:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/clipsave-upload.jks
```

`android/app/build.gradle.kts` uses this file automatically when it exists. Without it, release builds are signed with the **debug** key. That's fine for testing an APK, but Play Console won't accept it.

## 3. Release APK (sideloading / testing)

```bash
flutter clean
flutter pub get
flutter test
flutter build apk --release
# Smaller per-ABI files:
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-release.apk` (or `app-arm64-v8a-release.apk` and others).

Install: `adb install -r build/app/outputs/flutter-apk/app-release.apk`

## 4. Play Store App Bundle (AAB)

1. Bump `version:` in `pubspec.yaml`. The number after `+` (versionCode) must increase for every upload.
2. Build:

   ```bash
   flutter build appbundle --release
   ```

   Output: `build/app/outputs/bundle/release/app-release.aab`
3. Play Console → Create app → upload the `.aab` to **Internal testing** first. Enrol in **Play App Signing** (the default).
4. Fill in the store listing:
   - **Privacy policy URL:** host `PRIVACY_POLICY.md` publicly (for example GitHub Pages) and paste the link.
   - **Data safety:** see section 7 below. Copy Box itself uploads nothing, but the AdMob SDK collects data, so the form is **not** "no data collected".
   - **App content → Ads:** answer **Yes, my app contains ads**.
   - **App content → Advertising ID:** declare that the app uses the advertising ID, for **Advertising or marketing**. The Google Mobile Ads SDK adds `com.google.android.gms.permission.AD_ID`.
   - **App content → Permissions:** INTERNET and ACCESS_NETWORK_STATE (normal permissions, used by AdMob), AD_ID, POST_NOTIFICATIONS (runtime on Android 13+, requested only when the user turns on the quick-save notification) and RECEIVE_BOOT_COMPLETED (normal; only re-shows that notification after a restart). POST_NOTIFICATIONS and RECEIVE_BOOT_COMPLETED need **no special Play Console declaration** (they are not restricted permissions). The Quick Settings tile uses a system binding permission.
   - **Target API:** 36 (set in `build.gradle.kts`). Raise it when Google raises the requirement.
5. Suggested short description: "Clipboard history that stays on your device. Save, search, favourite and organise copied text."
   In the full description, state the Android limitation honestly. For example: "Android only lets apps read the clipboard while they're open. Copy Box saves when you open it, or with one tap from the Quick Settings tile, the text-selection menu or Share."
   Don't claim "automatically saves everything you copy in the background". That would be inaccurate, and it risks a policy rejection.

## 5. Verify release permissions and components

Check the **merged** release manifest, not just the source manifest. Plugins and AndroidX can add entries:

```bash
flutter build apk --release
# Permissions actually in the APK (aapt2 is in $ANDROID_HOME/build-tools/<ver>/):
aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
# Full merged manifest for review:
cat build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml \
  2>/dev/null || find build/app/intermediates -name AndroidManifest.xml -path '*release*'
```

Expected:

- `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE`, declared in the main manifest for AdMob.
- `com.google.android.gms.permission.AD_ID`, merged in by the Google Mobile Ads SDK. Declare it in Play Console (section 4).
- `android.permission.POST_NOTIFICATIONS` (runtime on Android 13+, asked only when the quick-save notification is turned on) and `android.permission.RECEIVE_BOOT_COMPLETED` (normal). No other runtime (dangerous) permissions.
- `BootReceiver` is `exported="false"` and only re-posts the notification.
- You **may** see `com.clipsave.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. AndroidX Core adds this signature-level permission automatically for apps targeting 33+. It grants nothing to other apps and needs no Play declaration.
- `ClipboardCaptureActivity` has `exported="false"`. `CaptureActivity` is exported only for `SEND` / `PROCESS_TEXT` `text/plain`. `ClipTileService` is protected by `BIND_QUICK_SETTINGS_TILE`.

If anything else appears, find its source in `build/app/outputs/logs/manifest-merger-release-report.txt`.

## 6. Pre-release checklist

- [ ] `flutter analyze` shows no errors (warnings reviewed)
- [ ] `flutter test` passes, including `clips_controller_test.dart` (sensitivity gate on every capture path)
- [ ] `python3 -I tool/check_structure.py .` and `python3 -I tool/verify_logic.py .` pass
- [ ] The README manual test plan passes on real devices or emulators running **Android 10, 12, 13, 14 and 15+**, especially the tile-focus and sensitive-data rows
- [ ] Step 5 shows only INTERNET, ACCESS_NETWORK_STATE, AD_ID, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED (plus the AndroidX signature permission) and no unexpected components
- [ ] Quick-save notification on Android 13+: turning it on asks for permission once; denying turns the switch back off with "Open settings"; Save copied text saves (source "Notification"); it reappears after a reboot only if on
- [ ] **AdMob IDs replaced:** `lib/core/ad_config.dart` and the `APPLICATION_ID` meta-data in `AndroidManifest.xml` contain your real IDs, not Google's test IDs (`ca-app-pub-3940256099942544…`). `tool/check_structure.py` checks that the two match.
- [ ] The consent form appears for an EEA test user (UMP debug geography) and **Settings → Privacy and ad choices** re-opens it
- [ ] Banner appears only on History and Folders, above the navigation bar, never covering the "New clip" FAB
- [ ] App icon looks right on the home screen, including themed icons on Android 13+
- [ ] The privacy policy URL is reachable

## 7. Play Console Data safety form (with AdMob)

Copy Box itself uploads nothing: clips, folders and settings stay on the device. The Google Mobile Ads SDK does collect data, so declare what Google documents for AdMob. Check Google's current guidance before submitting, because it can change: <https://developers.google.com/admob/android/privacy/play-data-disclosure>.

| Data type (Play category) | Collected | Shared | Purpose | Notes |
|---|---|---|---|---|
| **Device or other IDs** (incl. **advertising ID**) | Yes | Yes (Google) | Advertising or marketing; Analytics; Fraud prevention, security, and compliance | Collected by the Mobile Ads SDK |
| **App activity → App interactions** (ad views, taps) | Yes | Yes (Google) | Advertising or marketing; Analytics | For advertising |
| **App info and performance → Crash logs / Diagnostics** | Yes | Yes (Google) | Analytics; Fraud prevention | Per Google's AdMob disclosure |
| **Location → Approximate location** | Declare if Google's disclosure lists it | Yes (Google) | Advertising or marketing | Derived from IP by the ad SDK |
| Clip text, folders, settings | **No** | **No** | — | Stored only on device; never uploaded |

Other answers:
- **Is all user data encrypted in transit?** Yes (the Mobile Ads SDK uses HTTPS).
- **Can users request deletion?** On-device data: delete in the app or uninstall. Ad data: Google's controls (advertising ID reset/delete, <https://policies.google.com/technologies/ads>).
- **Data collection is required or optional?** Ads data collection is subject to the UMP consent where applicable.

## 8. Smallest APK, size analysis and start-up timing

> These numbers have **not** been measured yet: the environment that prepared this configuration had no Flutter/Android SDK. Run the commands below (or the Codemagic workflows) and record the results.

**Size settings already in the project:** R8 minify + resource shrinking (`isMinifyEnabled`, `isShrinkResources`), keep rules only for `com.clipsave.app.**` and the `google_mobile_ads` plugin (`proguard-rules.pro`), English-only resources (`androidResources.localeFilters`), uncompressed page-aligned native libs (`useLegacyPackaging = false`), excluded `META-INF/*.version`, `*.kotlin_module`, `DebugProbesKt.bin`; when building with `--target-platform android-arm64` the APK is filtered to `arm64-v8a`. No bundled fonts (system font; Material icons are tree-shaken), `assets/logo/*` is **not** a Flutter asset, no Firebase/analytics SDK.

```bash
# Release APK, arm64 only (Codemagic: copybox-release-apk)
flutter build apk --release --target-platform android-arm64 \
  --split-debug-info=build/symbols --obfuscate --tree-shake-icons
du -h build/app/outputs/flutter-apk/app-release.apk

# Play Store bundle, all ABIs (Codemagic: copybox-release-aab)
flutter build appbundle --release --split-debug-info=build/symbols --obfuscate
du -h build/app/outputs/bundle/release/app-release.aab

# What is big? (Codemagic: copybox-size-report). Run without --obfuscate/--split-debug-info.
flutter build apk --release --target-platform android-arm64 --analyze-size
#   prints a breakdown (lib/arm64-v8a/libapp.so = your Dart code, libflutter.so = engine,
#   classes.dex = Java/Kotlin incl. ads SDK, res/, assets/) and writes a JSON you can open with:
dart devtools   # then "App Size Tool" → load the apk-code-size-analysis_*.json
```

Keep `build/symbols/` and `build/app/outputs/mapping/release/mapping.txt` from each release: you need them to read obfuscated stack traces (`flutter symbolize -i <trace> -d build/symbols/app.android-arm64.symbols`).

**arm64-only APK:** it does **not** install on old 32-bit-only phones. For those, build `flutter build apk --release --split-per-abi` (one APK per ABI) or ship the AAB, which Play splits per device.

**Signing:** without `android/key.properties`, release builds are signed with the **debug key** (marked TODO in `build.gradle.kts`). That is fine for testing a sideloaded APK; the Play Store requires your own upload keystore (section 2).

**Measuring start-up** (always on a release or profile build; debug builds are slow by design):

```bash
# Cold start, release APK installed: TotalTime = time to first frame of MainActivity
adb shell am force-stop com.clipsave.app
adb shell am start -S -W -n com.clipsave.app/.MainActivity
#   repeat 5x and take the median of "TotalTime"

# Profile build with a start-up trace (writes build/start_up_info.json)
flutter run --profile --trace-startup
#   then open DevTools (Performance) from the printed URL for frame timings
```

Expected flow: one pink screen → in-app splash for 1.5–3 s (it leaves as soon as settings and the database are ready) → History. Ads consent and the banner load in the background and never delay this.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter.sdk not set in local.properties` | Run `flutter pub get`, or create `android/local.properties` containing `flutter.sdk=/path/to/flutter` |
| "Gradle / AGP / KGP version is lower than Flutter's minimum" | Raise the version it names. Gradle goes in `gradle-wrapper.properties`; AGP and KGP go in `android/settings.gradle.kts`. Keep AGP's minimum Gradle in mind (AGP 9.1 → 9.3.1, 9.2 → 9.4.1, 9.3 → 9.5.0) |
| "Unsupported class file major version" / Gradle won't start | The build machine's JDK is older than 17. On Codemagic, add `java: 17` (or 21) under `environment` |
| R8 "Missing classes" warning | Add the suggested `-dontwarn` lines from `build/app/outputs/mapping/release/missing_rules.txt` to `proguard-rules.pro` |
| The tile toast says "Could not read the clipboard" | Focus didn't arrive within 2.5 s (seen on some OEM ROMs). Tap the tile again, or open Copy Box (auto-save reads the clipboard when it opens). Please report the device model |
| The tile does nothing on Android 15+ | Background-activity-launch rules may have blocked it. Check `adb logcat \| grep -i "Background activity launch blocked"`. The tile already opts in through `ActivityOptions`; if it is still blocked, report the Android build |
| Kotlin warns about `MODE_BACKGROUND_ACTIVITY_START_ALLOWED` being deprecated (compileSdk 36+) | Expected and suppressed. It is the opt-in that works on API 34 and 35 |
