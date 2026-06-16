package com.justremote.justremote.remote

import android.content.Context
import android.util.Log
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

class TvRemotePlugin(
    context: Context,
    discoveryPermissionRequester: DiscoveryPermissionRequester? = null
) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val credentialStore = PairingCredentialStore(appContext)
    private val tlsSocketFactory = TlsSocketFactory(credentialStore)
    private val discoveryManager = TvDiscoveryManager(appContext, discoveryPermissionRequester)
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
        Log.d(TAG, "MethodChannel call received: ${call.method}")
        when (call.method) {
            "scanForTvs",
            "pairTv",
            "connectToTv",
            "disconnectTv",
            "sendCommand",
            "sendText",
            "launchApp",
            "forgetTv",
            "resetPairingData",
            "getConnectionStatus",
            "getDiagnostics" -> executor.execute {
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
                "forgetTv" -> {
                    val device = NativeTvDevice.fromArguments(call.argumentsMap())
                    commandManager.disconnectTv()
                    result.success(pairingManager.forgetTv(device).toMap())
                }
                "resetPairingData" -> {
                    commandManager.disconnectTv()
                    result.success(pairingManager.resetPairingData().toMap())
                }
                "sendCommand" -> {
                    val command = call.argument<String>("command").orEmpty()
                    result.success(commandManager.sendCommand(command))
                }
                "sendText" -> {
                    val text = call.argument<String>("text").orEmpty()
                    result.success(commandManager.sendText(text))
                }
                "launchApp" -> {
                    val appLink = call.argument<String>("appLink").orEmpty()
                    result.success(commandManager.launchApp(appLink))
                }
                "getConnectionStatus" -> {
                    result.success(commandManager.getConnectionStatus())
                }
                "getDiagnostics" -> {
                    result.success(NativeRemoteDiagnostics.snapshot())
                }
            }
        } catch (error: Throwable) {
            Log.w(TAG, "MethodChannel call failed: ${call.method}", error)
            result.success(call.failureResponse(error.cleanMessage("Operation failed")))
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

    private fun MethodCall.failureResponse(message: String): Any {
        return when (method) {
            "scanForTvs" -> emptyList<Map<String, Any>>()
            "pairTv",
            "connectToTv",
            "disconnectTv",
            "forgetTv",
            "resetPairingData" -> mapOf("success" to false, "message" to message)
            "sendCommand",
            "sendText",
            "launchApp" -> mapOf("success" to false, "message" to message)
            "getConnectionStatus" -> mapOf("connected" to false, "deviceName" to null)
            "getDiagnostics" -> mapOf(
                "connected" to false,
                "deviceName" to null,
                "lastError" to message,
                "events" to emptyList<String>()
            )
            else -> mapOf("success" to false, "message" to message)
        }
    }

    private fun Throwable.cleanMessage(fallback: String): String {
        return message?.takeIf { it.isNotBlank() } ?: fallback
    }

    private companion object {
        const val TAG = "TvRemotePlugin"
        const val CHANNEL_NAME = "com.justremote.tv_remote"
    }
}
