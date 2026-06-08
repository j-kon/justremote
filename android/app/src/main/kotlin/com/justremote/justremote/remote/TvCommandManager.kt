package com.justremote.justremote.remote

import android.util.Log
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.protocol.RemoteConnection
import com.justremote.justremote.remote.protocol.RemoteProtocolClient

class TvCommandManager(
    private val remoteProtocolClient: RemoteProtocolClient
) {
    private var connectedDevice: NativeTvDevice? = null
    private var connection: RemoteConnection? = null

    fun connectToTv(device: NativeTvDevice): Map<String, Any> {
        return try {
            connection?.close()
            connection = remoteProtocolClient.connect(device)
            connectedDevice = device
            Log.d(TAG, "connectToTv connected to ${device.name}")

            mapOf(
                "success" to true,
                "message" to "Connected"
            )
        } catch (error: Throwable) {
            Log.w(TAG, "connectToTv failed", error)
            connectedDevice = null
            connection = null
            mapOf(
                "success" to false,
                "message" to (error.message ?: "Connection failed")
            )
        }
    }

    fun disconnectTv(): Map<String, Any> {
        Log.d(TAG, "disconnectTv requested")
        connection?.close()
        connection = null
        connectedDevice = null
        return mapOf(
            "success" to true,
            "message" to "Disconnected"
        )
    }

    fun sendCommand(command: String): Map<String, Any> {
        Log.d(TAG, "sendCommand command=$command device=${connectedDevice?.name}")
        val activeConnection = connection
        if (activeConnection == null || activeConnection.isClosed) {
            return mapOf("success" to false, "message" to "Not connected")
        }
        return try {
            mapOf("success" to activeConnection.sendCommand(command))
        } catch (error: Throwable) {
            Log.w(TAG, "sendCommand failed", error)
            mapOf("success" to false, "message" to (error.message ?: "Command failed"))
        }
    }

    fun getConnectionStatus(): Map<String, Any?> {
        val activeConnection = connection
        return mapOf(
            "connected" to (connectedDevice != null && activeConnection?.isClosed == false),
            "deviceName" to connectedDevice?.name
        )
    }

    fun dispose() {
        connection?.close()
        connection = null
        connectedDevice = null
    }

    private companion object {
        const val TAG = "TvCommandManager"
    }
}
