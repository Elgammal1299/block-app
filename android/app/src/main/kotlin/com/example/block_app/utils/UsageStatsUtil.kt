package com.example.block_app.utils

import android.app.Activity
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import java.util.Calendar

/**
 * Utility class for retrieving app usage statistics
 */
class UsageStatsUtil(private val activity: Activity) {

    companion object {
        private const val TAG = "UsageStatsUtil"
    }

    /**
     * Get app usage statistics for a time range using accurate UsageEvents
     * Returns a map of packageName -> usage time in milliseconds
     */
    fun getAppUsageStats(startTime: Long, endTime: Long): Map<String, Long> {
        val usageStatsMap = mutableMapOf<String, Long>()

        try {
            val usageStatsManager = activity.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageStatsManager == null) {
                Log.e(TAG, "UsageStatsManager is null")
                return emptyMap()
            }

            Log.d(TAG, "Querying usage stats from $startTime to $endTime")

            // Use UsageEvents for accurate tracking
            val events = usageStatsManager.queryEvents(startTime, endTime)
            if (events == null) {
                Log.w(TAG, "UsageEvents query returned null, falling back to UsageStats")
                return getFallbackUsageStats(usageStatsManager, startTime, endTime)
            }

            val openApps = mutableMapOf<String, Long>() // packageName -> openTime
            var eventsProcessed = 0

            while (events.hasNextEvent()) {
                val event = android.app.usage.UsageEvents.Event()
                events.getNextEvent(event)

                val packageName = event.packageName
                val timestamp = event.timeStamp

                // Skip system apps
                if (isSystemPackage(packageName)) {
                    continue
                }

                when (event.eventType) {
                    android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND,
                    android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED -> {
                        // App opened/resumed
                        openApps[packageName] = timestamp
                        eventsProcessed++
                    }

                    android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND,
                    android.app.usage.UsageEvents.Event.ACTIVITY_PAUSED,
                    android.app.usage.UsageEvents.Event.ACTIVITY_STOPPED -> {
                        // App closed/paused
                        val openTime = openApps[packageName]
                        if (openTime != null) {
                            val duration = timestamp - openTime
                            if (duration > 0) {
                                val currentUsage = usageStatsMap[packageName] ?: 0L
                                usageStatsMap[packageName] = currentUsage + duration
                            }
                            openApps.remove(packageName)
                        }
                        eventsProcessed++
                    }
                }
            }

            // Handle apps still open at endTime
            for ((packageName, openTime) in openApps) {
                if (openTime < endTime) {
                    val duration = endTime - openTime
                    if (duration > 0) {
                        val currentUsage = usageStatsMap[packageName] ?: 0L
                        usageStatsMap[packageName] = currentUsage + duration
                    }
                }
            }

            Log.d(TAG, "Processed $eventsProcessed events, returning ${usageStatsMap.size} apps with usage data")

        } catch (e: Exception) {
            Log.e(TAG, "Error getting usage stats: ${e.message}", e)
        }

