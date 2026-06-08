package com.justremote.justremote.remote

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import android.util.Log
import com.justremote.justremote.remote.models.NativeTvDevice
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class TvDiscoveryManager(private val context: Context) {
    private val nsdManager: NsdManager? =
        context.getSystemService(Context.NSD_SERVICE) as? NsdManager
    private var discoveryListener: NsdManager.DiscoveryListener? = null

    fun scanForTvs(): List<NativeTvDevice> {
        Log.d(TAG, "scanForTvs requested. NSD available=${nsdManager != null}")
        val manager = nsdManager ?: return emptyList()
        val devices = Collections.synchronizedMap(linkedMapOf<String, NativeTvDevice>())
        val scanFinished = CountDownLatch(1)

        val listener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) {
                Log.d(TAG, "NSD discovery started for $serviceType")
            }

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                if (!serviceInfo.serviceType.contains(REMOTE_SERVICE_TYPE.trimEnd('.'))) {
                    return
                }
                resolveService(manager, serviceInfo) { resolved ->
                    val host = resolved.hostAddress() ?: return@resolveService
                    val port = if (resolved.port > 0) resolved.port else REMOTE_PORT
                    val id = "${resolved.serviceName}-$host-$port"
                    devices[id] = NativeTvDevice(
                        id = id,
                        name = resolved.serviceName.ifBlank { "Android TV" },
                        host = host,
                        port = port
                    )
                }
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) {
                Log.d(TAG, "NSD service lost: ${serviceInfo.serviceName}")
            }

            override fun onDiscoveryStopped(serviceType: String) {
                scanFinished.countDown()
            }

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.w(TAG, "NSD discovery failed to start: $errorCode")
                manager.stopServiceDiscoverySafely(this)
                scanFinished.countDown()
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.w(TAG, "NSD discovery failed to stop: $errorCode")
                scanFinished.countDown()
            }
        }

        discoveryListener = listener
        manager.discoverServices(REMOTE_SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, listener)
        scanFinished.await(SCAN_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        manager.stopServiceDiscoverySafely(listener)
        discoveryListener = null

        return devices.values.toList()
    }

    fun dispose() {
        discoveryListener?.let { nsdManager?.stopServiceDiscoverySafely(it) }
        discoveryListener = null
    }

    private fun resolveService(
        manager: NsdManager,
        serviceInfo: NsdServiceInfo,
        onResolved: (NsdServiceInfo) -> Unit
    ) {
        manager.resolveService(
            serviceInfo,
            object : NsdManager.ResolveListener {
                override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                    Log.w(TAG, "NSD resolve failed for ${serviceInfo.serviceName}: $errorCode")
                }

                override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                    Log.d(TAG, "NSD resolved ${serviceInfo.serviceName} at ${serviceInfo.hostAddress()}")
                    onResolved(serviceInfo)
                }
            }
        )
    }

    private fun NsdServiceInfo.hostAddress(): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            hostAddresses.firstOrNull()?.hostAddress
        } else {
            @Suppress("DEPRECATION")
            host?.hostAddress
        }
    }

    private fun NsdManager.stopServiceDiscoverySafely(listener: NsdManager.DiscoveryListener) {
        try {
            stopServiceDiscovery(listener)
        } catch (error: IllegalArgumentException) {
            Log.d(TAG, "NSD discovery already stopped")
        }
    }

    private companion object {
        const val TAG = "TvDiscoveryManager"
        const val REMOTE_SERVICE_TYPE = "_androidtvremote2._tcp."
        const val REMOTE_PORT = 6466
        const val SCAN_TIMEOUT_SECONDS = 4L
    }
}
