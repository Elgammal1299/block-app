package com.example.block_app.services

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.block_app.MainActivity
import kotlinx.coroutines.*
import org.json.JSONObject
import java.util.*

/**
 * Foreground Service for accurate usage tracking
 * Continuously monitors app usage and stores data locally for precise statistics
 */
class UsageTrackingService : Service() {

    companion object {
        private const val TAG = "UsageTrackingService"
        private const val NOTIFICATION_ID = 1002
        private const val CHANNEL_ID = "usage_tracking_service"
        private const val PREFS_NAME = "usage_tracking"
        private const val KEY_DAILY_USAGE = "daily_usage_"
        private const val KEY_LAST_UPDATE = "last_update"
        private const val KEY_LAST_RESET_DATE = "last_reset_date"
        private const val TRACKING_INTERVAL = 10000L // 10 seconds for accurate tracking
    }

    private val serviceScope = CoroutineScope(Dispatchers.Default + Job())
    private var trackingJob: Job? = null
    private lateinit var prefs: SharedPreferences
    private lateinit var usageStatsManager: UsageStatsManager

    // Cache for tracking current session
    private val currentSessions = mutableMapOf<String, Long>() // packageName -> startTime
    private var lastCheckTime = 0L

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "UsageTrackingService created")

        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        createNotificationChannel()
        checkAndResetDailyUsage()

        // Schedule midnight alarm for automatic daily reset
        com.example.block_app.receivers.MidnightResetReceiver.scheduleMidnightAlarm(this)
        Log.d(TAG, "Midnight alarm scheduled from service")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "UsageTrackingService started")

        // Start as foreground service
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // Start tracking
        startTracking()

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "UsageTrackingService destroyed")

        // Save any ongoing sessions before stopping
        saveOngoingSessions()

        trackingJob?.cancel()
        serviceScope.cancel()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "App task removed - scheduling service restart")

        // Save ongoing sessions before restart
        saveOngoingSessions()

        // Restart the service automatically
        val restartServiceIntent = Intent(applicationContext, UsageTrackingService::class.java)
        restartServiceIntent.setPackage(packageName)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(restartServiceIntent)
        } else {
            applicationContext.startService(restartServiceIntent)
        }

        Log.d(TAG, "Service restart scheduled")
    }

    private fun startTracking() {
        trackingJob?.cancel()

        // Initialize last check time
        lastCheckTime = System.currentTimeMillis()

        trackingJob = serviceScope.launch {
            while (isActive) {
                try {
                    // Daily reset is now handled by MidnightResetReceiver
                    // No need to check on every loop
                    trackAppUsage()
                    delay(TRACKING_INTERVAL)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in tracking loop: ${e.message}", e)
                }
            }
        }
    }

    /**
     * Check if it's a new day and reset usage counters
     */
    private fun checkAndResetDailyUsage() {
        val calendar = Calendar.getInstance()
        val today = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
        val lastResetDate = prefs.getString(KEY_LAST_RESET_DATE, null)

        if (lastResetDate != null && lastResetDate != today) {
            Log.d(TAG, "New day detected. Saving yesterday's snapshot before reset.")

            // Save yesterday's data to database via Flutter before resetting
            saveYesterdaySnapshot(lastResetDate)

            // Update the reset date
            prefs.edit()
                .putString(KEY_LAST_RESET_DATE, today)
                .apply()

            Log.d(TAG, "Daily usage reset completed for new day: $today")
        } else if (lastResetDate == null) {
            // First time initialization
            prefs.edit()
                .putString(KEY_LAST_RESET_DATE, today)
                .apply()
            Log.d(TAG, "Initialized last reset date: $today")
        }
    }

    /**
     * Save yesterday's snapshot to a "pending snapshots" list
     * Flutter will read and process these when the app starts
     */
    private fun saveYesterdaySnapshot(yesterdayDate: String) {
        try {
            val storageKey = KEY_DAILY_USAGE + yesterdayDate
            val dataJson = prefs.getString(storageKey, "{}")

            if (dataJson.isNullOrEmpty() || dataJson == "{}") {
                Log.d(TAG, "No data to save for $yesterdayDate")
                return
            }

            // Mark this date as needing a snapshot save
            // Flutter will pick this up and process it
            val pendingSnapshots = prefs.getStringSet("pending_snapshots", mutableSetOf()) ?: mutableSetOf()
            val updatedSet = pendingSnapshots.toMutableSet()
            updatedSet.add(yesterdayDate)

            prefs.edit()
                .putStringSet("pending_snapshots", updatedSet)
                .apply()

            Log.d(TAG, "Marked $yesterdayDate for snapshot save (will be processed by Flutter)")

        } catch (e: Exception) {
            Log.e(TAG, "Error marking yesterday's snapshot: ${e.message}", e)
        }
    }

    /**
     * Track app usage using UsageEvents for high accuracy
     */
    private fun trackAppUsage() {
        try {
            val currentTime = System.currentTimeMillis()

            // Query usage events since last check
            val events = usageStatsManager.queryEvents(lastCheckTime, currentTime)

            if (events == null) {
                Log.w(TAG, "Usage events query returned null")
                lastCheckTime = currentTime
                return
            }

            var eventsCount = 0
            while (events.hasNextEvent()) {
                val event = UsageEvents.Event()
                events.getNextEvent(event)

                val packageName = event.packageName
                val timestamp = event.timeStamp

                // Skip system packages
                if (isSystemPackage(packageName)) {
                    continue
                }

                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND,
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        // App opened/resumed
                        currentSessions[packageName] = timestamp
                        Log.v(TAG, "App opened: $packageName at $timestamp")
                        eventsCount++
                    }

                    UsageEvents.Event.MOVE_TO_BACKGROUND,
                    UsageEvents.Event.ACTIVITY_PAUSED,
                    UsageEvents.Event.ACTIVITY_STOPPED -> {
                        // App closed/paused - save usage duration
                        val startTime = currentSessions[packageName]
                        if (startTime != null) {
                            val duration = timestamp - startTime
                            if (duration > 0) {
                                saveUsageDuration(packageName, duration, startTime)
                                Log.v(TAG, "App closed: $packageName, duration: ${duration}ms")
                            }
                            currentSessions.remove(packageName)
                        }
                        eventsCount++
                    }
                }
            }

            // SAFETY NET: Handle missed MOVE_TO_BACKGROUND events
            // Check for stale sessions (open > 10 seconds without close event)
            applySafetyNetForStaleSessions(currentTime)

            Log.d(TAG, "Processed $eventsCount usage events")
            lastCheckTime = currentTime

        } catch (e: Exception) {
            Log.e(TAG, "Error tracking app usage: ${e.message}", e)
        }
    }

    /**
     * Safety net for missed MOVE_TO_BACKGROUND events
     * Clamps duration for sessions that have been open too long without a close event
     */
    private fun applySafetyNetForStaleSessions(currentTime: Long) {
        val maxSessionDuration = TRACKING_INTERVAL + 5000L // 15 seconds (10s interval + 5s buffer)

        val staleSessions = currentSessions.filter { (_, startTime) ->
            (currentTime - startTime) > maxSessionDuration
        }

        if (staleSessions.isNotEmpty()) {
            Log.w(TAG, "Found ${staleSessions.size} stale sessions (likely missed MOVE_TO_BACKGROUND events)")

            for ((packageName, startTime) in staleSessions) {
                // Clamp duration to max interval to avoid inflated numbers
                val clampedDuration = maxSessionDuration
                saveUsageDuration(packageName, clampedDuration, startTime)

                Log.w(TAG, "Applied safety net: $packageName (clamped to ${clampedDuration}ms)")

                // Update session start time to now for next check
                currentSessions[packageName] = currentTime
            }
        }
    }

    /**
     * Save usage duration for an app
     * Handles cross-day sessions (e.g., 11:59 PM - 12:05 AM)
     */
    private fun saveUsageDuration(packageName: String, durationMillis: Long, sessionStart: Long) {
        try {
            val sessionEnd = sessionStart + durationMillis

            val startCal = Calendar.getInstance()
            startCal.timeInMillis = sessionStart

            val endCal = Calendar.getInstance()
            endCal.timeInMillis = sessionEnd

            val startDate = "${startCal.get(Calendar.YEAR)}-${startCal.get(Calendar.MONTH) + 1}-${startCal.get(Calendar.DAY_OF_MONTH)}"
            val endDate = "${endCal.get(Calendar.YEAR)}-${endCal.get(Calendar.MONTH) + 1}-${endCal.get(Calendar.DAY_OF_MONTH)}"

            // Check if session spans midnight (crosses days)
            if (startDate != endDate) {
                // Split usage across days
                Log.d(TAG, "Cross-day session detected: $packageName from $startDate to $endDate")

                // Calculate midnight boundary
                val midnightCal = Calendar.getInstance()
                midnightCal.timeInMillis = sessionStart
                midnightCal.set(Calendar.HOUR_OF_DAY, 23)
                midnightCal.set(Calendar.MINUTE, 59)
                midnightCal.set(Calendar.SECOND, 59)
                midnightCal.set(Calendar.MILLISECOND, 999)
                val midnight = midnightCal.timeInMillis

                // Duration for first day (until 23:59:59.999)
                val durationDay1 = midnight - sessionStart
                // Duration for second day (from 00:00:00.000)
                val durationDay2 = sessionEnd - (midnight + 1)

                if (durationDay1 > 0) {
                    saveUsageForDate(packageName, durationDay1, startDate)
                    Log.v(TAG, "Split: $packageName ${durationDay1}ms to $startDate")
                }

                if (durationDay2 > 0) {
                    saveUsageForDate(packageName, durationDay2, endDate)
                    Log.v(TAG, "Split: $packageName ${durationDay2}ms to $endDate")
                }

            } else {
                // Normal case: same day
                saveUsageForDate(packageName, durationMillis, startDate)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error saving usage duration: ${e.message}", e)
        }
    }

    /**
     * Save usage for a specific date
     */
    private fun saveUsageForDate(packageName: String, durationMillis: Long, dateKey: String) {
        try {
            val storageKey = KEY_DAILY_USAGE + dateKey

            // Get existing usage data for this date
            val existingDataJson = prefs.getString(storageKey, "{}")
            val usageData = JSONObject(existingDataJson ?: "{}")

            // Add/update this app's usage
            val currentUsage = usageData.optLong(packageName, 0L)
            usageData.put(packageName, currentUsage + durationMillis)

            // Save back to preferences
            prefs.edit()
                .putString(storageKey, usageData.toString())
                .putLong(KEY_LAST_UPDATE, System.currentTimeMillis())
                .apply()

            Log.v(TAG, "Saved usage: $packageName +${durationMillis}ms for $dateKey")

        } catch (e: Exception) {
            Log.e(TAG, "Error saving usage for date: ${e.message}", e)
        }
    }

    /**
     * Save ongoing sessions before service stops
     */
    private fun saveOngoingSessions() {
        val currentTime = System.currentTimeMillis()
        for ((packageName, startTime) in currentSessions) {
            val duration = currentTime - startTime
            if (duration > 0) {
                saveUsageDuration(packageName, duration, startTime)
            }
        }
        currentSessions.clear()
    }

    /**
     * Check if package is a system app or our own app
     */
    private fun isSystemPackage(packageName: String): Boolean {
        val systemPackages = setOf(
            "android",
            "com.android.systemui",
            "com.android.settings",
            "com.android.launcher",
            "com.android.launcher3",
            "com.google.android.gms",
            "com.google.android.gsf",
            "com.example.block_app" // Don't track our own app
        )

        return systemPackages.contains(packageName) ||
               packageName.startsWith("com.android.") ||
               packageName.startsWith("com.google.android.") ||
               packageName.contains("launcher")
    }

    /**
     * Get usage data for a specific date
     */
    fun getUsageForDate(date: String): Map<String, Long> {
        val storageKey = KEY_DAILY_USAGE + date
        val dataJson = prefs.getString(storageKey, "{}")

        return try {
            val jsonObject = JSONObject(dataJson ?: "{}")
            val result = mutableMapOf<String, Long>()

            jsonObject.keys().forEach { key ->
                result[key] = jsonObject.getLong(key)
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing usage data: ${e.message}")
            emptyMap()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Usage Tracking Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks app usage for accurate statistics"
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
            .setContentTitle("تتبع الاستخدام نشط")
            .setContentText("جاري تتبع استخدام التطبيقات للحصول على إحصائيات دقيقة")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
