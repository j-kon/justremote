package com.justremote.justremote.remote

import android.util.Log
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.protocol.RemoteConnection
import com.justremote.justremote.remote.protocol.RemoteProtocolClient
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

class TvCommandManager(
    private val remoteProtocolClient: RemoteProtocolClient
) {
    private var connectedDevice: NativeTvDevice? = null
    private var connection: RemoteConnection? = null
    private val commandExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    fun connectToTv(device: NativeTvDevice): Map<String, Any> {
        return try {
            val newConnection = runWithTimeout(CONNECTION_TIMEOUT_SECONDS, "Connection timed out") {
                connection?.close()
                remoteProtocolClient.connect(device)
            }
            connection = newConnection
            connectedDevice = device
            Log.d(TAG, "connectToTv connected to ${device.name}")
            NativeRemoteDiagnostics.setConnection(true, device.name)

            mapOf(
                "success" to true,
                "message" to "Connected"
            )
        } catch (error: Throwable) {
            Log.w(TAG, "connectToTv failed", error)
            connectedDevice = null
            connection?.close()
            connection = null
            val message = error.cleanMessage("Connection failed")
            NativeRemoteDiagnostics.setError(message)
            mapOf(
                "success" to false,
                "message" to message
            )
        }
    }

    fun disconnectTv(): Map<String, Any> {
        Log.d(TAG, "disconnectTv requested")
        connection?.close()
        connection = null
        connectedDevice = null
        NativeRemoteDiagnostics.setConnection(false, null)
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
            val success = runWithTimeout(COMMAND_TIMEOUT_SECONDS, "Command timed out") {
                activeConnection.sendCommand(command)
            }
            if (success) {
                NativeRemoteDiagnostics.record("Command sent: $command")
                mapOf("success" to true)
            } else {
                NativeRemoteDiagnostics.setError("Unsupported command: $command")
                mapOf("success" to false, "message" to "Unsupported command")
            }
        } catch (error: Throwable) {
            Log.w(TAG, "sendCommand failed", error)
            val message = error.cleanMessage("Command failed")
            NativeRemoteDiagnostics.setError(message)
            mapOf("success" to false, "message" to message)
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
        commandExecutor.shutdownNow()
    }

    private fun <T> runWithTimeout(timeoutSeconds: Long, timeoutMessage: String, block: () -> T): T {
        val future = commandExecutor.submit<T> { block() }
        return try {
            future.get(timeoutSeconds, TimeUnit.SECONDS)
        } catch (error: TimeoutException) {
            future.cancel(true)
            throw TimeoutException(timeoutMessage)
        }
    }

    private fun Throwable.cleanMessage(fallback: String): String {
        return message?.takeIf { it.isNotBlank() } ?: fallback
    }

    private companion object {
        const val TAG = "TvCommandManager"
        const val CONNECTION_TIMEOUT_SECONDS = 15L
        const val COMMAND_TIMEOUT_SECONDS = 5L
    }
}
