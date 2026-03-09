package com.ahmedelgammal.appblock

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ahmedelgammal.appblock.channels.AppBlockerChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ahmedelgammal.appblock/app_blocker"
    private lateinit var appBlockerChannel: AppBlockerChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        appBlockerChannel = AppBlockerChannel(this, channel)
        appBlockerChannel.setupMethodChannel()
    }
}
