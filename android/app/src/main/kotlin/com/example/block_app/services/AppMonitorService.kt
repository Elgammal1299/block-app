package com.example.block_app.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.block_app.MainActivity
import com.example.block_app.R
import kotlinx.coroutines.*
import org.json.JSONArray
import java.util.*

class AppMonitorService : Service() {

    companion object {
        private const val TAG = "AppMonitorService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "app_blocker_service"
        private const val PREFS_NAME = "app_blocker"
        private const val KEY_SCHEDULES = "schedules"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_MONITORING_ENABLED = "monitoring_enabled"
    }

    private val serviceScope = CoroutineScope(Dispatchers.Default + Job())
    private var monitoringJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AppMonitorService created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "AppMonitorService started")

        // Start as foreground service
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // Save monitoring state
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_MONITORING_ENABLED, true).apply()

        // Start periodic monitoring
        startMonitoring()

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

        // Cancel monitoring
        monitoringJob?.cancel()
        serviceScope.cancel()
    }

    private fun startMonitoring() {
        monitoringJob?.cancel()

        monitoringJob = serviceScope.launch {
            while (isActive) {
                try {
                    checkSchedulesAndUpdate()
                    delay(10000) // Check every 10 seconds
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop: ${e.message}")
                }
            }
        }
    }

    private fun checkSchedulesAndUpdate() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val schedulesJson = prefs.getString(KEY_SCHEDULES, null)
        val blockedAppsJson = prefs.getString(KEY_BLOCKED_APPS, null)

        if (schedulesJson == null || blockedAppsJson == null) {
            Log.d(TAG, "No schedules or blocked apps found")
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

            Log.d(TAG, "Active schedules: $activeSchedulesCount at $currentHour:$currentMinute (Day: $dayOfWeek)")

            // Update notification with current status
            updateNotification(activeSchedulesCount)

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
