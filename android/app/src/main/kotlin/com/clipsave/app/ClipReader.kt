package com.clipsave.app

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.PersistableBundle

/** A piece of text captured from the clipboard, a share, or a text selection. */
data class CapturedClip(
    val text: String,
    val sensitive: Boolean,
    val source: String,
    val timestamp: Long,
) {
    fun toMap(): Map<String, Any> = mapOf(
        "text" to text,
        "sensitive" to sensitive,
        "source" to source,
        "timestamp" to timestamp,
    )
}

/**
 * Reads and writes the primary clip. Android 10+ only returns clipboard data
 * while one of this app's windows has input focus, so read calls must come
 * from a focused activity (MainActivity or ClipboardCaptureActivity).
 * Otherwise Android returns null, which callers handle.
 */
object ClipReader {
    /** Same value as ClipDescription.EXTRA_IS_SENSITIVE (API 33), usable on all API levels. */
    const val EXTRA_IS_SENSITIVE = "android.content.extra.IS_SENSITIVE"

    /** Must match AppInfo.maxClipLength in Dart. */
    const val MAX_CLIP_LENGTH = 100_000

    private const val PREFS = "clipsave_native"
    private const val KEY_LAST_TIMESTAMP = "last_clip_timestamp"
    private const val CLIP_LABEL = "Copy Box"

    private fun manager(context: Context): ClipboardManager? =
        context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager

    /** Always reads the clipboard (used for explicit user actions). */
    fun read(context: Context, source: String): CapturedClip? {
        val cm = manager(context) ?: return null
        val clip = try {
            cm.primaryClip
        } catch (e: SecurityException) {
            null
        } ?: return null
        if (clip.itemCount == 0) return null

        val description: ClipDescription? = clip.description
        val text = try {
            clip.getItemAt(0).coerceToText(context)?.toString()
        } catch (e: Exception) {
            null
        }
        if (text.isNullOrBlank()) return null

        val sensitive = description?.extras?.getBoolean(EXTRA_IS_SENSITIVE, false) == true
        val timestamp = description?.timestamp ?: System.currentTimeMillis()
        return CapturedClip(text, sensitive, source, timestamp)
    }

    /**
     * Reads the clipboard only if it changed since the last automatic read.
     * Checking the description first (which is not a content read) avoids
     * repeated "pasted from your clipboard" notices on Android 12+, and stops
     * deleted items from being re-added on every resume.
     */
    fun readIfChanged(context: Context, source: String): CapturedClip? {
        val cm = manager(context) ?: return null
        val description = try {
            cm.primaryClipDescription
        } catch (e: SecurityException) {
            null
        } ?: return null
        if (!description.hasMimeType("text/*")) return null

        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val timestamp = description.timestamp
        if (timestamp != 0L && timestamp == prefs.getLong(KEY_LAST_TIMESTAMP, -1L)) return null

        val clip = read(context, source) ?: return null
        prefs.edit().putLong(KEY_LAST_TIMESTAMP, timestamp).apply()
        return clip
    }

    /**
     * Copies [text] to the clipboard. When [sensitive] is true the clip is
     * flagged so Android 13+ hides its content in the copy preview, and other
     * clipboard tools (including Copy Box itself) treat it as sensitive.
     */
    fun write(context: Context, text: String, sensitive: Boolean) {
        val cm = manager(context) ?: return
        val clip = ClipData.newPlainText(CLIP_LABEL, text)
        if (sensitive) {
            clip.description.extras = PersistableBundle().apply {
                putBoolean(EXTRA_IS_SENSITIVE, true)
            }
        }
        cm.setPrimaryClip(clip)
    }
}
