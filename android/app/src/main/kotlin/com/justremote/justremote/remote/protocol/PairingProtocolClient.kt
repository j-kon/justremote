package com.justremote.justremote.remote.protocol

import com.google.polo.wire.protobuf.PoloProto.Configuration
import com.google.polo.wire.protobuf.PoloProto.Options
import com.google.polo.wire.protobuf.PoloProto.OuterMessage
import com.google.protobuf.ByteString
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.security.PairingCredentialStore
import com.justremote.justremote.remote.security.TlsSocketFactory
import java.math.BigInteger
import java.security.MessageDigest
import java.security.interfaces.RSAPublicKey
import java.security.cert.X509Certificate
import javax.net.ssl.SSLSocket

class PairingProtocolClient(
    private val credentialStore: PairingCredentialStore,
    private val socketFactory: TlsSocketFactory
) {
    fun isPaired(device: NativeTvDevice): Boolean = credentialStore.isPaired(device)

    fun forgetDevice(device: NativeTvDevice) {
        credentialStore.removePairedDevice(device)
    }

    fun resetPairingData() {
        credentialStore.clearPairingData()
    }

    fun startPairing(device: NativeTvDevice): PairingSession {
        val pairingPort = AndroidTvPorts.pairingPort(device.port)
        val socket = socketFactory.createSocket(device.host, pairingPort)
        val session = PairingSession(device, socket, socket.peerCertificate())

        // Android TV Remote Protocol v2 pairs over the Polo protocol on the
        // port immediately after the remote-control port. The client first
        // announces itself, then negotiates hexadecimal code entry as INPUT.
        session.send(
            createMessage().toBuilder()
                .setPairingRequest(
                    com.google.polo.wire.protobuf.PoloProto.PairingRequest.newBuilder()
                        .setServiceName(SERVICE_NAME)
                        .setClientName(CLIENT_NAME)
                )
                .build()
        )

        while (true) {
            val response = session.read()
            ensureOk(response)
            when {
                response.hasPairingRequestAck() -> {
                    val encoding = Options.Encoding.newBuilder()
                        .setType(Options.Encoding.EncodingType.ENCODING_TYPE_HEXADECIMAL)
                        .setSymbolLength(PAIRING_CODE_LENGTH)
                    session.send(
                        createMessage().toBuilder()
                            .setOptions(
                                Options.newBuilder()
                                    .addInputEncodings(encoding)
                                    .setPreferredRole(Options.RoleType.ROLE_TYPE_INPUT)
                            )
                            .build()
                    )
                }
                response.hasOptions() -> {
                    session.send(
                        createMessage().toBuilder()
                            .setConfiguration(
                                Configuration.newBuilder()
                                    .setClientRole(Options.RoleType.ROLE_TYPE_INPUT)
                                    .setEncoding(
                                        Options.Encoding.newBuilder()
                                            .setType(Options.Encoding.EncodingType.ENCODING_TYPE_HEXADECIMAL)
                                            .setSymbolLength(PAIRING_CODE_LENGTH)
                                    )
                            )
                            .build()
                    )
                }
                response.hasConfigurationAck() -> return session
                else -> error("Unexpected pairing response")
            }
        }
    }

    fun finishPairing(session: PairingSession, pairingCode: String) {
        val normalizedCode = pairingCode.trim().uppercase()
        require(normalizedCode.length == PAIRING_CODE_LENGTH) {
            "Pairing code must be 6 hexadecimal characters"
        }
        // The TV never receives the code directly. Both sides combine the
        // client/server RSA certificate public parameters with the entered code
        // and compare the resulting SHA-256 proof.
        val secret = computeSecret(
            clientCertificate = credentialStore.getOrCreateClientIdentity().certificate,
            serverCertificate = session.serverCertificate,
            pairingCode = normalizedCode
        )
        session.send(
            createMessage().toBuilder()
                .setSecret(
                    com.google.polo.wire.protobuf.PoloProto.Secret.newBuilder()
                        .setSecret(ByteString.copyFrom(secret))
                )
                .build()
        )
        val response = session.read()
        ensureOk(response)
        if (!response.hasSecretAck()) error("Android TV rejected pairing secret")
        credentialStore.savePairedDevice(session.device, session.serverCertificate)
    }

    private fun computeSecret(
        clientCertificate: X509Certificate,
        serverCertificate: X509Certificate,
        pairingCode: String
    ): ByteArray {
        val hash = MessageDigest.getInstance("SHA-256")
        val clientPublicKey = clientCertificate.publicKey as RSAPublicKey
        val serverPublicKey = serverCertificate.publicKey as RSAPublicKey
        hash.update(clientPublicKey.modulus.toEvenHexBytes())
        hash.update(clientPublicKey.publicExponent.toEvenHexBytes())
        hash.update(serverPublicKey.modulus.toEvenHexBytes())
        hash.update(serverPublicKey.publicExponent.toEvenHexBytes())
        hash.update(pairingCode.substring(2).hexToBytes())
        val digest = hash.digest()
        check((digest.first().toInt() and 0xff) == pairingCode.substring(0, 2).toInt(16)) {
            "Pairing code does not match TLS certificates"
        }
        return digest
    }

    private fun BigInteger.toEvenHexBytes(): ByteArray {
        val hex = toString(16).uppercase().let {
            if (it.length % 2 == 0) it else "0$it"
        }
        return hex.hexToBytes()
    }

    private fun String.hexToBytes(): ByteArray {
        require(length % 2 == 0) { "Hex string must have an even length" }
        return chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    }

    private fun createMessage(): OuterMessage {
        return OuterMessage.newBuilder()
            .setProtocolVersion(PROTOCOL_VERSION)
            .setStatus(OuterMessage.Status.STATUS_OK)
            .build()
    }

    private fun ensureOk(message: OuterMessage) {
        if (message.status != OuterMessage.Status.STATUS_OK) {
            error("Android TV pairing status: ${message.status}")
        }
    }

    private fun SSLSocket.peerCertificate(): X509Certificate {
        return session.peerCertificates.first() as X509Certificate
    }

    companion object {
        private const val PROTOCOL_VERSION = 2
        private const val PAIRING_CODE_LENGTH = 6
        private const val SERVICE_NAME = "atvremote"
        private const val CLIENT_NAME = "JustRemote"
    }
}

class PairingSession(
    val device: NativeTvDevice,
    private val socket: SSLSocket,
    val serverCertificate: X509Certificate
) : AutoCloseable {
    fun send(message: OuterMessage) {
        ProtobufFramer.writeDelimited(socket.outputStream, message.toByteArray())
    }

    fun read(): OuterMessage {
        return OuterMessage.parseFrom(ProtobufFramer.readDelimited(socket.inputStream))
    }

    override fun close() {
        socket.close()
    }
}
