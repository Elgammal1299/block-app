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
        private const val KEY_USAGE_LIMITS = "usage_limits"
        private const val KEY_MONITORING_ENABLED = "monitoring_enabled"
        private const val KEY_DAILY_USAGE = "daily_usage"
        private const val KEY_LAST_RESET_DATE = "last_reset_date"
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
                    checkDailyReset()
                    checkCurrentAppUsageLimit()  // Check current app first (more important)
                    checkUsageLimits()
                    checkSchedulesAndUpdate()
                    delay(3000) // Check every 3 seconds for faster response
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop: ${e.message}")
                }
            }
        }
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

    private fun checkUsageLimits() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val usageLimitsJson = prefs.getString(KEY_USAGE_LIMITS, null) ?: return

        try {
            val limitsArray = JSONArray(usageLimitsJson)
            if (limitsArray.length() == 0) return

            // Get current app usage using UsageStatsManager
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val stats = usageStatsManager.queryUsageStats(
                android.app.usage.UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            // Create a map of package -> total time in minutes
            val usageMap = mutableMapOf<String, Int>()
            stats?.forEach { stat ->
                val totalTimeMinutes = (stat.totalTimeInForeground / 1000 / 60).toInt()
                usageMap[stat.packageName] = totalTimeMinutes
            }

            // Check each limit
            for (i in 0 until limitsArray.length()) {
                val limit = limitsArray.getJSONObject(i)
                val packageName = limit.getString("packageName")
                val dailyLimitMinutes = limit.getInt("dailyLimitMinutes")
                val isEnabled = limit.optBoolean("isEnabled", true)

                if (!isEnabled) continue

                val usedMinutes = usageMap[packageName] ?: 0

                // If limit is reached, just log it
                // The actual blocking is handled by the accessibility service
                if (usedMinutes >= dailyLimitMinutes) {
                    Log.d(TAG, "Usage limit reached for $packageName: $usedMinutes/$dailyLimitMinutes minutes")
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error checking usage limits: ${e.message}")
        }
    }

    private fun checkCurrentAppUsageLimit() {
        try {
            // Get the currently running foreground app
            val currentPackage = getForegroundApp() ?: return

            // Don't block our own app or launcher
            if (currentPackage == packageName || currentPackage.contains("launcher")) {
                return
            }

            // Check if this app has reached its usage limit
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val usageLimitsJson = prefs.getString(KEY_USAGE_LIMITS, null) ?: return

            val limitsArray = JSONArray(usageLimitsJson)
            for (i in 0 until limitsArray.length()) {
                val limit = limitsArray.getJSONObject(i)
                if (limit.getString("packageName") == currentPackage) {
                    val isEnabled = limit.optBoolean("isEnabled", true)
                    if (!isEnabled) continue

                    val dailyLimitMinutes = limit.getInt("dailyLimitMinutes")

                    // Get current app usage using UsageStatsManager
                    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                    if (usageStatsManager == null) {
                        Log.e(TAG, "UsageStatsManager is null")
                        return
                    }

                    // Get total usage for today
                    val calendar = Calendar.getInstance()
                    calendar.set(Calendar.HOUR_OF_DAY, 0)
                    calendar.set(Calendar.MINUTE, 0)
                    calendar.set(Calendar.SECOND, 0)
                    calendar.set(Calendar.MILLISECOND, 0)
                    val startOfDay = calendar.timeInMillis
                    val currentTime = System.currentTimeMillis()

                    val todayStats = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        startOfDay,
                        currentTime
                    )

                    val appStat = todayStats?.find { it.packageName == currentPackage }
                    val usedMinutes = if (appStat != null) {
                        (appStat.totalTimeInForeground / 1000 / 60).toInt()
                    } else {
                        0
                    }

                    Log.d(TAG, "Checking current app: $currentPackage - Used: $usedMinutes/$dailyLimitMinutes minutes")

                    // If limit is reached, show block overlay and go home
                    if (usedMinutes >= dailyLimitMinutes) {
                        Log.d(TAG, "⚠️ LIMIT REACHED! Showing block screen for $currentPackage - $usedMinutes/$dailyLimitMinutes minutes")

                        // Launch block overlay activity
                        val overlayIntent = Intent(this, com.example.block_app.ui.BlockOverlayActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                            putExtra("blocked_package", currentPackage)
                            putExtra("block_reason", "usage_limit_reached")
                        }
                        startActivity(overlayIntent)

                        // Force the user to go to home screen to close the blocked app
                        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(homeIntent)
                    }

                    // Only check the first matching limit
                    break
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking current app usage limit: ${e.message}", e)
        }
    }

    private fun getForegroundApp(): String? {
        return try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageStatsManager == null) {
                Log.e(TAG, "UsageStatsManager is null")
                return null
            }

            val currentTime = System.currentTimeMillis()
            // Query usage stats for the last 2 seconds
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                currentTime - 2000,
                currentTime
            )

            if (stats == null || stats.isEmpty()) {
                return null
            }

            // Get the app with the most recent timestamp
            val currentApp = stats.maxByOrNull { it.lastTimeUsed }
            currentApp?.packageName
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app: ${e.message}", e)
            null
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
