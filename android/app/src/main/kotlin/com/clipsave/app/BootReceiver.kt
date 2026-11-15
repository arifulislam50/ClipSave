package com.clipsave.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Shows the quick-save notification again after a reboot or an app update,
 * but only if the user turned it on. It does nothing else: it never reads the
 * clipboard and never opens an activity.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> QuickSaveNotification.repostIfNeeded(context)
        }
    }
}
