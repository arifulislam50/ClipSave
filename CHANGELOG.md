# Changelog

## 1.0.0 (unreleased): security and functionality review

**Not build-tested.** No Flutter or Android SDK was available. Run `flutter analyze`, `flutter test` and the README device test plan before release.

### Security
- **Fixed:** the native inbox (Quick Settings tile, Share, text selection) was imported into SQLite without the `SensitiveDetector`. All automatic paths now go through one gate, `ClipsController._autoFilterReason`. System-flagged clips are always refused; the heuristics follow "Skip passwords and codes".
- Skipped inbox items are held in memory only, for 2 minutes, behind a "Save anyway" snackbar action.
- Skipped auto-save clips now show a message instead of being dropped silently.
- "Save clipboard" always asks before storing sensitive-looking text, whatever the setting.
- Copying a sensitive-looking clip out of ClipSave sets `EXTRA_IS_SENSITIVE` (new native `copyText`).
- Native side rejects text over 100,000 characters before queueing it, so the exported share/selection activity can't be fed oversized input.
- `tool/check_structure.py` enforces these invariants.

### Functionality
- `CaptureActivity`: removed `val intent = intent` self-shadowing, a likely Kotlin compile error.
- Tile: retries the read once after 200 ms if focus is still settling. Android 14+ `PendingIntent` gets the creator background-launch opt-in.
- Tile, share and selection toasts now say "Sent to ClipSave", because the text is filtered later in Flutter.
- Folder ids are validated before every write. Previously, saving from the editor after the selected folder was deleted hit a foreign-key failure.
- A failed database open is no longer cached forever. Init failure shows a message and disables auto-capture.
- Snackbars support actions (`AppMessage`).

### Files changed
- Kotlin: `ClipReader.kt`, `CaptureActivity.kt`, `ClipboardCaptureActivity.kt`, `ClipTileService.kt`, `ClipInbox.kt`, `MainActivity.kt`
- Resources: `res/values/strings.xml`
- Dart: `state/clips_controller.dart`, `state/app_message.dart` (new), `core/utils/sensitive_detector.dart`, `data/db/app_database.dart`, `platform/clipboard_bridge.dart`, `ui/root_shell.dart`, `ui/actions/clip_actions.dart`, `ui/screens/clip_editor_screen.dart`, `ui/screens/settings_screen.dart`, `ui/screens/capture_guide_screen.dart`, `ui/screens/privacy_screen.dart`
- Tests and tools: `test/clips_controller_test.dart` (new), `tool/check_structure.py`
- Docs: `README.md`, `BUILD.md`, `PRIVACY_POLICY.md`, `CHANGELOG.md` (new)
