package com.justremote.justremote.remote

import android.util.Log
import com.justremote.justremote.remote.models.NativePairingStatus
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.protocol.PairingProtocolClient
import com.justremote.justremote.remote.protocol.PairingSession
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

class TvPairingManager(
    private val pairingProtocolClient: PairingProtocolClient
) {
    private val activeSessions = ConcurrentHashMap<String, PairingSession>()
    private val pairingExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    fun pairTv(device: NativeTvDevice, pairingCode: String): NativePairingStatus {
        Log.d(TAG, "pairTv requested for ${device.name} at ${device.host}:${device.port}")

        return try {
            if (pairingProtocolClient.isPaired(device)) {
                Log.d(TAG, "pairTv skipped because ${device.name} is already paired")
                return NativePairingStatus(true, "Already paired")
            }

            if (pairingCode.isBlank()) {
                runWithTimeout(PAIRING_TIMEOUT_SECONDS, "Pairing timed out") {
                    activeSessions[device.sessionKey()]?.close()
                    activeSessions[device.sessionKey()] = pairingProtocolClient.startPairing(device)
                }
                Log.d(TAG, "Pairing challenge started for ${device.name}")
                NativePairingStatus(true, "Pairing started. Enter the code shown on your TV.")
            } else {
                runWithTimeout(PAIRING_TIMEOUT_SECONDS, "Pairing timed out") {
                    val session = activeSessions.remove(device.sessionKey())
                        ?: pairingProtocolClient.startPairing(device)
                    session.use {
                        pairingProtocolClient.finishPairing(it, pairingCode)
                    }
                }
                Log.d(TAG, "Pairing completed for ${device.name}")
                NativePairingStatus(true, "Paired successfully")
            }
        } catch (error: Throwable) {
            activeSessions.remove(device.sessionKey())?.close()
            Log.w(TAG, "Pairing failed", error)
            NativePairingStatus(false, error.cleanMessage("Pairing failed"))
        }
    }

    fun dispose() {
        activeSessions.values.forEach { it.close() }
        activeSessions.clear()
        pairingExecutor.shutdownNow()
    }

    private fun <T> runWithTimeout(timeoutSeconds: Long, timeoutMessage: String, block: () -> T): T {
        val future = pairingExecutor.submit<T> { block() }
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

    private fun NativeTvDevice.sessionKey(): String = "$id-$host"

    private companion object {
        const val TAG = "TvPairingManager"
        const val PAIRING_TIMEOUT_SECONDS = 30L
    }
}
