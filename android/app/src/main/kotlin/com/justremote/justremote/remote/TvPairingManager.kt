package com.justremote.justremote.remote

import android.util.Log
import com.justremote.justremote.remote.models.NativePairingStatus
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.protocol.PairingProtocolClient
import com.justremote.justremote.remote.protocol.PairingSession
import java.util.concurrent.ConcurrentHashMap

class TvPairingManager(
    private val pairingProtocolClient: PairingProtocolClient
) {
    private val activeSessions = ConcurrentHashMap<String, PairingSession>()

    fun pairTv(device: NativeTvDevice, pairingCode: String): NativePairingStatus {
        Log.d(TAG, "pairTv requested for ${device.name} at ${device.host}:${device.port}")

        return try {
            if (pairingCode.isBlank()) {
                activeSessions[device.sessionKey()]?.close()
                activeSessions[device.sessionKey()] = pairingProtocolClient.startPairing(device)
                NativePairingStatus(true, "Pairing started. Enter the code shown on your TV.")
            } else {
                val session = activeSessions.remove(device.sessionKey())
                    ?: pairingProtocolClient.startPairing(device)
                session.use {
                    pairingProtocolClient.finishPairing(it, pairingCode)
                }
                NativePairingStatus(true, "Paired successfully")
            }
        } catch (error: Throwable) {
            activeSessions.remove(device.sessionKey())?.close()
            Log.w(TAG, "Pairing failed", error)
            NativePairingStatus(false, error.message ?: "Pairing failed")
        }
    }

    fun dispose() {
        activeSessions.values.forEach { it.close() }
        activeSessions.clear()
    }

    private fun NativeTvDevice.sessionKey(): String = "$id-$host"

    private companion object {
        const val TAG = "TvPairingManager"
    }
}
