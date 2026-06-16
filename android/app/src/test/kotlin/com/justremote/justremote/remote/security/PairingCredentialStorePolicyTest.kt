package com.justremote.justremote.remote.security

import org.junit.Assert.assertFalse
import org.junit.Test

class PairingCredentialStorePolicyTest {
    @Test
    fun `android tv tls client identity does not use android keystore`() {
        assertFalse(PairingCredentialStore.USES_ANDROID_KEYSTORE_FOR_CLIENT_TLS)
    }
}
