# ClipSave Privacy Policy

**Effective date:** [DATE]  ·  **Developer:** [YOUR NAME / COMPANY]  ·  **Contact:** [CONTACT EMAIL]

*Draft. Fill in the bracketed fields and have it reviewed for your jurisdiction before publishing. This is not legal advice.*

## Summary

ClipSave is an offline clipboard manager. It stores the text you choose to save **only on your device**. ClipSave has no accounts, ads, analytics, crash reporting or third-party SDKs. It does not request internet access, so the app itself cannot send your data anywhere.

## Information ClipSave stores

ClipSave stores the following in its private app storage on your device:

- **Clip text** that you save, or that ClipSave saves on your behalf as described below.
- **Clip details:** the detected type (link, email, phone, number or text), the folder you choose, whether it is a favourite, how it was saved (for example auto-save, Quick Settings tile or share), and when.
- **Folders** you create, with their names and colours.
- **Settings:** theme, auto-save on or off, sensitive-text filtering on or off, and history size.

Other apps cannot access this storage.

## When ClipSave reads your clipboard

Android allows apps to read the clipboard only while they are open and focused. ClipSave reads the clipboard **only**:

1. When you open or return to ClipSave, if "Auto-save when ClipSave opens" is enabled (it is on by default and can be turned off in Settings).
2. When you tap **Save clipboard** in the app.
3. When you tap the ClipSave **Quick Settings tile**.

When you use **Share → Save to ClipSave** or **Save to ClipSave** in the text-selection menu, ClipSave receives only the text you sent. It does not read the clipboard in that case.

ClipSave does not use Accessibility Services, does not run in the background to monitor the clipboard, and does not log keystrokes.

## Sensitive information

- Clips that the copying app marks as sensitive, as password managers do, are never saved automatically.
- By default, every automatic path also skips text that looks like a one-time code, password, payment card number or access key: auto-save when you open the app, the Quick Settings tile, Share and text selection. This check runs entirely on your device.
- Text skipped this way is held in memory for two minutes only, so you can choose "Save anyway". It is never written to the clip history unless you do.
- Text sent from the Quick Settings tile, Share or text selection waits in a small private queue on the device until ClipSave next opens and checks it.
- When you copy a clip that looks sensitive out of ClipSave, it is marked as sensitive, so Android 13 and newer hide it in the on-screen copy preview.
- If you choose to save such text manually, ClipSave asks you to confirm first. Saved clips are stored in the app's private storage and are not separately encrypted. Protect your device with a screen lock.

## Sharing and transfer

ClipSave does **not** sell, share or transmit your information to anyone. Android cloud backup and device-to-device transfer are disabled for ClipSave's data.

When you tap a clip, ClipSave copies it to the system clipboard. Other apps can then read it, under Android's normal rules.

## Retention and deletion

Clips stay on your device until you delete them. You can:

- Delete individual clips (swipe or long-press → Delete)
- Limit history size (Settings → History size). Older non-favourite clips are removed automatically.
- Clear history, or delete all clips (Settings)
- Uninstall ClipSave, which removes all of its data

## Children

ClipSave is not directed to children and does not knowingly collect information from anyone.

## Permissions

ClipSave requests no runtime permissions. The Quick Settings tile uses Android's standard tile binding (`BIND_QUICK_SETTINGS_TILE`), which only the system can use.

## Changes

If this policy changes, we will update the effective date above and publish the new version at this address.

## Contact

Questions: [CONTACT EMAIL]