        return usageStatsMap
    }

    /**
     * Fallback method using traditional UsageStats (less accurate but works as backup)
     */
    private fun getFallbackUsageStats(
        usageStatsManager: UsageStatsManager,
        startTime: Long,
        endTime: Long
    ): Map<String, Long> {
        val usageStatsMap = mutableMapOf<String, Long>()

        try {
            // Use INTERVAL_DAILY for better accuracy
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            if (usageStatsList.isNullOrEmpty()) {
                Log.d(TAG, "No usage stats found for time range (fallback)")
                return emptyMap()
            }

            Log.d(TAG, "Using fallback method - Found ${usageStatsList.size} usage stats entries")

            // Aggregate usage by package name
            for (usageStats in usageStatsList) {
                val packageName = usageStats.packageName
                val totalTime = usageStats.totalTimeInForeground

                // Skip system apps and apps with zero usage
                if (totalTime <= 0 || isSystemPackage(packageName)) {
                    continue
                }

                // Add or accumulate usage time
                val currentTime = usageStatsMap[packageName] ?: 0L
                usageStatsMap[packageName] = currentTime + totalTime

                Log.v(TAG, "App: $packageName, Time: ${totalTime}ms")
            }

            Log.d(TAG, "Fallback: Returning ${usageStatsMap.size} apps with usage data")

        } catch (e: Exception) {
            Log.e(TAG, "Error in fallback usage stats: ${e.message}", e)
        }

        return usageStatsMap
    }

    /**
     * Get app usage statistics with app names included
     * Returns a map with both package names and app names
     */
    fun getAppUsageStatsWithNames(startTime: Long, endTime: Long): Map<String, Map<String, Any>> {
        val resultMap = mutableMapOf<String, Map<String, Any>>()
        val usageStatsMap = getAppUsageStats(startTime, endTime)

        for ((packageName, usageTime) in usageStatsMap) {
            val appName = getAppName(packageName)
            resultMap[packageName] = mapOf(
                "appName" to appName,
                "usageTime" to usageTime
            )
        }

        return resultMap
    }

    /**
     * Get the display name of an app from its package name
     */
    fun getAppName(packageName: String): String {
        return try {
            val packageManager = activity.packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            Log.w(TAG, "App name not found for package: $packageName")
            packageName // Return package name as fallback
        }
    }

    /**
     * Check if a package is a system app or our own app
     */
    private fun isSystemPackage(packageName: String): Boolean {
        // Skip known system packages
        val systemPackages = setOf(
            "android",
            "com.android.systemui",
            "com.android.settings",
            "com.google.android.gms",
            "com.google.android.gsf",
            "com.example.block_app" // Skip our own app from statistics
        )

        return systemPackages.contains(packageName) || packageName.startsWith("com.android.")
    }

    /**
     * Get total screen time for a time range
     */
    fun getTotalScreenTime(startTime: Long, endTime: Long): Long {
        val usageStats = getAppUsageStats(startTime, endTime)
        return usageStats.values.sum()
    }

    /**
     * Get top N apps by usage time
     */
    fun getTopApps(startTime: Long, endTime: Long, limit: Int = 10): List<Pair<String, Long>> {
        val usageStats = getAppUsageStats(startTime, endTime)
        return usageStats.entries
            .sortedByDescending { it.value }
            .take(limit)
            .map { Pair(it.key, it.value) }
    }

    /**
     * Get hourly usage statistics for a time range
     * Returns a list of 24 maps, each containing usage data for that hour (0-23)
     * Each map contains: hour -> Map<packageName, usageTimeInMillis>
     */
    fun getHourlyUsageStats(startTime: Long, endTime: Long): List<Map<String, Any>> {
        val hourlyData = mutableListOf<Map<String, Any>>()

        try {
            val usageStatsManager = activity.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageStatsManager == null) {
                Log.e(TAG, "UsageStatsManager is null")
                return createEmptyHourlyData()
            }

            // Initialize 24 hours with empty data
            val hourlyUsageMap = Array(24) { mutableMapOf<String, Long>() }
            val calendar = java.util.Calendar.getInstance()

            // Query usage events for accurate hourly tracking
            val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
            if (usageEvents == null) {
                Log.w(TAG, "Usage events is null")
                return createEmptyHourlyData()
            }

            val openApps = mutableMapOf<String, Pair<Long, Int>>() // packageName -> (openTime, openHour)
            var eventsProcessed = 0

            while (usageEvents.hasNextEvent()) {
                val event = android.app.usage.UsageEvents.Event()
                usageEvents.getNextEvent(event)

                val packageName = event.packageName
                val timestamp = event.timeStamp

                // Skip system apps
                if (isSystemPackage(packageName)) {
                    continue
                }

                when (event.eventType) {
                    android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND,
                    android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED -> {
                        // App opened/resumed
                        calendar.timeInMillis = timestamp
                        val hour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
                        openApps[packageName] = Pair(timestamp, hour)
                        eventsProcessed++
                    }

                    android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND,
                    android.app.usage.UsageEvents.Event.ACTIVITY_PAUSED,
                    android.app.usage.UsageEvents.Event.ACTIVITY_STOPPED -> {
                        // App closed/paused
                        val (openTime, startHour) = openApps[packageName] ?: continue

                        calendar.timeInMillis = timestamp
                        val endHour = calendar.get(java.util.Calendar.HOUR_OF_DAY)

                        // Calculate duration and distribute across hours if needed
                        if (startHour == endHour) {
                            // Simple case: same hour
                            val duration = timestamp - openTime
                            if (duration > 0 && startHour in 0..23) {
                                val currentUsage = hourlyUsageMap[startHour][packageName] ?: 0L
                                hourlyUsageMap[startHour][packageName] = currentUsage + duration
                            }
                        } else {
                            // Complex case: usage spans multiple hours
                            distributeUsageAcrossHours(
                                packageName,
                                openTime,
                                timestamp,
                                hourlyUsageMap,
                                calendar
                            )
                        }

                        openApps.remove(packageName)
                        eventsProcessed++
                    }
                }
            }

            // Handle apps that are still open at endTime
            for ((packageName, openInfo) in openApps) {
                val (openTime, startHour) = openInfo
                if (openTime < endTime) {
                    calendar.timeInMillis = endTime
                    val endHour = calendar.get(java.util.Calendar.HOUR_OF_DAY)

                    if (startHour == endHour) {
                        val duration = endTime - openTime
                        if (duration > 0 && startHour in 0..23) {
                            val currentUsage = hourlyUsageMap[startHour][packageName] ?: 0L
                            hourlyUsageMap[startHour][packageName] = currentUsage + duration
                        }
                    } else {
                        distributeUsageAcrossHours(
                            packageName,
                            openTime,
                            endTime,
                            hourlyUsageMap,
                            calendar
                        )
                    }
                }
            }

            // Convert to list format
            for (hour in 0..23) {
                val hourData = mutableMapOf<String, Any>()
                hourData["hour"] = hour

                // Calculate total time for this hour
                val totalTime = hourlyUsageMap[hour].values.sum()
                hourData["totalTimeInMillis"] = totalTime

                // Add app breakdown
                hourData["appBreakdown"] = hourlyUsageMap[hour].toMap()

                hourlyData.add(hourData)
            }

            Log.d(TAG, "Generated hourly usage data for 24 hours ($eventsProcessed events processed)")

        } catch (e: Exception) {
            Log.e(TAG, "Error getting hourly usage stats: ${e.message}", e)
            return createEmptyHourlyData()
        }

        return hourlyData
    }

    /**
     * Distribute usage across multiple hours when a session spans hour boundaries
     */
    private fun distributeUsageAcrossHours(
        packageName: String,
        startTime: Long,
        endTime: Long,
        hourlyUsageMap: Array<MutableMap<String, Long>>,
        calendar: Calendar
    ) {
        var currentTime = startTime

        while (currentTime < endTime) {
            calendar.timeInMillis = currentTime
            val currentHour = calendar.get(Calendar.HOUR_OF_DAY)

            // Calculate end of current hour (exact boundary)
            val hourEndExact = calendar.clone() as Calendar
            hourEndExact.set(Calendar.MINUTE, 59)
            hourEndExact.set(Calendar.SECOND, 59)
            hourEndExact.set(Calendar.MILLISECOND, 999)

            // Use exact hour boundary without adding 1ms to avoid data leakage
            val segmentEnd = minOf(endTime, hourEndExact.timeInMillis)
            val duration = segmentEnd - currentTime

            if (duration > 0 && currentHour in 0..23) {
                val currentUsage = hourlyUsageMap[currentHour][packageName] ?: 0L
                hourlyUsageMap[currentHour][packageName] = currentUsage + duration

                Log.v(TAG, "Distributed $duration ms to hour $currentHour for $packageName")
            }

            // Move to start of next hour (after the 999ms boundary)
            currentTime = hourEndExact.timeInMillis + 1
        }
    }

    /**
     * Create empty hourly data structure (all zeros)
     */
    private fun createEmptyHourlyData(): List<Map<String, Any>> {
        return (0..23).map { hour ->
            mapOf(
                "hour" to hour,
                "totalTimeInMillis" to 0L,
                "appBreakdown" to emptyMap<String, Long>()
            )
        }
    }

    /**
     * Get today's usage from UsageTrackingService (real-time data)
     * This is more accurate than queryUsageStats as it's updated every 10 seconds
     */
    fun getTodayUsageFromTrackingService(): Map<String, Long> {
        try {
            val prefs = activity.getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val calendar = java.util.Calendar.getInstance()
            val today = "${calendar.get(java.util.Calendar.YEAR)}-${calendar.get(java.util.Calendar.MONTH) + 1}-${calendar.get(java.util.Calendar.DAY_OF_MONTH)}"

            val storageKey = "daily_usage_$today"
            val dataJson = prefs.getString(storageKey, "{}")
            val lastUpdate = prefs.getLong("last_update", 0L)

            // Check if data is recent (updated within last 30 seconds)
            val isRecent = (System.currentTimeMillis() - lastUpdate) < 30000

            if (!isRecent) {
                Log.w(TAG, "UsageTrackingService data is stale, falling back to UsageStats API")
                return emptyMap()
            }

            val jsonObject = org.json.JSONObject(dataJson ?: "{}")
            val result = mutableMapOf<String, Long>()

            jsonObject.keys().forEach { key ->
                val usage = jsonObject.getLong(key)
                if (usage > 0) {
                    result[key] = usage
                }
            }

            Log.d(TAG, "Retrieved ${result.size} apps from UsageTrackingService (last update: ${System.currentTimeMillis() - lastUpdate}ms ago)")
            return result

        } catch (e: Exception) {
            Log.e(TAG, "Error getting data from UsageTrackingService: ${e.message}", e)
            return emptyMap()
        }
    }

    /**
     * Get usage data for a specific date from UsageTrackingService storage
     */
    fun getUsageForDateFromTracking(date: String): Map<String, Long> {
        try {
            val prefs = activity.getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val storageKey = "daily_usage_$date"
            val dataJson = prefs.getString(storageKey, "{}")

            val jsonObject = org.json.JSONObject(dataJson ?: "{}")
            val result = mutableMapOf<String, Long>()

            jsonObject.keys().forEach { key ->
                result[key] = jsonObject.getLong(key)
            }

            return result
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing usage data for $date: ${e.message}")
            return emptyMap()
        }
    }
}
