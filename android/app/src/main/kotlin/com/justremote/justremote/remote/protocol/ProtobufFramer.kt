package com.justremote.justremote.remote.protocol

import java.io.EOFException
import java.io.InputStream
import java.io.OutputStream

object ProtobufFramer {
    fun writeDelimited(output: OutputStream, payload: ByteArray) {
        writeRawVarint32(output, payload.size)
        output.write(payload)
        output.flush()
    }

    fun readDelimited(input: InputStream): ByteArray {
        val size = readRawVarint32(input)
        val payload = ByteArray(size)
        var offset = 0
        while (offset < size) {
            val read = input.read(payload, offset, size - offset)
            if (read == -1) throw EOFException("Connection closed while reading protobuf payload")
            offset += read
        }
        return payload
    }

    private fun writeRawVarint32(output: OutputStream, value: Int) {
        var remaining = value
        while (true) {
            if ((remaining and 0x7f.inv()) == 0) {
                output.write(remaining)
                return
            }
            output.write((remaining and 0x7f) or 0x80)
            remaining = remaining ushr 7
        }
    }

    private fun readRawVarint32(input: InputStream): Int {
        var result = 0
        var shift = 0
        while (shift < 32) {
            val byte = input.read()
            if (byte == -1) throw EOFException("Connection closed while reading protobuf size")
            result = result or ((byte and 0x7f) shl shift)
            if ((byte and 0x80) == 0) return result
            shift += 7
        }
        throw IllegalArgumentException("Malformed protobuf varint")
    }
}
