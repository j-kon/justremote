package com.justremote.justremote.remote.security

import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.net.InetSocketAddress
import java.net.Socket
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLHandshakeException
import javax.net.ssl.SSLSocket
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

class TlsSocketFactory(private val credentialStore: PairingCredentialStore) {
    fun createSocket(
        host: String,
        port: Int,
        connectTimeoutMs: Int = SOCKET_TIMEOUT_MS,
        readTimeoutMs: Int = SOCKET_TIMEOUT_MS
    ): SSLSocket {
        return try {
            createSocketInternal(host, port, connectTimeoutMs, readTimeoutMs)
        } catch (e: SSLHandshakeException) {
            // If the stored TLS client identity is stale or incompatible with
            // Android TV's legacy TLS handshake, regenerate it and retry once.
            credentialStore.resetClientIdentity()
            createSocketInternal(host, port, connectTimeoutMs, readTimeoutMs)
        }
    }

    private fun createSocketInternal(
        host: String,
        port: Int,
        connectTimeoutMs: Int,
        readTimeoutMs: Int
    ): SSLSocket {
        val tcpSocket = Socket().apply {
            connect(InetSocketAddress(host, port), connectTimeoutMs)
        }
        val context = SSLContext.getInstance("TLS").apply {
            init(credentialStore.getOrCreateClientKeyManagers(), arrayOf(trustAllManager), SecureRandom())
        }
        return (context.socketFactory.createSocket(tcpSocket, host, port, true) as SSLSocket).apply {
            soTimeout = readTimeoutMs
            useClientMode = true
            startHandshake()
        }
    }

    private companion object {
        const val SOCKET_TIMEOUT_MS = 10_000

        val trustAllManager = object : X509TrustManager {
            override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
            override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
            override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
        } as TrustManager
    }
}
