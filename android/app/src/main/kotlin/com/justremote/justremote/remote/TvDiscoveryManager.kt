package com.justremote.justremote.remote

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.util.Log
import com.justremote.justremote.remote.models.NativeTvDevice
import java.util.Collections
import java.util.Locale
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

class TvDiscoveryManager(
    private val context: Context,
    private val permissionRequester: DiscoveryPermissionRequester? = null
) {
    private val nsdManager: NsdManager? =
        context.getSystemService(Context.NSD_SERVICE) as? NsdManager
    private val wifiManager: WifiManager? =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
    private var discoveryListener: NsdManager.DiscoveryListener? = null
    private var multicastLock: WifiManager.MulticastLock? = null

    fun scanForTvs(): List<NativeTvDevice> {
        Log.d(TAG, "scanForTvs requested")
        logDiscoveryEnvironment()

        return try {
            if (!ensureDiscoveryPermissionsGranted()) {
                Log.w(TAG, "Discovery permissions are not granted; returning no devices")
                return emptyList()
            }
            Log.d(TAG, "Discovery permissions granted; starting NSD")

            val manager = nsdManager
            if (manager == null) {
                Log.w(TAG, "NSD manager is unavailable; returning no devices")
                return emptyList()
            }

            acquireMulticastLock()
            val devices = Collections.synchronizedMap(linkedMapOf<String, NativeTvDevice>())
            SERVICE_TYPES.forEach { serviceType ->
                discoverServiceType(manager, serviceType, devices)
            }

            val discovered = devices.values.toList()
            Log.d(TAG, "scanForTvs finished with ${discovered.size} device(s)")
            NativeRemoteDiagnostics.record("Scan found ${discovered.size} TV(s)")
            discovered
        } catch (error: Throwable) {
            Log.w(TAG, "scanForTvs failed; returning no devices", error)
            NativeRemoteDiagnostics.setError(error.message ?: "Scan failed")
            emptyList()
        } finally {
            releaseMulticastLock()
            discoveryListener = null
        }
    }

    private fun ensureDiscoveryPermissionsGranted(): Boolean {
        if (permissionRequester == null) {
            Log.d(TAG, "No runtime permission requester is attached")
            return missingDiscoveryPermissions().isEmpty()
        }
        return permissionRequester.ensureDiscoveryPermissionsGranted()
    }

    fun dispose() {
        discoveryListener?.let { nsdManager?.stopServiceDiscoverySafely(it) }
        discoveryListener = null
        releaseMulticastLock()
    }

    private fun discoverServiceType(
        manager: NsdManager,
        serviceType: String,
        devices: MutableMap<String, NativeTvDevice>
    ) {
        Log.d(TAG, "Starting Android TV NSD browse for $serviceType")
        val scanFinished = CountDownLatch(1)
        val retries = AtomicInteger(1)

        val listener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(registeredType: String) {
                Log.d(TAG, "NSD discovery started for $registeredType")
            }

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                Log.d(
                    TAG,
                    "NSD service found name=${serviceInfo.serviceName} type=${serviceInfo.serviceType} port=${serviceInfo.port}"
                )
                if (!TvDiscoveryMapper.isAndroidTvRemoteService(serviceInfo.serviceType)) {
                    Log.d(TAG, "Ignoring non Android TV service type=${serviceInfo.serviceType}")
                    return
                }

                resolveService(manager, serviceInfo) { resolved ->
                    val host = resolved.hostAddress()
                    val device = TvDiscoveryMapper.toDevice(
                        serviceName = resolved.serviceName,
                        serviceType = resolved.serviceType,
                        host = host.orEmpty(),
                        port = resolved.port
                    )
                    if (device == null) {
                        Log.d(
                            TAG,
                            "Resolved service is not usable name=${resolved.serviceName} host=$host port=${resolved.port}"
                        )
                        return@resolveService
                    }

                    devices[device.id] = device
                    Log.d(TAG, "Android TV discovered ${device.name} at ${device.host}:${device.port}")
                    NativeRemoteDiagnostics.record("Discovered ${device.name} at ${device.host}:${device.port}")
                }
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) {
                Log.d(TAG, "NSD service lost name=${serviceInfo.serviceName} type=${serviceInfo.serviceType}")
            }

            override fun onDiscoveryStopped(stoppedType: String) {
                Log.d(TAG, "NSD discovery stopped for $stoppedType")
                scanFinished.countDown()
            }

            override fun onStartDiscoveryFailed(failedType: String, errorCode: Int) {
                Log.w(TAG, "NSD discovery failed to start for $failedType: $errorCode")
                manager.stopServiceDiscoverySafely(this)
                // Error 3 = FAILURE_ALREADY_ACTIVE; error 7 = internal FAILURE_MDNS_ALREADY_ACTIVE.
                // Both mean a stale mDNS session is lingering — wait briefly and retry once.
                if (errorCode in ALREADY_ACTIVE_CODES && retries.getAndDecrement() > 0) {
                    try {
                        Thread.sleep(RETRY_DELAY_MS)
                        manager.discoverServices(failedType, NsdManager.PROTOCOL_DNS_SD, this)
                        return
                    } catch (e: Throwable) {
                        Log.w(TAG, "NSD retry threw for $failedType", e)
                    }
                }
                scanFinished.countDown()
            }

            override fun onStopDiscoveryFailed(failedType: String, errorCode: Int) {
                Log.w(TAG, "NSD discovery failed to stop for $failedType: $errorCode")
                scanFinished.countDown()
            }
        }

        discoveryListener = listener
        try {
            manager.discoverServices(serviceType, NsdManager.PROTOCOL_DNS_SD, listener)
            val stoppedByCallback = scanFinished.await(SCAN_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            if (!stoppedByCallback) {
                Log.d(TAG, "NSD discovery timed out for $serviceType after ${SCAN_TIMEOUT_SECONDS}s")
            }
        } catch (error: Throwable) {
            Log.w(TAG, "Unable to run NSD discovery for $serviceType", error)
        } finally {
            manager.stopServiceDiscoverySafely(listener)
        }
    }

    private fun resolveService(
        manager: NsdManager,
        serviceInfo: NsdServiceInfo,
        onResolved: (NsdServiceInfo) -> Unit
    ) {
        Log.d(TAG, "Resolving NSD service name=${serviceInfo.serviceName} type=${serviceInfo.serviceType}")
        try {
            manager.resolveService(
                serviceInfo,
                object : NsdManager.ResolveListener {
                    override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                        Log.w(
                            TAG,
                            "NSD resolve failed for ${serviceInfo.serviceName} type=${serviceInfo.serviceType}: $errorCode"
                        )
                    }

                    override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                        Log.d(
                            TAG,
                            "NSD resolved ${serviceInfo.serviceName} type=${serviceInfo.serviceType} at ${serviceInfo.hostAddress()}:${serviceInfo.port}"
                        )
                        onResolved(serviceInfo)
                    }
                }
            )
        } catch (error: Throwable) {
            Log.w(TAG, "NSD resolve threw for ${serviceInfo.serviceName}", error)
        }
    }

    private fun NsdServiceInfo.hostAddress(): String? {
        val address = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            hostAddresses.firstOrNull { !it.isAnyLocalAddress }?.hostAddress
        } else {
            null
        }
        if (!address.isNullOrBlank()) return address

        @Suppress("DEPRECATION")
        return host?.hostAddress
    }

    private fun NsdManager.stopServiceDiscoverySafely(listener: NsdManager.DiscoveryListener) {
        try {
            stopServiceDiscovery(listener)
        } catch (error: IllegalArgumentException) {
            Log.d(TAG, "NSD discovery already stopped")
        } catch (error: Throwable) {
            Log.w(TAG, "Unable to stop NSD discovery", error)
        }
    }

    private fun acquireMulticastLock() {
        val manager = wifiManager
        if (manager == null) {
            Log.d(TAG, "WifiManager unavailable; scanning without multicast lock")
            return
        }

        try {
            multicastLock = manager.createMulticastLock(MULTICAST_LOCK_TAG).apply {
                setReferenceCounted(false)
                acquire()
            }
            Log.d(TAG, "Wi-Fi multicast lock acquired")
        } catch (error: Throwable) {
            Log.w(TAG, "Unable to acquire Wi-Fi multicast lock; NSD may still work", error)
            multicastLock = null
        }
    }

    private fun releaseMulticastLock() {
        try {
            multicastLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "Wi-Fi multicast lock released")
                }
            }
        } catch (error: Throwable) {
            Log.w(TAG, "Unable to release Wi-Fi multicast lock", error)
        } finally {
            multicastLock = null
        }
    }

    private fun logDiscoveryEnvironment() {
        Log.d(TAG, "NSD available=${nsdManager != null}")
        Log.d(TAG, "Wi-Fi multicast lock available=${wifiManager != null}")
        Log.d(TAG, "ACCESS_WIFI_STATE granted=${isPermissionGranted(Manifest.permission.ACCESS_WIFI_STATE)}")
        Log.d(
            TAG,
            "CHANGE_WIFI_MULTICAST_STATE granted=${isPermissionGranted(Manifest.permission.CHANGE_WIFI_MULTICAST_STATE)}"
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Log.d(TAG, "NEARBY_WIFI_DEVICES granted=${isPermissionGranted(Manifest.permission.NEARBY_WIFI_DEVICES)}")
        }
        Log.d(TAG, "ACCESS_LOCAL_NETWORK granted=${isPermissionGranted(ACCESS_LOCAL_NETWORK_PERMISSION)}")
    }

    private fun missingDiscoveryPermissions(): List<String> {
        return DiscoveryPermissionPolicy.missingPermissions(
            sdkInt = Build.VERSION.SDK_INT,
            isGranted = ::isPermissionGranted
        )
    }

    private fun isPermissionGranted(permission: String): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private companion object {
        const val TAG = "TvDiscoveryManager"
        const val MULTICAST_LOCK_TAG = "JustRemoteTvDiscovery"
        const val ACCESS_LOCAL_NETWORK_PERMISSION = "android.permission.ACCESS_LOCAL_NETWORK"
        val SERVICE_TYPES = listOf("_androidtvremote2._tcp.", "_androidtvremote._tcp.")
        const val SCAN_TIMEOUT_SECONDS = 4L
        // 3 = FAILURE_ALREADY_ACTIVE; 7 = internal FAILURE_MDNS_ALREADY_ACTIVE (API 31+)
        val ALREADY_ACTIVE_CODES = setOf(3, 7)
        const val RETRY_DELAY_MS = 300L
    }
}

internal object TvDiscoveryMapper {
    private const val REMOTE_PORT = 6466
    private val androidTvServiceTypes = setOf("_androidtvremote2._tcp", "_androidtvremote._tcp")

    fun toDevice(
        serviceName: String,
        serviceType: String,
        host: String,
        port: Int
    ): NativeTvDevice? {
        if (!isAndroidTvRemoteService(serviceType) || host.isBlank()) return null

        val deviceName = serviceName.trim().ifBlank { "Android TV" }
        val devicePort = if (port > 0) port else REMOTE_PORT
        return NativeTvDevice(
            id = buildStableId(deviceName, host, devicePort),
            name = deviceName,
            host = host,
            port = devicePort
        )
    }

    fun isAndroidTvRemoteService(serviceType: String): Boolean {
        val normalized = serviceType.trim().lowercase(Locale.US)
            .removeSuffix(".local.")
            .removeSuffix(".")
            .removePrefix(".")
        return normalized in androidTvServiceTypes
    }

    private fun buildStableId(name: String, host: String, port: Int): String {
        val raw = "${name}_${host}_$port".lowercase(Locale.US)
        val slug = raw.replace(Regex("[^a-z0-9]+"), "_").trim('_')
        return "tv_$slug"
    }
}
