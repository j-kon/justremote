package com.justremote.justremote.remote

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TvDiscoveryManagerTest {
    @Test
    fun `builds android tv device from remote service`() {
        val device = TvDiscoveryMapper.toDevice(
            serviceName = "Living Room TV",
            serviceType = "_androidtvremote2._tcp.",
            host = "192.168.1.20",
            port = 6466
        )

        requireNotNull(device)
        assertEquals("tv_living_room_tv_192_168_1_20_6466", device.id)
        assertEquals("Living Room TV", device.name)
        assertEquals("192.168.1.20", device.host)
        assertEquals(6466, device.port)
        assertEquals("android_tv", device.type)
    }

    @Test
    fun `uses default remote port when service port is missing`() {
        val device = TvDiscoveryMapper.toDevice(
            serviceName = "",
            serviceType = "_androidtvremote2._tcp.local.",
            host = "192.168.1.21",
            port = 0
        )

        requireNotNull(device)
        assertEquals("Android TV", device.name)
        assertEquals(6466, device.port)
    }

    @Test
    fun `accepts resolved service type with leading dot`() {
        val device = TvDiscoveryMapper.toDevice(
            serviceName = "Jaykon_TV",
            serviceType = "._androidtvremote2._tcp",
            host = "192.168.1.7",
            port = 6466
        )

        requireNotNull(device)
        assertEquals("Jaykon_TV", device.name)
        assertEquals("192.168.1.7", device.host)
        assertEquals(6466, device.port)
    }

    @Test
    fun `ignores non android tv service`() {
        val device = TvDiscoveryMapper.toDevice(
            serviceName = "Speaker",
            serviceType = "_googlecast._tcp.",
            host = "192.168.1.30",
            port = 8009
        )

        assertNull(device)
    }

    @Test
    fun `ignores services without host`() {
        val device = TvDiscoveryMapper.toDevice(
            serviceName = "Bedroom TV",
            serviceType = "_androidtvremote2._tcp.",
            host = "",
            port = 6466
        )

        assertNull(device)
    }
}
