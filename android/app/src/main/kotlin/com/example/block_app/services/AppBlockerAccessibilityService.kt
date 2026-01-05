package com.example.block_app.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.block_app.ui.BlockOverlayActivity
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerAccessibility"
        private const val PREFS_NAME = "app_blocker"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_SCHEDULES = "schedules"
        private const val KEY_USAGE_LIMITS = "usage_limits"
        private const val KEY_TEMP_UNLOCK = "temp_unlock_until"
        private const val KEY_FOCUS_SESSION_PACKAGES = "focus_session_packages"
        private const val KEY_FOCUS_SESSION_END = "focus_session_end_time"

        // Method to set temporary unlock (called from BlockOverlayActivity)
        fun setTemporaryUnlock(context: Context, durationMinutes: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val unlockUntil = System.currentTimeMillis() + (durationMinutes * 60 * 1000)
            prefs.edit().putLong(KEY_TEMP_UNLOCK, unlockUntil).apply()
            Log.d(TAG, "Temporary unlock set for $durationMinutes minutes")
        }
    }

    private var currentSessionPackage: String? = null
    private var sessionStartTime: Long = 0
    private var screenOffReceiver: android.content.BroadcastReceiver? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility Service Connected - Usage Tracking Enabled")

        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        info.notificationTimeout = 100
        serviceInfo = info

        // Register receiver for screen events to handle session closing
        registerScreenReceiver()
        
        // Notify UsageTrackingService to yield/pause (optional optimization)
        disableLegacyTracking()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        unregisterScreenReceiver()
        // Close any open session
        endCurrentSession()
        // Re-enable legacy tracking service as fallback
        enableLegacyTracking()
    }

    private fun registerScreenReceiver() {
        val filter = android.content.IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        
        screenOffReceiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        Log.d(TAG, "Screen OFF - Finding and closing active session")
                        endCurrentSession()
                    }
                    Intent.ACTION_USER_PRESENT, Intent.ACTION_SCREEN_ON -> {
                        // We wait for the next WINDOW_STATE_CHANGED event to start a session
                        // But we reset start time just in case
                        Log.d(TAG, "Screen ON - Ready for next app")
                    }
                }
            }
        }
        registerReceiver(screenOffReceiver, filter)
    }

    private fun unregisterScreenReceiver() {
        screenOffReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering receiver: ${e.message}")
            }
        }
    }
    
    // Disable legacy UsageTrackingService writing to prevent double counting
    private fun disableLegacyTracking() {
         getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("is_accessibility_tracking_active", true)
            .apply()
    }

    // Enable legacy UsageTrackingService writing as fallback
    private fun enableLegacyTracking() {
         getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("is_accessibility_tracking_active", false)
            .apply()
    }

    private fun handleAppChange(newPackage: String) {
        // If it's the same app, ignore (unless we want to track sub-activities, but usually package level is fine)
        if (newPackage == currentSessionPackage) {
            return
        }

        // 1. Close previous session
        endCurrentSession()

        // 2. Start new session
        startNewSession(newPackage)
    }

    private fun startNewSession(packageName: String) {
        currentSessionPackage = packageName
        sessionStartTime = System.currentTimeMillis()
        
        // Track open count immediately
        trackSessionOpen(packageName, sessionStartTime)
        
        // Save current session to shared prefs for real-time UI
        saveCurrentSessionToPrefs(packageName, sessionStartTime)
        
        Log.d(TAG, "Started session for $packageName")
    }

    private fun endCurrentSession() {
        val packageName = currentSessionPackage ?: return
        val startTime = sessionStartTime
        
        if (startTime == 0L) return

        val endTime = System.currentTimeMillis()
        val duration = endTime - startTime

        if (duration > 0) { // Filter extremely short blips if needed, e.g. > 100ms
            // Add to daily total
            updateDailyUsage(packageName, duration)
            Log.d(TAG, "Ended session for $packageName: ${duration}ms")
        }

        currentSessionPackage = null
        sessionStartTime = 0
        
        // Clear current session from prefs
        clearCurrentSessionFromPrefs()
    }

    // --- Persistence Methods (Matching UsageTrackingService logic) ---

    private fun updateDailyUsage(packageName: String, duration: Long) {
        try {
            val prefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val calendar = Calendar.getInstance()
            val today = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
            
            val storageKey = "daily_usage_$today"
            val dataJson = prefs.getString(storageKey, "{}")
            val jsonObject = JSONObject(dataJson ?: "{}")
            
            val currentUsage = jsonObject.optLong(packageName, 0L)
            jsonObject.put(packageName, currentUsage + duration)
            
            prefs.edit()
                .putString(storageKey, jsonObject.toString())
                .putLong("last_update", System.currentTimeMillis())
                .apply()
                
        } catch (e: Exception) {
            Log.e(TAG, "Error saving usage: ${e.message}")
        }
    }

    private fun trackSessionOpen(packageName: String, timestamp: Long) {
        try {
            val prefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = timestamp
            val dateKey = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
            
            val storageKey = "session_count_$dateKey"
            val dataJson = prefs.getString(storageKey, "{}")
            val jsonObject = JSONObject(dataJson ?: "{}")
            
            val currentCount = jsonObject.optInt(packageName, 0)
            jsonObject.put(packageName, currentCount + 1)
            
            prefs.edit().putString(storageKey, jsonObject.toString()).apply()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error tracking open count: ${e.message}")
        }
    }
    
    private fun saveCurrentSessionToPrefs(packageName: String, startTime: Long) {
        try {
            val prefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val sessionsJson = JSONObject()
            sessionsJson.put(packageName, startTime)
            
            prefs.edit().putString("current_sessions", sessionsJson.toString()).apply()
        } catch (e: Exception) {
           Log.e(TAG, "Error saving current session: ${e.message}") 
        }
    }

    private fun clearCurrentSessionFromPrefs() {
         try {
            val prefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            prefs.edit().putString("current_sessions", "{}").apply()
        } catch (e: Exception) {
           Log.e(TAG, "Error clearing current session: ${e.message}") 
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            // Don't block our own app
            if (packageName == this.packageName) {
                return
            }

            // Check if there's a temporary unlock
            if (isTemporarilyUnlocked()) {
                return
            }

            // ✨ NEW: Track App Usage (Source of Truth)
            // This is where we detect app changes and track usage time/open counts
            // We ignore our own app and system UI usually, but handling everything gives best results
            // We can filter specific system packages later if needed
            handleAppChange(packageName)

            // Check if app is in active focus session (priority check)
            if (isInActiveFocusSession(packageName)) {
                Log.d(TAG, "Blocking app (Focus Mode): $packageName")
                incrementBlockAttempts(packageName)
                // Show full-screen block overlay instead of returning to home screen
                launchBlockOverlay(packageName)
                return
            }

            // Check if app has reached its usage limit (priority check)
            if (hasReachedUsageLimit(packageName)) {
                Log.d(TAG, "Blocking app (Usage Limit): $packageName")
                incrementBlockAttempts(packageName)
                // Show full-screen block overlay instead of returning to home screen
                launchBlockOverlay(packageName, "usage_limit_reached")
                return
            }

            // Check if app should be blocked based on its schedules
            if (shouldBlockApp(packageName)) {
                Log.d(TAG, "Blocking app: $packageName")

                // Increment block attempts
                incrementBlockAttempts(packageName)

                // Launch block overlay activity and keep user on this screen
                launchBlockOverlay(packageName)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    private fun shouldBlockApp(packageName: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val blockedAppsJson = prefs.getString(KEY_BLOCKED_APPS, null) ?: run {
            Log.d(TAG, "No blocked apps JSON found in preferences")
            return false
        }

        try {
            val blockedAppsArray = JSONArray(blockedAppsJson)
            Log.d(TAG, "Checking $packageName against ${blockedAppsArray.length()} blocked apps")

            // Find this app in blocked apps list
            for (i in 0 until blockedAppsArray.length()) {
                val appObj = blockedAppsArray.getJSONObject(i)
                if (appObj.getString("packageName") == packageName) {
                    val scheduleIds = appObj.optJSONArray("scheduleIds")

                    // If no schedules assigned, block 24/7
                    if (scheduleIds == null || scheduleIds.length() == 0) {
                        Log.d(TAG, "App $packageName has no schedules - blocking 24/7")
                        return true
                    }

                    // Check if current time is within any of the assigned schedules
                    Log.d(TAG, "App $packageName has ${scheduleIds.length()} schedule(s)")
                    val shouldBlock = isWithinAnySchedule(scheduleIds)
                    Log.d(TAG, "App $packageName should${if (shouldBlock) "" else " NOT"} be blocked")
                    return shouldBlock
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing blocked apps: ${e.message}")
        }

        return false
    }

    private fun isWithinAnySchedule(scheduleIds: JSONArray): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val schedulesJson = prefs.getString(KEY_SCHEDULES, null) ?: run {
            Log.d(TAG, "No schedules JSON found in preferences")
            return false
        }

        Log.d(TAG, "Schedules JSON: $schedulesJson")

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

            Log.d(TAG, "Current time: ${String.format("%02d:%02d", currentHour, currentMinute)} ($currentMinutes mins), Day: $dayOfWeek")

            // Check each assigned schedule
            for (i in 0 until scheduleIds.length()) {
                val scheduleId = scheduleIds.getString(i)

                // Find this schedule in all schedules
                for (j in 0 until schedulesArray.length()) {
                    val schedule = schedulesArray.getJSONObject(j)

                    if (schedule.getString("id") == scheduleId && schedule.getBoolean("isEnabled")) {
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

                            Log.d(TAG, "Schedule $scheduleId: ${String.format("%02d:%02d", startTime.getInt("hour"), startTime.getInt("minute"))} - ${String.format("%02d:%02d", endTime.getInt("hour"), endTime.getInt("minute"))}")

                            // Check if current time is within this schedule
                            val isWithinTime = if (endMinutes < startMinutes) {
                                // Schedule crosses midnight
                                currentMinutes >= startMinutes || currentMinutes <= endMinutes
                            } else {
                                currentMinutes >= startMinutes && currentMinutes <= endMinutes
                            }

                            Log.d(TAG, "Is within time? $isWithinTime (current: $currentMinutes, start: $startMinutes, end: $endMinutes)")

                            if (isWithinTime) {
                                Log.d(TAG, "✓ Current time is within schedule $scheduleId - BLOCKING")
                                return true
                            } else {
                                Log.d(TAG, "✗ Current time is NOT within schedule $scheduleId")
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking schedules: ${e.message}")
        }

        return false
    }

    private fun isInActiveFocusSession(packageName: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val sessionEndTime = prefs.getLong(KEY_FOCUS_SESSION_END, 0)

        // Check if session is still active
        if (System.currentTimeMillis() > sessionEndTime) {
            // Session expired, clear it
            if (sessionEndTime > 0) {
                prefs.edit()
                    .remove(KEY_FOCUS_SESSION_PACKAGES)
                    .remove(KEY_FOCUS_SESSION_END)
                    .apply()
                Log.d(TAG, "Focus session expired and cleared")
            }
            return false
        }

        // Check if package is in focus session
        val focusPackagesJson = prefs.getString(KEY_FOCUS_SESSION_PACKAGES, null)
        if (focusPackagesJson != null) {
            try {
                val packagesArray = JSONArray(focusPackagesJson)
                for (i in 0 until packagesArray.length()) {
                    if (packagesArray.getString(i) == packageName) {
                        Log.d(TAG, "Package $packageName is in active focus session")
                        return true
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing focus session packages: ${e.message}")
            }
        }

        return false
    }

    private fun hasReachedUsageLimit(packageName: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val usageLimitsJson = prefs.getString(KEY_USAGE_LIMITS, null) ?: return false

        try {
            val limitsArray = JSONArray(usageLimitsJson)

            // Find this app in usage limits
            for (i in 0 until limitsArray.length()) {
                val limit = limitsArray.getJSONObject(i)
                if (limit.getString("packageName") == packageName) {
                    val isEnabled = limit.optBoolean("isEnabled", true)
                    if (!isEnabled) {
                        return false
                    }

                    val dailyLimitMinutes = limit.getInt("dailyLimitMinutes")

                    // Get current app usage using UsageStatsManager
                    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? android.app.usage.UsageStatsManager
                    if (usageStatsManager == null) {
                        Log.e(TAG, "UsageStatsManager is null")
                        return false
                    }

                    val calendar = Calendar.getInstance()
                    calendar.set(Calendar.HOUR_OF_DAY, 0)
                    calendar.set(Calendar.MINUTE, 0)
                    calendar.set(Calendar.SECOND, 0)
                    calendar.set(Calendar.MILLISECOND, 0)
                    val startTime = calendar.timeInMillis
                    val endTime = System.currentTimeMillis()

                    val stats = usageStatsManager.queryUsageStats(
                        android.app.usage.UsageStatsManager.INTERVAL_DAILY,
                        startTime,
                        endTime
                    )

                    // Find usage for this specific package
                    val usageStat = stats?.find { it.packageName == packageName }
                    val usedMinutes = if (usageStat != null) {
                        (usageStat.totalTimeInForeground / 1000 / 60).toInt()
                    } else {
                        0
                    }

                    Log.d(TAG, "Usage limit check for $packageName: $usedMinutes/$dailyLimitMinutes minutes")

                    // Block if limit is reached
                    if (usedMinutes >= dailyLimitMinutes) {
                        Log.d(TAG, "✓ Usage limit reached for $packageName")
                        return true
                    }

                    return false
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking usage limit: ${e.message}")
        }

        return false
    }

    private fun isTemporarilyUnlocked(): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val unlockUntil = prefs.getLong(KEY_TEMP_UNLOCK, 0)
        val currentTime = System.currentTimeMillis()

        if (currentTime < unlockUntil) {
            return true
        } else if (unlockUntil > 0) {
            // Clear expired unlock
            prefs.edit().remove(KEY_TEMP_UNLOCK).apply()
        }

        return false
    }

    private fun incrementBlockAttempts(packageName: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val blockedAppsJson = prefs.getString(KEY_BLOCKED_APPS, null) ?: return

        try {
            val blockedAppsArray = JSONArray(blockedAppsJson)
            var found = false

            // Find and update the blocked app's attempts
            for (i in 0 until blockedAppsArray.length()) {
                val appObj = blockedAppsArray.getJSONObject(i)
                if (appObj.getString("packageName") == packageName) {
                    val currentAttempts = appObj.optInt("blockAttempts", 0)
                    appObj.put("blockAttempts", currentAttempts + 1)
                    found = true
                    Log.d(TAG, "Incremented block attempts for $packageName: ${currentAttempts + 1}")
                    break
                }
            }

            if (found) {
                // Save updated JSON back to preferences
                prefs.edit().putString(KEY_BLOCKED_APPS, blockedAppsArray.toString()).apply()
                Log.d(TAG, "Updated blocked apps JSON with new attempt count")
                
                // ✨ NEW: Also track daily block attempts for statistics
                trackDailyBlockAttempt(packageName)
            } else {
                Log.w(TAG, "Package $packageName not found in blocked apps list")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error incrementing block attempts: ${e.message}", e)
        }
    }

    /**
     * ✨ NEW: Track daily block attempts for statistics
     * Similar to session counting in UsageTrackingService
     */
    private fun trackDailyBlockAttempt(packageName: String) {
        try {
            val trackingPrefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val calendar = java.util.Calendar.getInstance()
            val today = "${calendar.get(java.util.Calendar.YEAR)}-${calendar.get(java.util.Calendar.MONTH) + 1}-${calendar.get(java.util.Calendar.DAY_OF_MONTH)}"
            
            val storageKey = "block_attempts_$today"
            
            // Get existing block attempts data for today
            val existingDataJson = trackingPrefs.getString(storageKey, "{}")
            val blockAttemptsData = JSONObject(existingDataJson ?: "{}")
            
            // Increment count for this app
            val currentCount = blockAttemptsData.optInt(packageName, 0)
            blockAttemptsData.put(packageName, currentCount + 1)
            
            // Save back to preferences
            trackingPrefs.edit()
                .putString(storageKey, blockAttemptsData.toString())
                .apply()
            
            Log.v(TAG, "Tracked block attempt for $packageName: ${currentCount + 1} on $today")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error tracking daily block attempt: ${e.message}", e)
        }
    }

    private fun launchBlockOverlay(packageName: String, blockReason: String? = null) {
        val intent = Intent(this, BlockOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            putExtra("blocked_package", packageName)
            if (blockReason != null) {
                putExtra("block_reason", blockReason)
            }
        }
        startActivity(intent)
    }
}
