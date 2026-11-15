package com.clipsave.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.os.Build

/**
 * The persistent "quick-save" notification: a Save button in the shade that
 * works like the Quick Settings tile.
 *
 * Android only lets an app read the clipboard while one of its windows has
 * focus, so "Save copied text" is an ACTIVITY PendingIntent straight to
 * [ClipboardCaptureActivity]. No receiver or service sits in between: Android
 * 12+ blocks notification trampolines, and only a focused activity can read
 * the clipboard anyway.
 *
 * The notification shows fixed text only and never contains clip content.
 */
object QuickSaveNotification {
    const val CHANNEL_ID = "quick_save"
    const val NOTIFICATION_ID = 4201
    private const val ACCENT = 0xFFFD79A8.toInt()

    // Distinct request codes so the PendingIntents never replace each other
    // (or the tile's PendingIntent, which uses request code 0).
    private const val REQUEST_SAVE = 101
    private const val REQUEST_OPEN = 102
    private const val REQUEST_CONTENT = 103

    // The on/off setting lives in the native prefs file (not Flutter's), so
    // BootReceiver can read it without starting Flutter.
    private const val PREFS = "clipsave_native"
    private const val KEY_ENABLED = "quick_save_enabled"

    private fun manager(context: Context): NotificationManager =
        context.getSystemService(NotificationManager::class.java)

    fun isEnabled(context: Context): Boolean =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    /** POST_NOTIFICATIONS is a runtime permission only on Android 13+ (API 33). */
    fun hasPermission(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    /**
     * Re-posts the notification if the setting is on, the permission is
     * granted and it is not currently showing (the user swiped it away, which
     * Android 14+ allows for ongoing notifications, or the system removed it).
     * Never posts while the setting is off.
     */
    fun repostIfNeeded(context: Context) {
        if (!isEnabled(context) || !hasPermission(context)) return
        if (!isPosted(context)) post(context)
    }

    /** IMPORTANCE_LOW: no sound, no vibration, no heads-up; no badge. */
    fun ensureChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.quick_save_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.quick_save_channel_description)
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        manager(context).createNotificationChannel(channel)
    }

    /** Posts (or updates) the single quick-save notification. */
    fun post(context: Context) {
        val app = context.applicationContext
        ensureChannel(app)
        manager(app).notify(NOTIFICATION_ID, build(app))
    }

    fun cancel(context: Context) {
        manager(context.applicationContext).cancel(NOTIFICATION_ID)
    }

    fun isPosted(context: Context): Boolean =
        manager(context.applicationContext).activeNotifications.any { it.id == NOTIFICATION_ID }

    private fun openAppIntent(context: Context): Intent =
        Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

    private fun build(context: Context): Notification {
        val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT

        // Started DIRECTLY as an activity (it needs window focus to read the clipboard).
        val saveIntent = Intent(context, ClipboardCaptureActivity::class.java)
            .putExtra(ClipboardCaptureActivity.EXTRA_SOURCE, ClipboardCaptureActivity.SOURCE_NOTIFICATION)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)
        val savePending = PendingIntent.getActivity(context, REQUEST_SAVE, saveIntent, flags)
        val openPending = PendingIntent.getActivity(context, REQUEST_OPEN, openAppIntent(context), flags)
        val contentPending = PendingIntent.getActivity(context, REQUEST_CONTENT, openAppIntent(context), flags)

        val icon = Icon.createWithResource(context, R.drawable.ic_tile_clip)
        val title = context.getString(R.string.quick_save_title)
        val text = context.getString(R.string.quick_save_text)

        // Lock screen: only the app name, no text.
        val publicVersion = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tile_clip)
            .setColor(ACCENT)
            .setContentTitle(context.getString(R.string.app_name))
            .setShowWhen(false)
            .build()

        return Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tile_clip)
            .setColor(ACCENT)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(publicVersion)
            .setContentIntent(contentPending)
            .addAction(
                Notification.Action.Builder(icon, context.getString(R.string.quick_save_action_save), savePending).build(),
            )
            .addAction(
                Notification.Action.Builder(icon, context.getString(R.string.quick_save_action_open), openPending).build(),
            )
            .build()
    }
}
