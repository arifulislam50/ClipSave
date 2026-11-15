# Copy Box

A clipboard manager for Android, built with Flutter, with native Kotlin capture components.

Copy Box keeps a searchable history of the text you copy. You can add favourites, put clips in folders, browse automatic categories (links, emails, phones, numbers, text) and copy any clip back with one tap.

**Privacy in one paragraph:** clips are stored only on the device and are never uploaded by Copy Box. Backup and device transfer are disabled for them. The app shows a banner ad from **Google AdMob** on the History and Folders screens. AdMob may collect device identifiers (such as the advertising ID) and usage data under Google's policy (<https://policies.google.com/technologies/ads>). Consent is collected with Google's User Messaging Platform before any ad loads, and users can change it in **Settings → Privacy and ad choices**. Clip text is never passed to the ad SDK, and `tool/check_structure.py` enforces this.

---

## What Android allows, and how Copy Box works within it

Since **Android 10**, an app can read the clipboard **only while it is in the foreground with input focus**. The one exception is the user's default keyboard (IME). No regular app can silently log everything you copy in the background. Copy Box **does not** get around this: it uses no Accessibility Service and needs no keyboard change.

Copy Box captures text in five compliant ways:

| # | Method | How it works | Reads clipboard? |
|---|--------|--------------|------------------|
| 1 | **Auto-save when you open Copy Box** | When Copy Box gains focus, `MainActivity` checks `primaryClipDescription.timestamp`. Only if the clip changed does it read the text and send it to Flutter. | Yes, only while focused |
| 2 | **Quick Settings tile "Save to Copy Box"** | The tile opens the invisible `ClipboardCaptureActivity`, which waits for window focus, reads once (retrying once after 200 ms), queues the text and closes. | Yes, during a user tap |
| 3 | **Text-selection menu "Save to Copy Box"** | `ACTION_PROCESS_TEXT` delivers the selected text to `CaptureActivity`. | No |
| 4 | **Share sheet "Save to Copy Box"** | `ACTION_SEND text/plain` to `CaptureActivity`. | No |
| 5 | **New clip** | The "New clip" button opens the editor to type or paste text yourself. | No (any paste is your own keyboard action) |

Things to know:

- On Android 12+, the system shows "Copy Box pasted from your clipboard" whenever the app reads another app's clip. Copy Box checks the timestamp first, so the notice appears only when there is something new.
- Turning off **Auto-save when Copy Box opens** cancels the Flutter event-channel subscription. Native code then never reads the clipboard on focus.

### Sensitive data: one gate for every automatic path

Anything stored without the user seeing it first passes through `ClipsController._autoFilterReason`. That covers focus auto-save **and** everything in the native inbox (Quick Settings tile, Share, text selection):

| Check | Applies when |
|-------|--------------|
| Copying app set `ClipDescription.EXTRA_IS_SENSITIVE` (password managers do) | **Always.** Not affected by the setting. The tile already refuses these natively. |
| `SensitiveDetector`: OTP, password, Luhn-valid card number, private key, known API-token formats | When **Skip passwords and codes** is on (the default) |

- **Skipped inbox items** are held **in memory only** for 2 minutes. A snackbar offers **Save anyway**. Nothing is written to SQLite unless the user taps it.
- **Skipped auto-save items** are held the same way (memory only, 2 minutes) with a **Save anyway** snackbar action.
- Copy Box reads the clipboard **only** when it opens or returns to the foreground (if auto-save is on) and when the Quick Settings tile is used. There is no in-app "read the clipboard now" button.
- **Typing in the editor** is an explicit action and is not filtered.
- **Copying back:** when a clip looks sensitive, Copy Box sets `EXTRA_IS_SENSITIVE` on the copy (native `copyText`). Android 13+ then hides it in the copy preview, and Copy Box's own auto-save ignores it.
- **Size cap:** native code rejects text over 100,000 characters before it reaches the queue. This protects the exported share/selection activity from oversized input. The Dart and Kotlin limits are checked to match.
- `tool/check_structure.py` enforces this gate. It fails if `_importInbox` or `_onAutoCaptured` can store text before calling `_autoFilterReason`, or if any other method calls `saveText`.

