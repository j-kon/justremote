package com.justremote.justremote.remote.models

data class NativeTvDevice(
    val id: String,
    val name: String,
    val host: String,
    val port: Int,
    val type: String = "android_tv"
) {
    fun toMap(): Map<String, Any> = mapOf(
        "id" to id,
        "name" to name,
        "host" to host,
        "port" to port,
        "type" to type
    )

    companion object {
        fun fromArguments(arguments: Map<*, *>): NativeTvDevice {
            return NativeTvDevice(
                id = arguments["deviceId"] as? String ?: arguments["id"] as? String ?: "",
                name = arguments["name"] as? String ?: "Android TV",
                host = arguments["host"] as? String ?: "",
                port = (arguments["port"] as? Number)?.toInt() ?: 6466,
                type = arguments["type"] as? String ?: "android_tv"
            )
        }
    }
}
