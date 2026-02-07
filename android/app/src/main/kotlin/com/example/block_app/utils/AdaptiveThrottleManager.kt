package com.example.block_app.utils

import android.util.Log

/**
 * Phase 3 Optimization: Adaptive Accessibility Throttling
 * 
 * Dynamically adjusts event throttling based on device performance:
 * - Excellent FPS (55+): 500ms throttle → responsive blocking
 * - Good FPS (45-55): 800ms throttle → balanced performance
 * - Poor FPS (<45): 1200ms throttle → conservative to avoid jank
 * - Memory pressure: 1200ms throttle → protect from OOM
 */
object AdaptiveThrottleManager {
    private const val TAG = "AdaptiveThrottle"

    // Performance thresholds
    private const val EXCELLENT_FPS_THRESHOLD = 55.0
    private const val GOOD_FPS_THRESHOLD = 45.0
    private const val POOR_FPS_THRESHOLD = 35.0

    // Throttle values (in milliseconds)
    private const val THROTTLE_EXCELLENT = 500L
    private const val THROTTLE_GOOD = 800L
    private const val THROTTLE_POOR = 1200L

    // Performance metrics
    private var currentFps = 60.0
    private var frameCount = 0
    private var lastFpsCheckTime = System.currentTimeMillis()
    private var isMemoryPressure = false

    /**
     * Update FPS metrics
     * Call this after frame rendering
     */
    fun recordFrame() {
        frameCount++
        val now = System.currentTimeMillis()
        val elapsed = now - lastFpsCheckTime

        // Update FPS every 1 second
        if (elapsed >= 1000) {
            currentFps = (frameCount / (elapsed / 1000.0)).coerceIn(0.0, 120.0)
            frameCount = 0
            lastFpsCheckTime = now
        }
    }

    /**
     * Get adaptive throttle duration based on performance
     */
    fun getAdaptiveThrottleDuration(): Long {
        if (isMemoryPressure) {
            Log.d(TAG, "Memory pressure detected, using conservative throttle: ${THROTTLE_POOR}ms")
            return THROTTLE_POOR
        }

        return when {
            currentFps >= EXCELLENT_FPS_THRESHOLD -> {
                Log.d(TAG, "Excellent FPS ($currentFps), using responsive throttle: ${THROTTLE_EXCELLENT}ms")
                THROTTLE_EXCELLENT
            }
            currentFps >= GOOD_FPS_THRESHOLD -> {
                Log.d(TAG, "Good FPS ($currentFps), using balanced throttle: ${THROTTLE_GOOD}ms")
                THROTTLE_GOOD
            }
            else -> {
                Log.d(TAG, "Poor FPS ($currentFps), using conservative throttle: ${THROTTLE_POOR}ms")
                THROTTLE_POOR
            }
        }
    }

    /**
     * Check memory usage and update pressure status
     */
    fun checkMemoryPressure(totalMemoryMb: Long, usedMemoryMb: Long) {
        val pressureThreshold = (totalMemoryMb * 0.85).toLong()
        val newPressureStatus = usedMemoryMb > pressureThreshold

        if (newPressureStatus != isMemoryPressure) {
            isMemoryPressure = newPressureStatus
            Log.d(
                TAG,
                "Memory pressure ${if (isMemoryPressure) "ENABLED" else "DISABLED"} " +
                        "($usedMemoryMb MB / $totalMemoryMb MB)"
            )
        }
    }

    /**
     * Get performance level description
     */
    fun getPerformanceLevel(): String {
        return when {
            currentFps >= EXCELLENT_FPS_THRESHOLD -> "Excellent (${String.format("%.1f", currentFps)} FPS)"
            currentFps >= GOOD_FPS_THRESHOLD -> "Good (${String.format("%.1f", currentFps)} FPS)"
            currentFps >= POOR_FPS_THRESHOLD -> "Fair (${String.format("%.1f", currentFps)} FPS)"
            else -> "Poor (${String.format("%.1f", currentFps)} FPS)"
        }
    }

    /**
     * Reset metrics (call on app resume)
     */
    fun reset() {
        currentFps = 60.0
        frameCount = 0
        lastFpsCheckTime = System.currentTimeMillis()
        Log.d(TAG, "Metrics reset")
    }
}
