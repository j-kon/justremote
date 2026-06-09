package com.justremote.justremote.remote

object DiscoveryPermissionPolicy {
    const val NEARBY_WIFI_DEVICES = "android.permission.NEARBY_WIFI_DEVICES"
    const val ACCESS_LOCAL_NETWORK = "android.permission.ACCESS_LOCAL_NETWORK"

    fun missingPermissions(
        sdkInt: Int,
        isGranted: (String) -> Boolean
    ): List<String> {
        return buildList {
            if (sdkInt >= ANDROID_13 && !isGranted(NEARBY_WIFI_DEVICES)) {
                add(NEARBY_WIFI_DEVICES)
            }
            if (sdkInt >= ANDROID_15 && !isGranted(ACCESS_LOCAL_NETWORK)) {
                add(ACCESS_LOCAL_NETWORK)
            }
        }
    }

    private const val ANDROID_13 = 33
    private const val ANDROID_15 = 35
}

interface DiscoveryPermissionRequester {
    fun ensureDiscoveryPermissionsGranted(): Boolean
}
