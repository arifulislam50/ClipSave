package com.clipsave.app

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Toast

/**
 * Launched only by [ClipTileService] after the user taps the tile.
 *
 * Android 10+ lets an app read the clipboard only while one of its windows
 * has input focus. This transparent, focusable activity waits for
 * onWindowFocusChanged(true), which arrives after the Quick Settings panel
 * collapses, reads the clip, queues it in [ClipInbox] and closes.
 *
 * - Items the copying app marked sensitive (EXTRA_IS_SENSITIVE) are refused here.
 * - Heuristic filtering (OTP/password/card/key) happens in Flutter on import.
 * - If the first read returns nothing right after focus (seen on some ROMs
 *   while focus is still settling), it retries once before reporting "empty".
 * - If focus never arrives, a timeout closes the activity.
 */
class ClipboardCaptureActivity : Activity() {

    private val handler = Handler(Looper.getMainLooper())
    private var handled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handler.postDelayed({
            if (!handled) {
                handled = true
                toast(R.string.capture_no_focus)
                finish()
            }
        }, FOCUS_TIMEOUT_MS)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus || handled) return
        handled = true
        handler.removeCallbacksAndMessages(null)
        attemptCapture(retriesLeft = 1)
    }

    private fun attemptCapture(retriesLeft: Int) {
        val clip = ClipReader.read(this, "tile")
        if (clip == null && retriesLeft > 0 && hasWindowFocus()) {
            handler.postDelayed({ attemptCapture(retriesLeft - 1) }, RETRY_DELAY_MS)
            return
        }
        when {
            clip == null -> toast(R.string.capture_empty)
            clip.sensitive -> toast(R.string.capture_sensitive_skipped)
            clip.text.length > ClipReader.MAX_CLIP_LENGTH -> toast(R.string.capture_too_long)
            else -> {
                ClipInbox.add(this, clip)
                toast(R.string.capture_sent)
            }
        }
        finish()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun toast(resId: Int) {
        Toast.makeText(applicationContext, resId, Toast.LENGTH_SHORT).show()
    }

    companion object {
        private const val FOCUS_TIMEOUT_MS = 2500L
        private const val RETRY_DELAY_MS = 200L
    }
}
