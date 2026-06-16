package com.justremote.justremote.remote

object NativeRemoteDiagnostics {
    private const val MAX_EVENTS = 30
    private val events = ArrayDeque<String>()

    @Volatile
    private var connected: Boolean = false
    @Volatile
    private var deviceName: String? = null
    @Volatile
    private var lastError: String? = null

    @Synchronized
    fun record(message: String) {
        events.addFirst(message)
        while (events.size > MAX_EVENTS) events.removeLast()
    }

    fun setConnection(isConnected: Boolean, name: String?) {
        connected = isConnected
        deviceName = name
        record(if (isConnected) "Connected to ${name ?: "TV"}" else "Disconnected")
    }

    fun setError(message: String) {
        lastError = message
        record("Error: $message")
    }

    @Synchronized
    fun snapshot(): Map<String, Any?> {
        return mapOf(
            "connected" to connected,
            "deviceName" to deviceName,
            "lastError" to lastError,
            "events" to events.toList()
        )
    }
}
