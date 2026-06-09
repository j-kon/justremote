package com.justremote.justremote.remote.protocol

object AndroidTvPorts {
    private const val DEFAULT_REMOTE_PORT = 6466

    fun remotePort(discoveredPort: Int): Int {
        return if (discoveredPort > 0) discoveredPort else DEFAULT_REMOTE_PORT
    }

    fun pairingPort(discoveredRemotePort: Int): Int {
        return remotePort(discoveredRemotePort) + 1
    }
}
