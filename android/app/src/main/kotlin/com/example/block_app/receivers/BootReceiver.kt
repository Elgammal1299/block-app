package com.example.block_app.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.block_app.services.AppMonitorService
import com.example.block_app.services.UsageTrackingService

/**
 * BroadcastReceiver to start monitoring and tracking services on device boot
 * and when the app is restarted by the system
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "Device boot completed - starting services")
                startServices(context)
            }

            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "App updated - restarting services")
                startServices(context)
            }

            "android.intent.action.QUICKBOOT_POWERON" -> {
                // For HTC devices
                Log.d(TAG, "HTC Quick boot completed - starting services")
                startServices(context)
            }
        }
    }

    private fun startServices(context: Context) {
        try {
            // Check if services should be running based on saved preferences
            val prefs = context.getSharedPreferences("app_settings", Context.MODE_PRIVATE)
            val servicesEnabled = prefs.getBoolean("services_enabled", true)

            if (!servicesEnabled) {
                Log.d(TAG, "Services are disabled by user - not starting")
                return
            }

            // Start App Monitor Service
            val monitorIntent = Intent(context, AppMonitorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(monitorIntent)
            } else {
                context.startService(monitorIntent)
            }
            Log.d(TAG, "AppMonitorService started")

            // Start Usage Tracking Service
            val trackingIntent = Intent(context, UsageTrackingService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(trackingIntent)
            } else {
                context.startService(trackingIntent)
            }
            Log.d(TAG, "UsageTrackingService started")

            // Schedule midnight alarm for automatic daily reset
            MidnightResetReceiver.scheduleMidnightAlarm(context)
            Log.d(TAG, "Midnight alarm scheduled")

        } catch (e: Exception) {
            Log.e(TAG, "Error starting services: ${e.message}", e)
        }
    }
}
