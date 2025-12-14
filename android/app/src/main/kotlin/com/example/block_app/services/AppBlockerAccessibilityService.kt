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

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility Service Connected")

        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        info.notificationTimeout = 100
        serviceInfo = info
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

            // Check if app is in active focus session (priority check)
            if (isInActiveFocusSession(packageName)) {
                Log.d(TAG, "Blocking app (Focus Mode): $packageName")
                incrementBlockAttempts(packageName)
                launchBlockOverlay(packageName)
                performGlobalAction(GLOBAL_ACTION_HOME)
                return
            }

            // Check if app has reached its usage limit (priority check)
            if (hasReachedUsageLimit(packageName)) {
                Log.d(TAG, "Blocking app (Usage Limit): $packageName")
                incrementBlockAttempts(packageName)
                launchBlockOverlay(packageName, "usage_limit_reached")
                performGlobalAction(GLOBAL_ACTION_HOME)
                return
            }

            // Check if app should be blocked based on its schedules
            if (shouldBlockApp(packageName)) {
                Log.d(TAG, "Blocking app: $packageName")

                // Increment block attempts
                incrementBlockAttempts(packageName)

                // Launch block overlay activity
                launchBlockOverlay(packageName)

                // Force go back to home
                performGlobalAction(GLOBAL_ACTION_HOME)
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
        val currentAttempts = prefs.getInt("attempts_$packageName", 0)
        prefs.edit().putInt("attempts_$packageName", currentAttempts + 1).apply()
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
