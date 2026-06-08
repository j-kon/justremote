package com.justremote.justremote.remote.security

import java.security.KeyStore
import java.security.SecureRandom
import java.security.cert.X509Certificate
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

class TlsSocketFactory(private val credentialStore: PairingCredentialStore) {
    fun createSocket(host: String, port: Int): SSLSocket {
        val identity = credentialStore.getOrCreateClientIdentity()
        val keyStore = KeyStore.getInstance(KeyStore.getDefaultType()).apply {
            load(null, null)
            setKeyEntry(
                "justremote",
                identity.privateKey,
                CharArray(0),
                arrayOf(identity.certificate)
            )
        }
        val keyManagerFactory = KeyManagerFactory.getInstance(
            KeyManagerFactory.getDefaultAlgorithm()
        ).apply {
            init(keyStore, CharArray(0))
        }
        val context = SSLContext.getInstance("TLS").apply {
            init(keyManagerFactory.keyManagers, arrayOf(trustAllManager), SecureRandom())
        }
        return (context.socketFactory.createSocket(host, port) as SSLSocket).apply {
            soTimeout = SOCKET_TIMEOUT_MS
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
