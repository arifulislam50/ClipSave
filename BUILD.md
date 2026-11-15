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
   - **Data safety:** Copy Box collects **no** data and shares **no** data. Data is stored only on the device and is never transmitted. Users can delete it in the app.
   - **App content → Permissions:** none are requested. The Quick Settings tile uses a system binding permission, not a user permission.
   - **Target API:** 36 (set in `build.gradle.kts`). Raise it when Google raises the requirement.
5. Suggested short description: "Private clipboard history. Save, search, favourite and organise copied text, all offline."
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

- **No** `android.permission.INTERNET`. Only `src/debug` and `src/profile` add it, for Flutter tooling.
- No runtime (dangerous) permissions.
- You **may** see `com.clipsave.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. AndroidX Core adds this signature-level permission automatically for apps targeting 33+. It grants nothing to other apps and needs no Play declaration.
- `ClipboardCaptureActivity` has `exported="false"`. `CaptureActivity` is exported only for `SEND` / `PROCESS_TEXT` `text/plain`. `ClipTileService` is protected by `BIND_QUICK_SETTINGS_TILE`.

If anything else appears, find its source in `build/app/outputs/logs/manifest-merger-release-report.txt`.

## 6. Pre-release checklist

- [ ] `flutter analyze` shows no errors (warnings reviewed)
- [ ] `flutter test` passes, including `clips_controller_test.dart` (sensitivity gate on every capture path)
- [ ] `python3 -I tool/check_structure.py .` and `python3 -I tool/verify_logic.py .` pass
- [ ] The README manual test plan passes on real devices or emulators running **Android 10, 12, 13, 14 and 15+**, especially the tile-focus and sensitive-data rows
- [ ] Step 5 shows no `INTERNET` permission and no unexpected components
- [ ] App icon looks right on the home screen, including themed icons on Android 13+
- [ ] The privacy policy URL is reachable

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter.sdk not set in local.properties` | Run `flutter pub get`, or create `android/local.properties` containing `flutter.sdk=/path/to/flutter` |
| "Gradle / AGP / KGP version is lower than Flutter's minimum" | Raise the version it names. Gradle goes in `gradle-wrapper.properties`; AGP and KGP go in `android/settings.gradle.kts`. Keep AGP's minimum Gradle in mind (AGP 9.1 → 9.3.1, 9.2 → 9.4.1, 9.3 → 9.5.0) |
| "Unsupported class file major version" / Gradle won't start | The build machine's JDK is older than 17. On Codemagic, add `java: 17` (or 21) under `environment` |
| R8 "Missing classes" warning | Add the suggested `-dontwarn` lines from `build/app/outputs/mapping/release/missing_rules.txt` to `proguard-rules.pro` |
| The tile toast says "Could not read the clipboard" | Focus didn't arrive within 2.5 s (seen on some OEM ROMs). Tap the tile again, or open Copy Box and use "Save clipboard". Please report the device model |
| The tile does nothing on Android 15+ | Background-activity-launch rules may have blocked it. Check `adb logcat \| grep -i "Background activity launch blocked"`. The tile already opts in through `ActivityOptions`; if it is still blocked, report the Android build |
| Kotlin warns about `MODE_BACKGROUND_ACTIVITY_START_ALLOWED` being deprecated (compileSdk 36+) | Expected and suppressed. It is the opt-in that works on API 34 and 35 |
