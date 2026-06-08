package com.justremote.justremote

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.justremote.justremote.remote.TvRemotePlugin

class MainActivity : FlutterActivity() {
    private var tvRemotePlugin: TvRemotePlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        tvRemotePlugin = TvRemotePlugin(this)
        tvRemotePlugin?.register(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        tvRemotePlugin?.dispose()
        tvRemotePlugin = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
