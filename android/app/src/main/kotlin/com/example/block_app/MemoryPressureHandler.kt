package com.example.block_app

import android.content.ComponentCallbacks2
import android.content.res.Configuration
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Phase 3.5+: Memory Pressure Handler
 *
 * يستمع لـ onTrimMemory callback من Android
 * وينبه Dart لتنظيف الـ caches
 *
 * Levels:
 * - TRIM_MEMORY_RUNNING_MODERATE (0)
 * - TRIM_MEMORY_RUNNING_LOW (5)
 * - TRIM_MEMORY_RUNNING_CRITICAL (10)
 * - TRIM_MEMORY_UI_HIDDEN (15)
 */
class MemoryPressureHandler(
    private val flutterEngine: FlutterEngine,
) : ComponentCallbacks2 {

    companion object {
        private const val CHANNEL = "com.example.block_app/memory_pressure"
    }

    private val channel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        CHANNEL,
    )

    /**
     * Register this handler for memory callbacks
     * Call this in MainActivity or app initialization
     */
    fun register(context: android.content.Context) {
        context.registerComponentCallbacks(this)
        Log.i("MemoryPressureHandler", "Registered for memory callbacks")
    }

    /**
     * Unregister when app is destroyed
     */
    fun unregister(context: android.content.Context) {
        context.unregisterComponentCallbacks(this)
        Log.i("MemoryPressureHandler", "Unregistered from memory callbacks")
    }

    override fun onTrimMemory(level: Int) {
        Log.w("MemoryPressureHandler", "Memory pressure: level=$level")

        // Convert level to human-readable format
        val levelName = when (level) {
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE -> "RUNNING_MODERATE"
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW -> "RUNNING_LOW"
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL -> "RUNNING_CRITICAL"
            ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN -> "UI_HIDDEN"
            else -> "UNKNOWN"
        }

        Log.w("MemoryPressureHandler", "Level: $levelName")

        // Send to Dart
        channel.invokeMethod(
            "onTrimMemory",
            mapOf("level" to level),
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d("MemoryPressureHandler", "Memory trim acknowledged by Dart")
                }
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e("MemoryPressureHandler", "Error: $errorMessage")
                }
                override fun notImplemented() {
                    Log.e("MemoryPressureHandler", "Method not implemented")
                }
            }
        )
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        // Not used
    }

    override fun onLowMemory() {
        // Legacy callback - also signal Dart
        Log.e("MemoryPressureHandler", "onLowMemory called!")

        channel.invokeMethod(
            "onTrimMemory",
            mapOf("level" to 100), // Custom level for critical
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d("MemoryPressureHandler", "Low memory acknowledged by Dart")
                }
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e("MemoryPressureHandler", "Error: $errorMessage")
                }
                override fun notImplemented() {
                    Log.e("MemoryPressureHandler", "Method not implemented")
                }
            }
        )
    }
}
