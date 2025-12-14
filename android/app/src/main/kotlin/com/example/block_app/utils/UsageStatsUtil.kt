package com.example.block_app.utils

import android.app.Activity
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log

/**
 * Utility class for retrieving app usage statistics
 */
class UsageStatsUtil(private val activity: Activity) {

    companion object {
        private const val TAG = "UsageStatsUtil"
    }

    /**
     * Get app usage statistics for a time range
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

            // Query usage stats for the time range
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            if (usageStatsList.isNullOrEmpty()) {
                Log.d(TAG, "No usage stats found for time range: $startTime - $endTime")
                return emptyMap()
            }

            Log.d(TAG, "Found ${usageStatsList.size} usage stats entries")

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

                Log.d(TAG, "App: $packageName, Time: ${totalTime}ms")
            }

            Log.d(TAG, "Returning ${usageStatsMap.size} apps with usage data")
        } catch (e: Exception) {
            Log.e(TAG, "Error getting usage stats: ${e.message}", e)
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
     * Check if a package is a system app
     */
    private fun isSystemPackage(packageName: String): Boolean {
        // Skip known system packages
        val systemPackages = setOf(
            "android",
            "com.android.systemui",
            "com.android.settings",
            "com.google.android.gms",
            "com.google.android.gsf"
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
}
