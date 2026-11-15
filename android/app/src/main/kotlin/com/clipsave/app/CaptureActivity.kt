package com.clipsave.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

/**
 * Invisible activity that receives text the user explicitly sends to Copy Box:
 *  - ACTION_SEND (share sheet, text/plain)
 *  - ACTION_PROCESS_TEXT ("Save to Copy Box" in any app's text-selection menu)
 *
 * These do not read the clipboard, so they work with any keyboard and on every
 * Android version. Text is only queued here; Flutter applies the sensitive-text
 * filter when it imports the queue, which is why the toast says "Sent" and
 * not "Saved".
 */
class CaptureActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val launchIntent: Intent? = intent
        when (launchIntent?.action) {
            Intent.ACTION_SEND -> handleShare(launchIntent)
            Intent.ACTION_PROCESS_TEXT -> handleProcessText(launchIntent)
        }
        finish()
    }

    private fun handleShare(launchIntent: Intent) {
        val type = launchIntent.type
        if (type == null || !type.startsWith("text/")) {
            toast(R.string.capture_unsupported)
            return
        }
        queue(launchIntent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString(), "share")
    }

    private fun handleProcessText(launchIntent: Intent) {
        queue(launchIntent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString(), "select")
    }

    private fun queue(text: String?, source: String) {
        when {
            text.isNullOrBlank() -> toast(R.string.capture_empty)
            // Any app can send to this exported activity; refuse oversized input.
            text.length > ClipReader.MAX_CLIP_LENGTH -> toast(R.string.capture_too_long)
            else -> {
                ClipInbox.add(this, CapturedClip(text, false, source, System.currentTimeMillis()))
                toast(R.string.capture_sent)
            }
        }
    }

    private fun toast(resId: Int) {
        Toast.makeText(applicationContext, resId, Toast.LENGTH_SHORT).show()
    }
}
