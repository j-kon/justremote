package com.justremote.justremote.remote.security

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import com.justremote.justremote.remote.models.NativeTvDevice
import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.SecureRandom
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.PKCS8EncodedKeySpec
import java.util.Date
import org.bouncycastle.asn1.x500.X500Name
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter
import org.bouncycastle.cert.jcajce.JcaX509v3CertificateBuilder
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder

class PairingCredentialStore(context: Context) {
    private val preferences: SharedPreferences = context.getSharedPreferences(
        "justremote_pairing_credentials",
        Context.MODE_PRIVATE
    )

    @Synchronized
    fun getOrCreateClientIdentity(): ClientIdentity {
        val encodedPrivateKey = preferences.getString(KEY_PRIVATE_KEY, null)
        val encodedCertificate = preferences.getString(KEY_CERTIFICATE, null)
        if (encodedPrivateKey != null && encodedCertificate != null) {
            return ClientIdentity(
                privateKey = decodePrivateKey(encodedPrivateKey),
                certificate = decodeCertificate(encodedCertificate)
            )
        }

        val keyPair = KeyPairGenerator.getInstance("RSA").apply {
            initialize(2048, SecureRandom())
        }.generateKeyPair()
        val certificate = createSelfSignedCertificate(keyPair)

        preferences.edit()
            .putString(KEY_PRIVATE_KEY, encode(keyPair.private.encoded))
            .putString(KEY_CERTIFICATE, encode(certificate.encoded))
            .apply()

        return ClientIdentity(keyPair.private, certificate)
    }

    fun savePairedDevice(device: NativeTvDevice, serverCertificate: X509Certificate) {
        preferences.edit()
            .putString(device.serverCertificateKey(), encode(serverCertificate.encoded))
            .apply()
    }

    fun getServerCertificate(device: NativeTvDevice): X509Certificate? {
        val encoded = preferences.getString(device.serverCertificateKey(), null) ?: return null
        return decodeCertificate(encoded)
    }

    fun isPaired(device: NativeTvDevice): Boolean = getServerCertificate(device) != null

    private fun createSelfSignedCertificate(keyPair: KeyPair): X509Certificate {
        val now = System.currentTimeMillis()
        val subject = X500Name("CN=JustRemote")
        val builder = JcaX509v3CertificateBuilder(
            subject,
            BigInteger(160, SecureRandom()),
            Date(now - ONE_DAY_MS),
            Date(now + TEN_YEARS_MS),
            subject,
            keyPair.public
        )
        val signer = JcaContentSignerBuilder("SHA256withRSA").build(keyPair.private)
        return JcaX509CertificateConverter().getCertificate(builder.build(signer))
    }

    private fun decodePrivateKey(encoded: String): PrivateKey {
        val bytes = Base64.decode(encoded, Base64.NO_WRAP)
        return KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(bytes))
    }

    private fun decodeCertificate(encoded: String): X509Certificate {
        val bytes = Base64.decode(encoded, Base64.NO_WRAP)
        return CertificateFactory.getInstance("X.509")
            .generateCertificate(bytes.inputStream()) as X509Certificate
    }

    private fun encode(bytes: ByteArray): String = Base64.encodeToString(bytes, Base64.NO_WRAP)

    private fun NativeTvDevice.serverCertificateKey(): String = "server_cert_${id}_${host}_$port"

    private companion object {
        const val KEY_PRIVATE_KEY = "client_private_key"
        const val KEY_CERTIFICATE = "client_certificate"
        const val ONE_DAY_MS = 24L * 60L * 60L * 1000L
        const val TEN_YEARS_MS = 3650L * ONE_DAY_MS
    }
}

data class ClientIdentity(
    val privateKey: PrivateKey,
    val certificate: X509Certificate
)
