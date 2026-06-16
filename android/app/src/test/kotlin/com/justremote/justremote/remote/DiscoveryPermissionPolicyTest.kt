package com.justremote.justremote.remote

import org.junit.Assert.assertEquals
import org.junit.Test

class DiscoveryPermissionPolicyTest {
    @Test
    fun `android 13 and 14 require nearby wifi permission only`() {
        val needed = DiscoveryPermissionPolicy.missingPermissions(
            sdkInt = 34,
            isGranted = { false }
        )

        assertEquals(listOf(DiscoveryPermissionPolicy.NEARBY_WIFI_DEVICES), needed)
    }

    @Test
    fun `android 15 and newer require nearby wifi and local network permissions`() {
        val needed = DiscoveryPermissionPolicy.missingPermissions(
            sdkInt = 35,
            isGranted = { false }
        )

        assertEquals(
            listOf(
                DiscoveryPermissionPolicy.NEARBY_WIFI_DEVICES,
                DiscoveryPermissionPolicy.ACCESS_LOCAL_NETWORK
            ),
            needed
        )
    }

    @Test
    fun `granted permissions are not requested again`() {
        val needed = DiscoveryPermissionPolicy.missingPermissions(
            sdkInt = 35,
            isGranted = { true }
        )

        assertEquals(emptyList<String>(), needed)
    }
}
