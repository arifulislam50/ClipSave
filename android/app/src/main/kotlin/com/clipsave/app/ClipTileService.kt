package com.clipsave.app

import android.annotation.SuppressLint
import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick Settings tile: "Save clipboard". One tap from any app opens the
 * invisible [ClipboardCaptureActivity], which reads the clipboard while focused.
 */
class ClipTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile ?: return
        tile.state = Tile.STATE_INACTIVE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = getString(R.string.tile_subtitle)
        }
        tile.updateTile()
    }

    override fun onClick() {
        super.onClick()
        if (isLocked) {
            // The clipboard is unavailable on the keyguard; unlock first.
            unlockAndRun { launchCapture() }
        } else {
            launchCapture()
        }
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    @Suppress("DEPRECATION")
    private fun launchCapture() {
        val intent = Intent(this, ClipboardCaptureActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+: the Intent overload throws for apps targeting API 34+.
            // The creator opt-in keeps the launch allowed under Android 15+
            // background-activity-launch hardening; the launch itself always
            // follows a user tap on the tile.
            val options = ActivityOptions.makeBasic()
                .setPendingIntentCreatorBackgroundActivityStartMode(
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                )
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                options.toBundle(),
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            startActivityAndCollapse(intent)
        }
    }
}
