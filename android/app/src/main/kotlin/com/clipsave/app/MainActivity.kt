package com.clipsave.app

import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and exposes the native clipboard bridge.
 *
 * Method channel  "com.clipsave.app/native":
 *   readClipboard -> Map?      (explicit read, used by the "Save clipboard" button)
 *   copyText(text, sensitive)  (copy back; sensitive clips get EXTRA_IS_SENSITIVE)
 *   drainInbox    -> List<Map> (items saved by tile/share/selection while UI was closed)
 *   requestAddTile -> String   (Android 13+ "add tile" system prompt)
 *   sdkInt        -> Int
 *
 * Event channel "com.clipsave.app/clipboard_events":
 *   Emits the clipboard when ClipSave gains focus or the clip changes while
 *   ClipSave is in the foreground. Flutter only listens while the user has
 *   "Auto-save when ClipSave opens" enabled, so no read happens otherwise.
 */
class MainActivity : FlutterActivity() {

    private var eventSink: EventChannel.EventSink? = null
    private var listenerRegistered = false

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
                "drainInbox" -> result.success(ClipInbox.drain(this))
                "requestAddTile" -> TileHelper.requestAddTile(this) { status -> result.success(status) }
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
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
        private const val METHOD_CHANNEL = "com.clipsave.app/native"
        private const val EVENT_CHANNEL = "com.clipsave.app/clipboard_events"
    }
}
