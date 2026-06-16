package com.justremote.justremote.remote.protocol

import android.util.Log
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteConfigure
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteDeviceInfo
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteMessage
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemotePingResponse
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteSetActive
import com.justremote.justremote.remote.security.PairingCredentialStore
import com.justremote.justremote.remote.security.TlsSocketFactory
import java.io.EOFException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLSocket

class RemoteProtocolClient(
    private val credentialStore: PairingCredentialStore,
    private val socketFactory: TlsSocketFactory
) {
    fun connect(device: NativeTvDevice): RemoteConnection {
        check(credentialStore.isPaired(device)) {
            "TV is not paired. Pair ${device.name} before connecting."
        }
        val remotePort = AndroidTvPorts.remotePort(device.port)
        val socket = socketFactory.createSocket(
            host = device.host,
            port = remotePort,
            readTimeoutMs = 0
        )
        return RemoteConnection(device, socket).also { it.start() }
    }
}

class RemoteConnection(
    val device: NativeTvDevice,
    private val socket: SSLSocket
) : AutoCloseable {
    private val startedLatch = CountDownLatch(1)
    @Volatile
    var isStarted: Boolean = false
        private set
    @Volatile
    var isClosed: Boolean = false
        private set

    fun start() {
        // After pairing, Remote Protocol v2 opens a mutually authenticated TLS
        // connection on the discovered remote port. The TV sends configuration,
        // active-feature, ping, and start messages; the client replies with the
        // feature set it supports before key injection is usable.
        Thread({ readLoop() }, "JustRemote-${device.name}-remote").apply {
            isDaemon = true
            start()
        }
        val started = startedLatch.await(REMOTE_START_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        if (!started || isClosed) {
            close()
            error("Connection timed out")
        }
    }

    @Synchronized
    fun sendCommand(command: String): Boolean {
        check(!isClosed) { "Connection is closed" }
        val message = RemoteCommandMapper.toKeyInjectMessage(command) ?: return false
        // Key presses are encoded as RemoteKeyInject messages with a SHORT
        // direction, which Android TV treats like a normal remote-button press.
        ProtobufFramer.writeDelimited(socket.outputStream, message.toByteArray())
        return true
    }

    private fun readLoop() {
        try {
            while (!isClosed) {
                val message = RemoteMessage.parseFrom(ProtobufFramer.readDelimited(socket.inputStream))
                handleMessage(message)
            }
        } catch (error: EOFException) {
            Log.d(TAG, "Remote connection closed by TV")
        } catch (error: Throwable) {
            if (!isClosed) Log.w(TAG, "Remote read loop failed", error)
        } finally {
            isClosed = true
            startedLatch.countDown()
        }
    }

    private fun handleMessage(message: RemoteMessage) {
        when {
            message.hasRemoteConfigure() -> {
                val supportedFeatures = message.remoteConfigure.code1
                val activeFeatures = supportedFeatures and REQUESTED_FEATURES
                send(
                    RemoteMessage.newBuilder()
                        .setRemoteConfigure(
                            RemoteConfigure.newBuilder()
                                .setCode1(activeFeatures)
                                .setDeviceInfo(
                                    RemoteDeviceInfo.newBuilder()
                                        .setUnknown1(1)
                                        .setUnknown2("1")
                                        .setPackageName("justremote")
                                        .setAppVersion("1.0.0")
                                )
                        )
                        .build()
                )
            }
            message.hasRemoteSetActive() -> {
                send(
                    RemoteMessage.newBuilder()
                        .setRemoteSetActive(
                            RemoteSetActive.newBuilder()
                                .setActive(REQUESTED_FEATURES)
                        )
                        .build()
                )
            }
            message.hasRemotePingRequest() -> {
                send(
                    RemoteMessage.newBuilder()
                        .setRemotePingResponse(
                            RemotePingResponse.newBuilder()
                                .setVal1(message.remotePingRequest.val1)
                        )
                        .build()
                )
            }
            message.hasRemoteStart() -> {
                isStarted = message.remoteStart.started
                startedLatch.countDown()
            }
        }
    }

    @Synchronized
    private fun send(message: RemoteMessage) {
        ProtobufFramer.writeDelimited(socket.outputStream, message.toByteArray())
    }

    override fun close() {
        isClosed = true
        socket.close()
        startedLatch.countDown()
    }

    private companion object {
        const val TAG = "RemoteConnection"
        const val FEATURE_PING = 1
        const val FEATURE_KEY = 2
        const val FEATURE_POWER = 32
        const val FEATURE_VOLUME = 64
        const val REQUESTED_FEATURES = FEATURE_PING or FEATURE_KEY or FEATURE_POWER or FEATURE_VOLUME
        const val REMOTE_START_TIMEOUT_SECONDS = 4L
    }
}