Because heuristic filtering happens in Flutter, native toasts for tile, share and selection say **"Sent to Copy Box"**, not "Saved".

**Known residual risk:** until Copy Box next opens, text from the tile, share or selection waits in the app-private inbox (SharedPreferences). That storage is excluded from backup and device transfer, and the item is filtered and removed from the queue on the next launch or resume. The text is not encrypted at rest. A rooted device or physical forensic access could read it during that window.

---

## Architecture

```
Flutter UI (Material 3)  ──►  State (Provider ChangeNotifiers)  ──►  Repositories  ──►  SQLite (sqflite)
        ▲                                │
        │                     ClipboardBridge (MethodChannel + EventChannel)
        │                                │
        └──── snackbars ◄────  Kotlin: MainActivity · ClipReader · ClipInbox
                                         CaptureActivity · ClipboardCaptureActivity
                                         ClipTileService · TileHelper
```

- **Only Flutter writes SQLite.** Native components that run while the UI is closed (tile, share, selection) append to a small private queue, `ClipInbox` (SharedPreferences JSON). Flutter drains the queue on launch and on every resume. This avoids two writers on one database.
- **Deduplication:** a unique index on `clips.content`. Saving existing text moves it to the top (`updated_at`) instead of storing it twice.
- **History limit:** `prune` keeps the newest N non-favourite clips. Favourites are never pruned.

### Project structure: every file

