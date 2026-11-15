package com.clipsave.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * Small private queue for text captured while the Flutter UI is not running
 * (Quick Settings tile, share sheet, text-selection menu). Flutter drains it
 * on launch and on every resume, applies the sensitive-text filter, and is
 * the only component that writes the SQLite database.
 *
 * The queue lives in app-private SharedPreferences, which is excluded from
 * backup and device transfer (see res/xml/data_extraction_rules.xml).
 */
object ClipInbox {
    private const val PREFS = "clipsave_inbox"
    private const val KEY_ITEMS = "items"
    private const val MAX_ITEMS = 200

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun load(context: Context): JSONArray = try {
        JSONArray(prefs(context).getString(KEY_ITEMS, "[]") ?: "[]")
    } catch (e: JSONException) {
        JSONArray()
    }

    @Synchronized
    fun add(context: Context, clip: CapturedClip) {
        if (clip.text.isBlank() || clip.text.length > ClipReader.MAX_CLIP_LENGTH) return
        val items = load(context)
        items.put(
            JSONObject()
                .put("text", clip.text)
                .put("sensitive", clip.sensitive)
                .put("source", clip.source)
                .put("timestamp", clip.timestamp),
        )
        while (items.length() > MAX_ITEMS) items.remove(0)
        // commit() (synchronous) so the item survives the activity finishing immediately.
        prefs(context).edit().putString(KEY_ITEMS, items.toString()).commit()
    }

    @Synchronized
    fun drain(context: Context): List<Map<String, Any>> {
        val items = load(context)
        val result = ArrayList<Map<String, Any>>(items.length())
        for (i in 0 until items.length()) {
            val o = items.optJSONObject(i) ?: continue
            val text = o.optString("text", "")
            if (text.isBlank()) continue
            result.add(
                mapOf(
                    "text" to text,
                    "sensitive" to o.optBoolean("sensitive", false),
                    "source" to o.optString("source", "share"),
                    "timestamp" to o.optLong("timestamp", System.currentTimeMillis()),
                ),
            )
        }
        prefs(context).edit().remove(KEY_ITEMS).commit()
        return result
    }
}
