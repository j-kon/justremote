package com.justremote.justremote.remote.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.RemoteViews
import android.widget.Toast
import com.justremote.justremote.R
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.protocol.RemoteConnection
import com.justremote.justremote.remote.protocol.RemoteProtocolClient
import com.justremote.justremote.remote.security.PairingCredentialStore
import com.justremote.justremote.remote.security.TlsSocketFactory
import java.util.concurrent.Executors

class JustRemoteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val credentialStore = PairingCredentialStore(context)
        val activeTv = credentialStore.getLastConnectedTv() ?: credentialStore.getFallbackTv(context)
        val tvName = activeTv?.name ?: "No TV Paired"

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            views.setTextViewText(R.id.txt_widget_tv_name, tvName)

            // Bind button click intents
            views.setOnClickPendingIntent(R.id.btn_power, getPendingSelfIntent(context, "power"))
            views.setOnClickPendingIntent(R.id.btn_vol_down, getPendingSelfIntent(context, "volumeDown"))
            views.setOnClickPendingIntent(R.id.btn_mute, getPendingSelfIntent(context, "mute"))
            views.setOnClickPendingIntent(R.id.btn_vol_up, getPendingSelfIntent(context, "volumeUp"))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun getPendingSelfIntent(context: Context, command: String): PendingIntent {
        val intent = Intent(context, JustRemoteWidgetProvider::class.java).apply {
            action = ACTION_WIDGET_COMMAND
            putExtra(EXTRA_COMMAND, command)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val requestCode = command.hashCode()
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_WIDGET_COMMAND) {
            val command = intent.getStringExtra(EXTRA_COMMAND) ?: return
            Log.d(TAG, "Widget action received: $command")
            
            executor.execute {
                handleWidgetCommand(context, command)
            }
        }
    }

    private fun handleWidgetCommand(context: Context, command: String) {
        try {
            val credentialStore = PairingCredentialStore(context)
            val tvDevice = credentialStore.getLastConnectedTv() ?: credentialStore.getFallbackTv(context)
            if (tvDevice == null) {
                showToast(context, "Please open the app to connect to a TV")
                return
            }

            // Update widget text to show targeted TV
            updateWidgetTvName(context, tvDevice.name)

            // Cancel any pending disconnect
            cancelDisconnectTimer()

            var connection = activeConnection
            if (connection != null && !connection.isClosed && connection.device.id == tvDevice.id) {
                Log.d(TAG, "Reusing cached connection to ${tvDevice.name}")
            } else {
                connection?.close()
                Log.d(TAG, "Connecting to ${tvDevice.name}...")
                
                val socketFactory = TlsSocketFactory(credentialStore)
                val client = RemoteProtocolClient(credentialStore, socketFactory)
                connection = client.connect(tvDevice)
                activeConnection = connection
            }

            val success = connection.sendCommand(command)
            if (success) {
                Log.d(TAG, "Successfully sent command: $command")
            } else {
                Log.w(TAG, "Failed to send command: $command")
                showToast(context, "Failed to send command")
            }

            scheduleDisconnect()

        } catch (e: Exception) {
            Log.e(TAG, "Error executing widget command", e)
            showToast(context, "Could not connect to TV")
            cleanupConnection()
        }
    }

    private fun updateWidgetTvName(context: Context, tvName: String) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, JustRemoteWidgetProvider::class.java)
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            views.setTextViewText(R.id.txt_widget_tv_name, tvName)
            appWidgetManager.partiallyUpdateAppWidget(appWidgetManager.getAppWidgetIds(thisWidget), views)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to update widget text label", e)
        }
    }

    private fun showToast(context: Context, message: String) {
        handler.post {
            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
        }
    }

    private fun scheduleDisconnect() {
        handler.post {
            disconnectRunnable?.let { handler.removeCallbacks(it) }
            val runnable = Runnable {
                executor.execute {
                    Log.d(TAG, "Inactivity timeout: closing connection")
                    cleanupConnection()
                }
            }
            disconnectRunnable = runnable
            handler.postDelayed(runnable, KEEP_ALIVE_MS)
        }
    }

    private fun cancelDisconnectTimer() {
        handler.post {
            disconnectRunnable?.let {
                handler.removeCallbacks(it)
                disconnectRunnable = null
            }
        }
    }

    private fun cleanupConnection() {
        activeConnection?.close()
        activeConnection = null
    }

    companion object {
        private const val TAG = "JustRemoteWidget"
        private const val ACTION_WIDGET_COMMAND = "com.justremote.ACTION_WIDGET_COMMAND"
        private const val EXTRA_COMMAND = "extra_command"

        @Volatile
        private var activeConnection: RemoteConnection? = null
        private val executor = Executors.newSingleThreadExecutor()
        private val handler = Handler(Looper.getMainLooper())
        private var disconnectRunnable: Runnable? = null
        private const val KEEP_ALIVE_MS = 6000L
    }
}
