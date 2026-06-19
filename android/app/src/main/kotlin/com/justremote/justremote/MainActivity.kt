package com.justremote.justremote

import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.justremote.justremote.remote.DiscoveryPermissionPolicy
import com.justremote.justremote.remote.DiscoveryPermissionRequester
import com.justremote.justremote.remote.TvRemotePlugin
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity(), DiscoveryPermissionRequester {
    private var tvRemotePlugin: TvRemotePlugin? = null
    @Volatile
    private var pendingDiscoveryPermissionLatch: CountDownLatch? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        tvRemotePlugin = TvRemotePlugin(this, this)
        tvRemotePlugin?.register(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        tvRemotePlugin?.dispose()
        tvRemotePlugin = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun ensureDiscoveryPermissionsGranted(): Boolean {
        val missing = missingDiscoveryPermissions()
        if (missing.isEmpty()) return true

        Log.d(TAG, "Requesting discovery permissions: $missing")
        val latch = CountDownLatch(1)
        pendingDiscoveryPermissionLatch = latch

        runOnUiThread {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), PERMISSION_REQUEST_CODE)
        }

        val completed = latch.await(PERMISSION_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        if (!completed) {
            Log.w(TAG, "Timed out waiting for discovery permissions")
            pendingDiscoveryPermissionLatch = null
            return false
        }

        val granted = missingDiscoveryPermissions().isEmpty()
        Log.d(TAG, "Discovery permissions granted=$granted")
        return granted
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            permissions.forEachIndexed { index, permission ->
                val granted = grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED
                Log.d(TAG, "Permission result $permission granted=$granted")
            }
            pendingDiscoveryPermissionLatch?.countDown()
            pendingDiscoveryPermissionLatch = null
        }
    }

    private fun missingDiscoveryPermissions(): List<String> {
        return DiscoveryPermissionPolicy.missingPermissions(
            sdkInt = Build.VERSION.SDK_INT,
            isGranted = ::isGranted
        ).filter { isPermissionDefined(it) }
    }

    private fun isPermissionDefined(permission: String): Boolean {
        return try {
            packageManager.getPermissionInfo(permission, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun isGranted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val action = event.action
        val keyCode = event.keyCode
        if (action == KeyEvent.ACTION_DOWN) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    val handled = tvRemotePlugin?.handleVolumeKey("volumeUp") ?: false
                    if (handled) return true
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    val handled = tvRemotePlugin?.handleVolumeKey("volumeDown") ?: false
                    if (handled) return true
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private companion object {
        const val TAG = "MainActivity"
        const val PERMISSION_REQUEST_CODE = 1001
        const val PERMISSION_TIMEOUT_SECONDS = 60L
    }
}
