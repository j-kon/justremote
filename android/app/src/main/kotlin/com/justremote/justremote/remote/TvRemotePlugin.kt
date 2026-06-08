package com.justremote.justremote.remote

import android.content.Context
import com.justremote.justremote.remote.models.NativeTvDevice
import com.justremote.justremote.remote.protocol.PairingProtocolClient
import com.justremote.justremote.remote.protocol.RemoteProtocolClient
import com.justremote.justremote.remote.security.PairingCredentialStore
import com.justremote.justremote.remote.security.TlsSocketFactory
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class TvRemotePlugin(context: Context) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val credentialStore = PairingCredentialStore(appContext)
    private val tlsSocketFactory = TlsSocketFactory(credentialStore)
    private val discoveryManager = TvDiscoveryManager(appContext)
    private val pairingManager = TvPairingManager(
        PairingProtocolClient(credentialStore, tlsSocketFactory)
    )
    private val commandManager = TvCommandManager(
        RemoteProtocolClient(credentialStore, tlsSocketFactory)
    )
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var channel: MethodChannel? = null

    fun register(binaryMessenger: BinaryMessenger) {
        channel = MethodChannel(binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanForTvs",
            "pairTv",
            "connectToTv",
            "disconnectTv",
            "sendCommand",
            "getConnectionStatus" -> executor.execute {
                handleRemoteMethod(call, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleRemoteMethod(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "scanForTvs" -> {
                    result.success(discoveryManager.scanForTvs().map { it.toMap() })
                }
                "pairTv" -> {
                    val args = call.argumentsMap()
                    val device = NativeTvDevice.fromArguments(args)
                    val pairingCode = args["pairingCode"] as? String ?: ""
                    result.success(pairingManager.pairTv(device, pairingCode).toMap())
                }
                "connectToTv" -> {
                    val device = NativeTvDevice.fromArguments(call.argumentsMap())
                    result.success(commandManager.connectToTv(device))
                }
                "disconnectTv" -> {
                    result.success(commandManager.disconnectTv())
                }
                "sendCommand" -> {
                    val command = call.argument<String>("command").orEmpty()
                    result.success(commandManager.sendCommand(command))
                }
                "getConnectionStatus" -> {
                    result.success(commandManager.getConnectionStatus())
                }
            }
        } catch (error: Throwable) {
            result.error("TV_REMOTE_ERROR", error.message, null)
        }
    }

    fun dispose() {
        discoveryManager.dispose()
        pairingManager.dispose()
        commandManager.dispose()
        executor.shutdownNow()
        channel?.setMethodCallHandler(null)
        channel = null
    }

    private fun MethodCall.argumentsMap(): Map<*, *> {
        return arguments as? Map<*, *> ?: emptyMap<Any, Any>()
    }

    private companion object {
        const val CHANNEL_NAME = "com.justremote.tv_remote"
    }
}
