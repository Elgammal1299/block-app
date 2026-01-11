package com.example.block_app.services

import android.app.*
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.block_app.MainActivity
import com.example.block_app.R
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

class AppMonitorService : Service() {

    companion object {
        private const val TAG = "AppMonitorService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "app_blocker_service"
        private const val PREFS_NAME = "app_blocker"
        private const val KEY_SCHEDULES = "schedules"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_USAGE_LIMITS = "usage_limits"
        private const val KEY_MONITORING_ENABLED = "monitoring_enabled"
        private const val KEY_DAILY_USAGE = "daily_usage"
        private const val KEY_LAST_RESET_DATE = "last_reset_date"
    }

    private var lastActiveSchedulesLog = -1

    // ✨ ARCHITECTURE: No more while(true) loops or timers!
    // We use a BroadcastReceiver to listen for system TIME_TICK (fires exactly once per minute).
    private val timeTickReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == Intent.ACTION_TIME_TICK) {
                // Determine if we need to do heavy checks
                // Accessibility Service handles real-time blocking.
                // We only handle schedule notification updates and daily resets here.
                checkDailyReset()
                checkSchedulesAndUpdate()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AppMonitorService created")
        createNotificationChannel()
        
        // Register receiver for minute updates
        val filter = android.content.IntentFilter(Intent.ACTION_TIME_TICK)
        registerReceiver(timeTickReceiver, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "AppMonitorService started")

        // Start as foreground service
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // Save monitoring state
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_MONITORING_ENABLED, true).apply()
        
        // Initial check
        checkDailyReset()
        checkSchedulesAndUpdate()

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AppMonitorService destroyed")

        // Save monitoring state
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_MONITORING_ENABLED, false).apply()

        // Unregister receiver
        try {
            unregisterReceiver(timeTickReceiver)
        } catch (e: Exception) {
            // Ignore if not registered
        }
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "App task removed - scheduling service restart")

        // Restart the service automatically
        val restartServiceIntent = Intent(applicationContext, AppMonitorService::class.java)
        restartServiceIntent.setPackage(packageName)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(restartServiceIntent)
        } else {
            applicationContext.startService(restartServiceIntent)
        }

        Log.d(TAG, "Service restart scheduled")
    }

    private fun checkDailyReset() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastResetDate = prefs.getString(KEY_LAST_RESET_DATE, null)
        val today = Calendar.getInstance().get(Calendar.DAY_OF_YEAR).toString() +
                    Calendar.getInstance().get(Calendar.YEAR).toString()

        if (lastResetDate != today) {
            // New day - reset all usage counters
            prefs.edit()
                .putString(KEY_DAILY_USAGE, "{}")
                .putString(KEY_LAST_RESET_DATE, today)
                .apply()
            Log.d(TAG, "Daily usage reset for new day")
        }
    }

    private fun checkSchedulesAndUpdate() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val schedulesJson = prefs.getString(KEY_SCHEDULES, null)
        val blockedAppsJson = prefs.getString(KEY_BLOCKED_APPS, null)

        if (schedulesJson == null || blockedAppsJson == null) {
            return
        }

        try {
            val schedulesArray = JSONArray(schedulesJson)
            val calendar = Calendar.getInstance()
            val currentDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
            val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
            val currentMinute = calendar.get(Calendar.MINUTE)
            val currentMinutes = currentHour * 60 + currentMinute

            // Convert Calendar.DAY_OF_WEEK to our format (1=Monday, 7=Sunday)
            val dayOfWeek = when (currentDayOfWeek) {
                Calendar.SUNDAY -> 7
                Calendar.MONDAY -> 1
                Calendar.TUESDAY -> 2
                Calendar.WEDNESDAY -> 3
                Calendar.THURSDAY -> 4
                Calendar.FRIDAY -> 5
                Calendar.SATURDAY -> 6
                else -> 1
            }

            var activeSchedulesCount = 0

            // Check each schedule
            for (i in 0 until schedulesArray.length()) {
                val schedule = schedulesArray.getJSONObject(i)

                if (!schedule.getBoolean("isEnabled")) {
                    continue
                }

                // Check if today is in the schedule's days
                val daysOfWeek = schedule.getJSONArray("daysOfWeek")
                var isDayMatch = false
                for (k in 0 until daysOfWeek.length()) {
                    if (daysOfWeek.getInt(k) == dayOfWeek) {
                        isDayMatch = true
                        break
                    }
                }

                if (isDayMatch) {
                    // Parse start and end times
                    val startTime = schedule.getJSONObject("startTime")
                    val endTime = schedule.getJSONObject("endTime")
                    val startMinutes = startTime.getInt("hour") * 60 + startTime.getInt("minute")
                    val endMinutes = endTime.getInt("hour") * 60 + endTime.getInt("minute")

                    // Check if current time is within this schedule
                    val isWithinTime = if (endMinutes < startMinutes) {
                        // Schedule crosses midnight
                        currentMinutes >= startMinutes || currentMinutes < endMinutes
                    } else {
                        currentMinutes >= startMinutes && currentMinutes < endMinutes
                    }

                    if (isWithinTime) {
                        activeSchedulesCount++
                    }
                }
            }

            // ✨ LOGGING OPTIMIZATION: Only log if status changed
            if (activeSchedulesCount != lastActiveSchedulesLog) {
                 Log.d(TAG, "Active schedules changed: $activeSchedulesCount")
                 lastActiveSchedulesLog = activeSchedulesCount
                 updateNotification(activeSchedulesCount)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error checking schedules: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Blocker Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors app blocking schedules"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("App Blocker Active")
            .setContentText("Monitoring app blocking schedules")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(activeSchedules: Int) {
        val notification = if (activeSchedules > 0) {
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("App Blocker Active")
                .setContentText("$activeSchedules schedule(s) active - Apps are blocked")
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        } else {
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("App Blocker Active")
                .setContentText("No active schedules - Apps are accessible")
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        }

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