| Path | Purpose |
|------|---------|
| `pubspec.yaml` | Dart package, dependencies (`sqflite`, `path`, `provider`, `shared_preferences`; dev: `flutter_lints`, `sqflite_common_ffi`) |
| `analysis_options.yaml` | Lint rules (flutter_lints + strict casts) |
| `lib/main.dart` | Builds repositories and controllers, registers Providers, starts `ClipsController.init()` |
| `lib/app.dart` | `MaterialApp`, light/dark themes, global `ScaffoldMessenger` key |
| `lib/core/constants.dart` | App info, history-limit options, clip source labels |
| `lib/core/theme/app_theme.dart` | Neutral themes with a pink accent: dark (default) is pure black (#000000 surface, #121214 cards, #26262A borders); light is white with neutral greys. `primary` #FD79A8, `onPrimary` #2D3436. `CopyBoxColors` holds only the roles `ColorScheme` lacks (card, fill, link, star, tip). Also transparent system-bar styles and the folder palette |
| `lib/platform/window_bridge.dart` | Switches the native window background from start-up pink to the theme surface once the app UI shows |
| `lib/core/ad_config.dart` | AdMob App ID and banner unit ID (Google **test** IDs; TODO before release) |
| `lib/ads/ads_service.dart` | UMP consent flow, then Mobile Ads init; `adsReady`, `privacyOptionsRequired`, `showPrivacyOptions()` |
| `lib/ui/widgets/ad_banner.dart` | Large anchored adaptive banner (History and Folders only, plain `AdRequest()`) |
| `lib/ui/widgets/app_logo.dart` | `AppLogo` CustomPaint (three stacked cards) and shared `LogoGeometry` |
| `lib/ui/screens/splash_screen.dart` | Brand splash: leaves when settings + database are ready and ≥ 1.5 s have passed, never after 3 s (1 s minimum with reduced motion); ads consent starts in the background; never reads the clipboard |
| `lib/ui/widgets/section_header.dart`, `category_visuals.dart` | Section labels; category icons, names, tints and `CategoryAvatar` |
| `tool/generate_logo.py` | Generates all icon drawables, `assets/logo/logo.svg` and the 1024px PNGs from one geometry |
| `assets/logo/` | `logo.svg`, `icon_1024.png` (store icon), `icon_foreground.png` |
| `lib/core/utils/content_classifier.dart` | `ClipCategory` enum and link/email/phone/number detection |
| `lib/core/utils/sensitive_detector.dart` | On-device OTP/password/card/key heuristics (+ Luhn) |
| `lib/core/utils/time_format.dart` | "5 min ago", "Yesterday 09:05", … |
| `lib/data/db/schema.dart` | All SQL: tables, indexes, folder-count query, prune |
| `lib/data/db/app_database.dart` | Opens the DB, enables foreign keys, migration hook |
| `lib/data/models/clip_item.dart` | `ClipItem` model, `SaveResult` |
| `lib/data/models/folder.dart` | `Folder` model |
| `lib/data/models/clip_filter.dart` | All / Favourites / Category / Folder filter value |
| `lib/data/repositories/clip_repository.dart` | CRUD, search (LIKE with escaping), favourites, folders, prune, undo |
| `lib/data/repositories/settings_repository.dart` | Preferences (never clip content) |
| `lib/platform/clipboard_bridge.dart` | Dart side of the platform channels |
| `lib/state/settings_controller.dart` | Theme, auto-capture, skip-sensitive, history size |
| `lib/state/clips_controller.dart` | Clip list, search debounce, filters, all capture paths, the single sensitivity gate, inbox import, held-sensitive items |
| `lib/state/app_message.dart` | Snackbar message with optional action ("Undo", "Save anyway") |
| `lib/ui/root_shell.dart` | Bottom navigation (History / Folders / Settings), snackbar listener |
| `lib/ui/actions/clip_actions.dart` | Shared flows: save clipboard, copy, delete + undo, move, clear |
| `lib/ui/screens/history_screen.dart` | Search, filter chips, list with swipe-to-delete, FAB |
| `lib/ui/screens/folders_screen.dart` | Create / rename / delete folders, open a folder |
| `lib/ui/screens/settings_screen.dart` | All settings, Quick Settings tile request, data deletion |
| `lib/ui/screens/clip_editor_screen.dart` | New or edit clip, choose folder |
| `lib/ui/screens/capture_guide_screen.dart` | In-app explanation of Android limits and capture methods |
| `lib/ui/screens/privacy_screen.dart` | In-app privacy policy |
| `lib/ui/widgets/*.dart` | `ClipTile` + actions sheet, `FilterBar`, `EmptyState`, dialogs, info card, category icons |
| `test/*.dart` | Unit tests: detector, classifier, time format, repository (real SQLite via ffi), controller capture paths with a fake native bridge (`clips_controller_test.dart`) |
| `tool/verify_logic.py` | SDK-free check: runs the Dart regexes and SQL in Python/SQLite |
| `tool/check_structure.py` | SDK-free check: imports, brackets, XML, resource refs, channel and method names, security invariants |
| `android/settings.gradle.kts` | Flutter plugin loader; AGP 9.1.1, Kotlin Gradle Plugin 2.4.10 |
| `android/build.gradle.kts` | Repositories, shared build dir |
| `android/gradle.properties` | JVM args, AndroidX, AGP 9 compatibility flags (`android.newDsl=false`, `android.builtInKotlin=false`) |
| `android/gradle/wrapper/*`, `gradlew*` | Gradle 9.3.1 wrapper |
| `android/app/build.gradle.kts` | `com.clipsave.app`, minSdk 26, targetSdk 36, compileSdk from Flutter, Kotlin `compilerOptions` JVM 17, signing, R8 |
| `android/app/proguard-rules.pro` | R8 keep rules |
| `android/app/src/main/AndroidManifest.xml` | Activities, share / PROCESS_TEXT filters, tile service, INTERNET + ACCESS_NETWORK_STATE (AdMob only), AdMob App ID |
| `android/app/src/debug|profile/AndroidManifest.xml` | INTERNET for Flutter tooling (also in main for AdMob) |
| `…/kotlin/com/clipsave/app/MainActivity.kt` | Flutter host, method and event channels, focus-time capture |
| `…/ClipReader.kt` | Reads the clip, the `IS_SENSITIVE` flag and the timestamp-based change check. Writes copies, flagging secrets as sensitive. Shared size limit. |
| `…/ClipInbox.kt` | Private queue for items captured while the UI is closed |
| `…/CaptureActivity.kt` | Share and text-selection receiver (exported) |
| `…/ClipboardCaptureActivity.kt` | Invisible focus-holding reader for the tile (not exported) |
| `…/ClipTileService.kt` | Quick Settings tile: unlock-then-run on the lock screen, Android 14+ `PendingIntent` API with creator BAL opt-in |
| `…/TileHelper.kt` | Android 13+ `requestAddTileService` prompt |
| `…/res/values*/` | Strings, colours, launch / normal / translucent themes (light + night) |
| `…/res/drawable/`, `mipmap-anydpi-v26/` | Vector tile icon, adaptive + themed (monochrome) launcher icon |
| `…/res/xml/data_extraction_rules.xml` | Excludes all data from cloud backup and device transfer |

---

## Requirements

- A current **stable Flutter**: 3.38.1 or newer with Dart 3.10+ (required by `google_mobile_ads` 9.x), and with AGP 9 support (3.44+). The Android build files meet Flutter's current minimums: **Gradle 9.3.1, AGP 9.1.1, Kotlin Gradle Plugin 2.4.10**.
- Android SDK with the platform Flutter selects (`flutter.compileSdkVersion`, currently 37) plus SDK Build Tools 36+. AGP downloads missing platforms when licences are accepted (`flutter doctor --android-licenses`).
- JDK **17 or newer**. Gradle 9 and AGP 9 will not run on older JDKs.
- A device or emulator running **Android 8.0 (API 26) or newer**

## Run it

```bash
cd clipsave
flutter pub get
flutter create . --platforms=android --org com.clipsave --project-name clipsave
#   ^ only fills in missing generated files (e.g. local.properties); it does not
#     overwrite existing files. Skip it if `flutter run` already works.
flutter analyze
flutter test
flutter run
```

`flutter test` includes `test/clip_repository_test.dart`, which uses desktop SQLite through `sqflite_common_ffi`. On Linux, install `libsqlite3-dev` first. macOS and Windows already ship it.

## Manual test plan (run on a real device)

| Phase | Steps | Expected |
|-------|-------|----------|
| Auto-capture | Copy text in Chrome, switch to Copy Box | Clip appears, "Saved from clipboard" |
| No repeat | Leave and return without copying anything new | No duplicate, no new paste notice |
| Delete stays deleted | Delete that clip, leave and come back | It does not reappear |
| Tile | Settings → Add Quick Settings tile. Copy in another app, tap the tile | Toast "Sent to Copy Box". Open Copy Box: "Saved 1 item from quick tile" |
| Tile focus (Android 10, 12, 13, 14, 15+) | Tap the tile from home, from inside another app, and from the lock screen | Shade collapses, no visible window, toast appears. On the lock screen it asks to unlock first. Never "Could not read the clipboard" on a stock ROM |
| Tile while Copy Box is open | Open Copy Box, pull the shade, tap the tile | One clip saved, no duplicate |
| Selection | Select text in an app → ⋮ → Save to Copy Box | Toast, then the clip appears on next open |
| Share | Share text → Save to Copy Box | Same as above |
| Sensitive, auto-save | Copy `482913`, open Copy Box | Not saved. Snackbar "Not saved…" with **Save anyway**; tapping it saves the code |
| Sensitive, tile/share/selection | Copy `P@ssw0rd!` and tap the tile, or share `Your code is 739201` | Toast "Sent". On opening: "Not saved…" with **Save anyway**. Ignore it, reopen after 2 minutes: nothing saved |
| Copy back a secret | Save `P@ssw0rd!` manually, tap it (Android 13+) | System copy preview hides the text |
| Oversized share | Share >100,000 characters | Toast "Text is too long", nothing queued |
| Password manager | Copy a password from a manager that sets `IS_SENSITIVE` | Never auto-saved. The tile shows "Not saved…" |
| Auto off | Turn off Auto-save, copy, open Copy Box | No read and no Android paste notice |
| Copy back | Tap the copy button on a clip | Clipboard updated (Android 13+ shows its own confirmation). Tapping the clip itself expands/collapses it and does **not** copy |
| Search / filters / folders / favourites | Use each | List updates. A deleted folder's clips remain |
| Swipe delete | Swipe left, tap Undo | Clip restored |
| Themes | System / Light / Dark | Whole UI switches |
| Splash | Cold-start a **release** build (with clipboard text from another app) | Pink splash 1.5–3 s, then fade to History. **No** "pasted from your clipboard" notice until History appears; auto-save happens then |
| Reduced motion | Enable "Remove animations", cold-start | Splash ~1 s, static bar, no fade |
| Android 12+ system splash | Cold-start on Android 12+ (light and dark mode) | One pink screen with no icon, then the in-app splash; no black flash |
| Consent (EEA) | Use an EEA device/VPN or UMP debug geography | Google consent form before any ad; Settings shows "Privacy and ad choices", which re-opens it |
| Banner placement | Open History, Folders, Settings, New clip | Test banner only on History and Folders, above the nav bar; "New clip" FAB fully visible above it; no ad on Settings, editor, splash |
| Copy button | Tap the round copy button on a tile; repeat with a password-like clip on Android 13+ | Copies; system preview hides the sensitive one |
| Themed icon | Android 13+, enable themed icons | Monochrome three-card icon |
| Lock screen | Tap the tile while locked | Asks to unlock, then captures |

Release builds and Play Store bundles: see **[BUILD.md](BUILD.md)**. Codemagic workflows (`codemagic.yaml`): `clipsave-android` (debug APK), `copybox-release-apk` (smallest arm64 release APK, obfuscated), `copybox-release-aab` (Play bundle), `copybox-size-report` (`--analyze-size`). Size and start-up measurement: BUILD.md §8. Privacy policy: see **[PRIVACY_POLICY.md](PRIVACY_POLICY.md)**.

## Limits

- The history list loads the newest **50** matching clips, then 50 more each time you scroll near the end (`ClipsController.loadMore`). Category counts are computed in SQL.

## Verification status

**Not compiled or run yet.** The environment that produced the Copy Box rebrand had no Flutter or Android SDK, so `flutter pub get`, `dart format`, `flutter analyze`, `flutter test` and `flutter build apk` were **not** run there. Run them before merging. The Codemagic workflow in `codemagic.yaml` builds a debug APK.

SDK-free checks that were run and pass:

| Check | Command | Covers |
|-------|---------|--------|
| Logic + SQL | `python3 -I tool/verify_logic.py .` | 38 detection/classification cases from the Dart tests; 11 SQL checks (dedupe, LIKE escaping, prune, FK, folder and category counts) |
| Structure + invariants | `python3 -I tool/check_structure.py .` | Imports, brackets, XML, resource refs, channel names; sensitivity gate; size cap; non-exported tile activity; **only AdMob permissions**; **AdMob App ID in manifest == `AdConfig`**; **only the two ad files use the ads SDK, they never reference clip data, `AdRequest()` has no targeting**; logo geometry identical in `app_logo.dart` and `tool/generate_logo.py` |
| Contrast | (computed) | Dark: #F5F5F7 on #000000 19.3:1; #A1A1AA on #121214 7.3:1; pink #FD79A8 on black 8.5:1, on #1E1E22 6.7:1; tip #FDCB6E on #2A2110 10.5:1. Light: #1B1B1F on white 17.2:1; links #B01F63 6.5:1 (pink text on white would be 2.5:1). #2D3436 on #FD79A8 5.1:1. Category icons ≥ 5.6:1 (dark) / ≥ 4.1:1 (light) on their 18% tints. The amber star is decorative and has a "Favourite" label. |

New Dart tests to run with `flutter test`: `test/copy_box_ui_test.dart` (theme colours, splash timing min/max/background/failure/reduced motion, centring, AppLogo, AdMob test-ID guard), `test/history_screen_test.dart` (New clip FAB, empty state, tile expand/collapse, copy button vs tile tap, date line, filter chips), `test/clips_controller_test.dart` (sensitivity gate, Save anyway, paging, lazy settings), `test/time_format_test.dart` (date/time edge cases).

See [CHANGELOG.md](CHANGELOG.md) for what changed in the security review.
