package com.justremote.justremote.remote.protocol

import org.junit.Assert.assertEquals
import org.junit.Test

class AndroidTvPortsTest {
    @Test
    fun `remote control uses discovered port`() {
        assertEquals(6466, AndroidTvPorts.remotePort(6466))
        assertEquals(7000, AndroidTvPorts.remotePort(7000))
    }

    @Test
    fun `pairing uses port after discovered remote port`() {
        assertEquals(6467, AndroidTvPorts.pairingPort(6466))
        assertEquals(7001, AndroidTvPorts.pairingPort(7000))
    }

    @Test
    fun `invalid discovered ports fall back to android tv defaults`() {
        assertEquals(6466, AndroidTvPorts.remotePort(0))
        assertEquals(6467, AndroidTvPorts.pairingPort(0))
    }
}
