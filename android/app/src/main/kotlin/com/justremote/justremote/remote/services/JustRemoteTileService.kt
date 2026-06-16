package com.justremote.justremote.remote.services

import android.content.Intent
import android.service.quicksettings.TileService
import com.justremote.justremote.MainActivity

class JustRemoteTileService : TileService() {
    override fun onClick() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        @Suppress("DEPRECATION")
        startActivityAndCollapse(intent)
    }
}
