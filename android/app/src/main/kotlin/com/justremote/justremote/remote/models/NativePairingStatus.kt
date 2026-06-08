package com.justremote.justremote.remote.models

data class NativePairingStatus(
    val success: Boolean,
    val message: String
) {
    fun toMap(): Map<String, Any> = mapOf(
        "success" to success,
        "message" to message
    )
}
