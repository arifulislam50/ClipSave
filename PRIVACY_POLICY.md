# Copy Box Privacy Policy

**Effective date:** [DATE]  ·  **Developer:** [YOUR NAME / COMPANY]  ·  **Contact:** [CONTACT EMAIL]

*Draft. Fill in the bracketed fields and have it reviewed for your jurisdiction before publishing. This is not legal advice.*

## Summary

- **Your clips are stored only on your device and are never uploaded by Copy Box.** Copy Box has no accounts and no servers of its own.
- **Copy Box shows ads provided by Google AdMob.** AdMob may collect device identifiers (such as the advertising ID) and usage data, under Google's policy: <https://policies.google.com/technologies/ads>.
- **You can manage your ad consent in Settings → Privacy and ad choices** (shown where consent is required, for example in the EEA and UK).

## Information Copy Box stores on your device

Copy Box stores the following in its private app storage on your device. Other apps cannot access it, and Copy Box never sends it anywhere:

- **Clip text** that you save, or that Copy Box saves on your behalf as described below.
- **Clip details:** the detected type (link, email, phone, number or text), the folder you choose, whether it is a favourite, how it was saved (for example auto-save, Quick Settings tile or share), and when.
- **Folders** you create, with their names and colours.
- **Settings:** theme, auto-save on or off, sensitive-text filtering on or off, and history size.

Android cloud backup and device-to-device transfer are disabled for this data.

## Advertising (Google AdMob)

Copy Box displays a banner ad on the History and Folders screens. Ads are provided by Google AdMob, and the ad SDK connects to the internet to request and display ads. That is why Copy Box has internet access.

- Google may collect and process **device or other identifiers** (including the Android advertising ID), **app interaction data** (for example ad views and clicks) and **diagnostics**, and may infer approximate location from your IP address. This is done under Google's own policies: <https://policies.google.com/technologies/ads> and <https://policies.google.com/privacy>.
- **Copy Box never passes your clips, clipboard content or folder names to the ad SDK.** Ad requests contain no keywords or content from the app.
- **Consent:** where the law requires it, Copy Box asks for your consent with Google's consent form (User Messaging Platform) before any ad is requested. You can review or change your choice at any time in **Settings → Privacy and ad choices**. Ads are not loaded while consent is required and not given.
- You can reset or delete your advertising ID in Android settings (Settings → Privacy → Ads, or Settings → Google → Ads, depending on your device).

## When Copy Box reads your clipboard

Android allows apps to read the clipboard only while they are open and focused. Copy Box reads the clipboard **only**:

1. When you open or return to Copy Box, if "Auto-save when Copy Box opens" is on (it is on by default and can be turned off in Settings).
2. When you tap the Copy Box **Quick Settings tile** ("Save to Copy Box").
3. When you tap **Save copied text** on the optional quick-save notification.

If you paste text into **New clip** yourself, that is your own keyboard action; Copy Box saves only what you type or paste there.

With **Share → Save to Copy Box** or **Save to Copy Box** in the text-selection menu, Copy Box receives only the text you sent. It does not read the clipboard in that case.

Copy Box does not use Accessibility Services, does not run in the background to monitor the clipboard, and does not log keystrokes. The clipboard is never read while the splash screen is showing.

## Sensitive information

- Clips that the copying app marks as sensitive, as password managers do, are never saved automatically.
- By default, every automatic path also skips text that looks like a one-time code, password, payment card number or access key: auto-save, the Quick Settings tile, Share and text selection. This check runs on your device.
- Text skipped this way is held in memory for two minutes only, so you can choose "Save anyway". It is never written to your history unless you do.
- Text sent from the Quick Settings tile, Share or text selection waits in a small private queue on the device until Copy Box next opens and checks it.
- When you copy a clip that looks sensitive out of Copy Box, it is marked as sensitive, so Android 13 and newer hide it in the on-screen copy preview.
- Saved clips are not separately encrypted. Protect your device with a screen lock.

## Sharing

Copy Box does not sell your clips or share them with anyone. Information collected by Google AdMob is described in the Advertising section above.

When you tap the copy button on a clip, Copy Box copies it to the system clipboard. Other apps can then read it, under Android's normal rules.

## Retention and deletion

Clips stay on your device until you delete them. You can:

- Delete individual clips (swipe, or long-press → Delete)
- Limit history size (Settings → History size). Older non-favourite clips are removed automatically.
- Clear history, or delete all clips (Settings)
- Uninstall Copy Box, which removes all of its data from the device

Data collected by Google for advertising is governed by Google's policies; see <https://policies.google.com/technologies/ads>.

## Children

Copy Box is not directed to children under 13 (or the equivalent minimum age in your country).

## Permissions

- **Internet access and network state:** used only by Google AdMob to load ads and the consent form.
- **Advertising ID:** added by the Google Mobile Ads SDK and used for advertising, subject to your consent and Android ad settings.
- **Notifications (Android 13+):** Copy Box asks for the notification permission only if you turn on the quick-save notification (Android 13+). The notification never shows clip text; its Save button reads the clipboard only when you tap it. If you turn the notification off, Copy Box stops showing it.
- **Run at startup (RECEIVE_BOOT_COMPLETED):** used only to show the quick-save notification again after a restart or app update, and only if you turned it on. It never reads the clipboard.
- The Quick Settings tile uses Android's standard tile binding (`BIND_QUICK_SETTINGS_TILE`), which only the system can use.

Apart from the optional notification permission, Copy Box requests no runtime permissions (such as location, contacts or storage).

## Quick-save notification (optional, off by default)

If you turn it on in Settings, Copy Box shows a silent notification with a **Save copied text** button. Tapping it briefly opens an invisible Copy Box window, which reads the clipboard once and saves the text on your device, with the same sensitive-text rules as the Quick Settings tile. The notification shows only fixed text, never your clips; on the lock screen it shows only the app name. On Android 12 and newer, Android shows its own "Copy Box pasted from your clipboard" notice whenever the clipboard is read; apps cannot turn that notice off.

## Changes

If this policy changes, we will update the effective date above and publish the new version at this address.

## Contact

Questions: [CONTACT EMAIL]
