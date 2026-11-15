package com.clipsave.app

import android.app.Activity
import android.app.StatusBarManager
import android.content.ComponentName
import android.graphics.drawable.Icon
import android.os.Build

/** Asks the system to add the Copy Box tile to Quick Settings (Android 13+). */
object TileHelper {

    /**
     * Calls [callback] exactly once with one of:
     * "added", "already_added", "not_added", "unsupported", "error".
     */
    fun requestAddTile(activity: Activity, callback: (String) -> Unit) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            callback("unsupported")
            return
        }
        val statusBar = activity.getSystemService(StatusBarManager::class.java)
        if (statusBar == null) {
            callback("unsupported")
            return
        }
        try {
            statusBar.requestAddTileService(
                ComponentName(activity, ClipTileService::class.java),
                activity.getString(R.string.tile_label),
                Icon.createWithResource(activity, R.drawable.ic_tile_clip),
                activity.mainExecutor,
            ) { code ->
                callback(
                    when (code) {
                        StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED -> "added"
                        StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED -> "already_added"
                        StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED -> "not_added"
                        else -> "error"
                    },
                )
            }
        } catch (e: Exception) {
            callback("error")
        }
    }
}
