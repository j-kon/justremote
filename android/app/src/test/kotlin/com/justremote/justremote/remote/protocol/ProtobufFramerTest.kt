package com.justremote.justremote.remote.protocol

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class ProtobufFramerTest {
    @Test
    fun writesAndReadsVarintLengthDelimitedPayload() {
        val payload = byteArrayOf(1, 2, 3, 4, 5)
        val output = ByteArrayOutputStream()

        ProtobufFramer.writeDelimited(output, payload)

        val decoded = ProtobufFramer.readDelimited(ByteArrayInputStream(output.toByteArray()))

        assertArrayEquals(payload, decoded)
    }

    @Test
    fun supportsPayloadsLongerThanSingleByteVarint() {
        val payload = ByteArray(260) { it.toByte() }
        val output = ByteArrayOutputStream()

        ProtobufFramer.writeDelimited(output, payload)

        val encoded = output.toByteArray()
        assertEquals(0x84, encoded.first().toInt() and 0xff)
        assertArrayEquals(payload, ProtobufFramer.readDelimited(ByteArrayInputStream(encoded)))
    }
}
