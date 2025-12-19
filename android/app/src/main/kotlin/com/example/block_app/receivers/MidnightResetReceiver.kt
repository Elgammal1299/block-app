package com.example.block_app.receivers

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.example.block_app.services.UsageTrackingService
import java.util.*

/**
 * BroadcastReceiver that triggers at midnight (12:00 AM) every day
 * Handles day transition WITHOUT requiring Flutter to be running
 */
class MidnightResetReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "MidnightResetReceiver"
        private const val ACTION_MIDNIGHT_RESET = "com.example.block_app.ACTION_MIDNIGHT_RESET"

        /**
         * Schedule the next midnight alarm
         * This is called from:
         * 1. BootReceiver (after device boot)
         * 2. MidnightResetReceiver itself (after each midnight trigger)
         * 3. UsageTrackingService (when service starts)
         */
        fun scheduleMidnightAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, MidnightResetReceiver::class.java).apply {
                action = ACTION_MIDNIGHT_RESET
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Calculate next midnight
            val calendar = Calendar.getInstance().apply {
                timeInMillis = System.currentTimeMillis()
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                add(Calendar.DAY_OF_MONTH, 1) // Next midnight
            }

            val nextMidnight = calendar.timeInMillis

            Log.d(TAG, "Scheduling midnight alarm for: ${calendar.time}")

            // Use setExactAndAllowWhileIdle for accurate midnight trigger even in Doze mode
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    nextMidnight,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    nextMidnight,
                    pendingIntent
                )
            }

            Log.d(TAG, "Midnight alarm scheduled successfully")
        }

        /**
         * Cancel the midnight alarm
         */
        fun cancelMidnightAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, MidnightResetReceiver::class.java).apply {
                action = ACTION_MIDNIGHT_RESET
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            alarmManager.cancel(pendingIntent)
            Log.d(TAG, "Midnight alarm cancelled")
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_MIDNIGHT_RESET) {
            Log.d(TAG, "🌙 Midnight reset triggered - New day started!")

            // Finalize yesterday's data
            finalizeYesterday(context)

            // Initialize new day
            initializeNewDay(context)

            // Ensure UsageTrackingService is running
            ensureTrackingServiceRunning(context)

            // Schedule next midnight alarm
            scheduleMidnightAlarm(context)

            Log.d(TAG, "✅ Midnight reset completed successfully")
        }
    }

    /**
     * Finalize yesterday's data
     * Save snapshot and mark for Flutter processing
     */
    private fun finalizeYesterday(context: Context) {
        try {
            val prefs = context.getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)

            // Get yesterday's date
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.DAY_OF_MONTH, -1)
            val yesterdayDate = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"

            // Check if yesterday has data
            val storageKey = "daily_usage_$yesterdayDate"
            val dataJson = prefs.getString(storageKey, "{}")

            if (!dataJson.isNullOrEmpty() && dataJson != "{}") {
                // Mark yesterday for snapshot processing by Flutter
                val pendingSnapshots = prefs.getStringSet("pending_snapshots", mutableSetOf()) ?: mutableSetOf()
                val updatedSet = pendingSnapshots.toMutableSet()
                updatedSet.add(yesterdayDate)

                prefs.edit()
                    .putStringSet("pending_snapshots", updatedSet)
                    .apply()

                Log.d(TAG, "✅ Yesterday ($yesterdayDate) finalized and marked for processing")
            } else {
                Log.d(TAG, "⚠️ No data for yesterday ($yesterdayDate)")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error finalizing yesterday: ${e.message}", e)
        }
    }

    /**
     * Initialize new day
     * Update last reset date to today
     */
    private fun initializeNewDay(context: Context) {
        try {
            val prefs = context.getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val calendar = Calendar.getInstance()
            val today = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"

            prefs.edit()
                .putString("last_reset_date", today)
                .apply()

            Log.d(TAG, "✅ New day initialized: $today")

        } catch (e: Exception) {
            Log.e(TAG, "Error initializing new day: ${e.message}", e)
        }
    }

    /**
     * Ensure UsageTrackingService is running
     */
    private fun ensureTrackingServiceRunning(context: Context) {
        try {
            val intent = Intent(context, UsageTrackingService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "✅ UsageTrackingService ensured running")
        } catch (e: Exception) {
            Log.e(TAG, "Error ensuring tracking service: ${e.message}", e)
        }
    }
}
