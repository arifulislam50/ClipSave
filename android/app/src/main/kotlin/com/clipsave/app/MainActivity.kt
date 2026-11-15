package com.clipsave.app

import android.Manifest
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.drawable.ColorDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and exposes the native clipboard bridge.
 *
 * Method channel  "com.clipsave.app/native":
 *   readClipboard -> Map?      (explicit read; kept for ClipsController.captureClipboard)
 *   copyText(text, sensitive)  (copy back; sensitive clips get EXTRA_IS_SENSITIVE)
 *   drainInbox    -> List<Map> (items saved by tile/share/selection while UI was closed)
 *   requestAddTile -> String   (Android 13+ "add tile" system prompt)
 *   sdkInt        -> Int
 *   setWindowBackground(color) (ARGB; the window starts pink, then follows the app theme)
 *   quickSaveStatus -> {enabled}   (real state: setting on AND notification allowed)
 *   setQuickSave(enabled) -> {enabled, denied, permanentlyDenied}
 *                    (asks for POST_NOTIFICATIONS on Android 13+ only when turning on)
 *   openNotificationSettings       (ACTION_APP_NOTIFICATION_SETTINGS)
 *
 * Event channel "com.clipsave.app/clipboard_events":
 *   Emits the clipboard when Copy Box gains focus or the clip changes while
 *   Copy Box is in the foreground. Flutter only listens while the user has
 *   "Auto-save when Copy Box opens" enabled, so no read happens otherwise.
 */
class MainActivity : FlutterActivity() {

    private var eventSink: EventChannel.EventSink? = null
    private var listenerRegistered = false

    // Disk work (inbox JSON in SharedPreferences, commit()) never runs on the
    // main thread. Created lazily on first use, not at start-up.
    private var ioExecutor: ExecutorService? = null
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    /** Pending Flutter reply while the POST_NOTIFICATIONS dialog is showing. */
    private var pendingQuickSaveResult: Result? = null

    private fun io(): ExecutorService =
        ioExecutor ?: Executors.newSingleThreadExecutor().also { ioExecutor = it }

    private val clipboard: ClipboardManager by lazy {
        getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    }

    private val clipListener = ClipboardManager.OnPrimaryClipChangedListener {
        if (hasWindowFocus()) emitClipIfChanged()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "readClipboard" -> result.success(ClipReader.read(this, "clipboard")?.toMap())
                "copyText" -> {
                    val text = call.argument<String>("text")
                    if (text == null) {
                        result.error("bad_args", "text is required", null)
                    } else {
                        ClipReader.write(this, text, call.argument<Boolean>("sensitive") == true)
                        result.success(null)
                    }
                }
                "drainInbox" -> {
                    val appContext = applicationContext
                    io().execute {
                        val items = try {
                            ClipInbox.drain(appContext)
                        } catch (e: Exception) {
                            emptyList()
                        }
                        mainHandler.post { result.success(items) }
                    }
                }
                "requestAddTile" -> TileHelper.requestAddTile(this) { status -> result.success(status) }
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                "quickSaveStatus" -> result.success(mapOf("enabled" to quickSaveActive()))
                "setQuickSave" -> setQuickSave(call.argument<Boolean>("enabled") == true, result)
                "openNotificationSettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
                    )
                    result.success(null)
                }
                "setWindowBackground" -> {
                    val color = call.argument<Number>("color")
                    if (color == null) {
                        result.error("bad_args", "color is required", null)
                    } else {
                        // Dart sends 0xAARRGGBB as a (possibly Long) number; toInt() keeps the bits.
                        window.setBackgroundDrawable(ColorDrawable(color.toLong().toInt()))
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                if (hasWindowFocus()) emitClipIfChanged()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onResume() {
        super.onResume()
        // Quick-save notification: show it again if it is on but missing
        // (dismissed by the user or removed by the system). Off the main thread.
        val appContext = applicationContext
        io().execute { QuickSaveNotification.repostIfNeeded(appContext) }
        if (!listenerRegistered) {
            clipboard.addPrimaryClipChangedListener(clipListener)
            listenerRegistered = true
        }
    }

    override fun onPause() {
        if (listenerRegistered) {
            clipboard.removePrimaryClipChangedListener(clipListener)
            listenerRegistered = false
        }
        super.onPause()
    }

    /** Real state. If the permission was revoked, the stored setting is turned off. */
    private fun quickSaveActive(): Boolean {
        if (!QuickSaveNotification.isEnabled(this)) return false
        if (QuickSaveNotification.hasPermission(this)) return true
        QuickSaveNotification.setEnabled(this, false)
        QuickSaveNotification.cancel(this)
        return false
    }

    private fun setQuickSave(enabled: Boolean, result: Result) {
        if (!enabled) {
            QuickSaveNotification.setEnabled(this, false)
            QuickSaveNotification.cancel(this)
            result.success(mapOf("enabled" to false))
            return
        }
        if (QuickSaveNotification.hasPermission(this)) {
            QuickSaveNotification.setEnabled(this, true)
            QuickSaveNotification.post(this)
            result.success(mapOf("enabled" to true))
            return
        }
        // Android 13+ without permission: ask now (only because the user turned it on).
        if (pendingQuickSaveResult != null) {
            result.error("busy", "A permission request is already showing", null)
            return
        }
        pendingQuickSaveResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATIONS) return
        val result = pendingQuickSaveResult ?: return
        pendingQuickSaveResult = null
        if (QuickSaveNotification.hasPermission(this)) {
            QuickSaveNotification.setEnabled(this, true)
            QuickSaveNotification.post(this)
            result.success(mapOf("enabled" to true))
        } else {
            QuickSaveNotification.setEnabled(this, false)
            // No rationale after a denial means "don't ask again" (or blocked by
            // policy): the system dialog will not show again, so Flutter offers settings.
            val permanentlyDenied =
                !shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)
            result.success(
                mapOf("enabled" to false, "denied" to true, "permanentlyDenied" to permanentlyDenied),
            )
        }
    }

    override fun onDestroy() {
        ioExecutor?.shutdown()
        ioExecutor = null
        super.onDestroy()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) emitClipIfChanged()
    }

    private fun emitClipIfChanged() {
        val sink = eventSink ?: return // Auto-capture disabled: never touch the clipboard.
        val clip = ClipReader.readIfChanged(this, "auto") ?: return
        sink.success(clip.toMap())
    }

    companion object {
        private const val REQUEST_NOTIFICATIONS = 4202
        private const val METHOD_CHANNEL = "com.clipsave.app/native"
        private const val EVENT_CHANNEL = "com.clipsave.app/clipboard_events"
    }
}
