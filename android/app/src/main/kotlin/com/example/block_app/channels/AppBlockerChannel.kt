package com.example.block_app.channels

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.example.block_app.utils.AppInfoUtil
import com.example.block_app.utils.PermissionUtil
import com.example.block_app.utils.UsageStatsUtil
import com.example.block_app.utils.WorkManagerUtil
import com.example.block_app.utils.UsageDataCleaner
import com.example.block_app.services.AppMonitorService
import com.example.block_app.services.UsageTrackingService

class AppBlockerChannel(
    private val activity: Activity,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    private val appInfoUtil = AppInfoUtil(activity)
    private val permissionUtil = PermissionUtil(activity)
    private val usageStatsUtil = UsageStatsUtil(activity)
    private val workManagerUtil = WorkManagerUtil(activity)

    fun setupMethodChannel() {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Get installed apps
            "getInstalledApps" -> {
                try {
                    val apps = appInfoUtil.getInstalledApps()
                    result.success(apps)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get installed apps: ${e.message}", null)
                }
            }

            // Usage Stats Permission
            "checkUsageStatsPermission" -> {
                val hasPermission = permissionUtil.hasUsageStatsPermission()
                result.success(hasPermission)
            }

            "requestUsageStatsPermission" -> {
                permissionUtil.requestUsageStatsPermission()
                result.success(null)
            }

            // Overlay Permission
            "checkOverlayPermission" -> {
                val hasPermission = permissionUtil.hasOverlayPermission()
                result.success(hasPermission)
            }

            "requestOverlayPermission" -> {
                permissionUtil.requestOverlayPermission()
                result.success(null)
            }

            // Accessibility Permission
            "checkAccessibilityPermission" -> {
                val hasPermission = permissionUtil.hasAccessibilityPermission()
                result.success(hasPermission)
            }

            "requestAccessibilityPermission" -> {
                permissionUtil.requestAccessibilityPermission()
                result.success(null)
            }

            // Monitoring Service
            "startMonitoringService" -> {
                try {
                    val intent = Intent(activity, AppMonitorService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        activity.startForegroundService(intent)
                    } else {
                        activity.startService(intent)
                    }
                    Log.d("AppBlockerChannel", "Monitoring service started")
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to start service: ${e.message}", null)
                }
            }

            "stopMonitoringService" -> {
                try {
                    val intent = Intent(activity, AppMonitorService::class.java)
                    activity.stopService(intent)
                    Log.d("AppBlockerChannel", "Monitoring service stopped")
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to stop service: ${e.message}", null)
                }
            }

            // Usage Tracking Service
            "startUsageTrackingService" -> {
                try {
                    // Save that services are enabled for auto-restart
                    val prefs = activity.getSharedPreferences("app_settings", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("services_enabled", true).apply()

                    val intent = Intent(activity, UsageTrackingService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        activity.startForegroundService(intent)
                    } else {
                        activity.startService(intent)
                    }
                    Log.d("AppBlockerChannel", "Usage tracking service started")
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to start usage tracking service: ${e.message}", null)
                }
            }

            "stopUsageTrackingService" -> {
                try {
                    // Mark services as disabled to prevent auto-restart
                    val prefs = activity.getSharedPreferences("app_settings", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("services_enabled", false).apply()

                    val intent = Intent(activity, UsageTrackingService::class.java)
                    activity.stopService(intent)
                    Log.d("AppBlockerChannel", "Usage tracking service stopped")
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to stop usage tracking service: ${e.message}", null)
                }
            }

            // Update blocked apps
            "updateBlockedApps" -> {
                try {
                    val packageNames = call.argument<List<String>>("packageNames")
                    if (packageNames != null) {
                        // Save to SharedPreferences
                        val sharedPrefs = activity.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                        val editor = sharedPrefs.edit()
                        editor.putStringSet("blocked_apps", packageNames.toSet())
                        editor.apply()
                        result.success(null)
                    } else {
                        result.error("ERROR", "Package names are null", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to update blocked apps: ${e.message}", null)
                }
            }

            // Update blocked apps with full JSON data
            "updateBlockedAppsJson" -> {
                try {
                    val appsJson = call.argument<String>("appsJson")
                    if (appsJson != null) {
                        val prefs = activity.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                        prefs.edit().putString("blocked_apps", appsJson).apply()
                        Log.d("AppBlockerChannel", "Blocked apps JSON updated: $appsJson")
                        result.success(null)
                    } else {
                        result.error("ERROR", "Apps JSON is null", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to update blocked apps JSON: ${e.message}", null)
                }
            }

            // Update schedules
            "updateSchedules" -> {
                try {
                    val schedules = call.argument<List<Map<String, Any>>>("schedules")
                    if (schedules != null) {
                        val prefs = activity.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                        val schedulesJson = org.json.JSONArray(schedules).toString()
                        prefs.edit().putString("schedules", schedulesJson).apply()
                        Log.d("AppBlockerChannel", "Schedules updated: $schedulesJson")
                        result.success(null)
                    } else {
                        result.error("ERROR", "Schedules are null", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to update schedules: ${e.message}", null)
                }
            }

            // Update usage limits
            "updateUsageLimits" -> {
                try {
                    val limitsJson = call.argument<String>("limitsJson")
                    if (limitsJson != null) {
                        val prefs = activity.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                        prefs.edit().putString("usage_limits", limitsJson).apply()
                        Log.d("AppBlockerChannel", "Usage limits updated: $limitsJson")
                        result.success(null)
                    } else {
                        result.error("ERROR", "Limits JSON is null", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to update usage limits: ${e.message}", null)
                }
            }

            // Get app usage stats
            "getAppUsageStats" -> {
                try {
                    val startTime = call.argument<Long>("startTime")
                    val endTime = call.argument<Long>("endTime")
                    if (startTime != null && endTime != null) {
                        Log.d("AppBlockerChannel", "Getting usage stats from $startTime to $endTime")

                        // Get usage stats from utility
                        val usageStats = usageStatsUtil.getAppUsageStats(startTime, endTime)

                        Log.d("AppBlockerChannel", "Found ${usageStats.size} apps with usage data")
                        result.success(usageStats)
                    } else {
                        result.error("ERROR", "Start or end time is null", null)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get usage stats", e)
                    result.error("ERROR", "Failed to get usage stats: ${e.message}", null)
                }
            }

            // Get app name from package name
            "getAppName" -> {
                try {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val appName = usageStatsUtil.getAppName(packageName)
                        result.success(appName)
                    } else {
                        result.error("ERROR", "Package name is null", null)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get app name", e)
                    result.error("ERROR", "Failed to get app name: ${e.message}", null)
                }
            }

            // Get hourly usage stats
            "getHourlyUsageStats" -> {
                try {
                    val startTime = call.argument<Long>("startTime")
                    val endTime = call.argument<Long>("endTime")
                    if (startTime != null && endTime != null) {
                        Log.d("AppBlockerChannel", "Getting hourly usage stats from $startTime to $endTime")

                        val hourlyStats = usageStatsUtil.getHourlyUsageStats(startTime, endTime)

                        Log.d("AppBlockerChannel", "Generated ${hourlyStats.size} hourly data points")
                        result.success(hourlyStats)
                    } else {
                        result.error("ERROR", "Start or end time is null", null)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get hourly usage stats", e)
                    result.error("ERROR", "Failed to get hourly usage stats: ${e.message}", null)
                }
            }

            // Get today's usage from UsageTrackingService (real-time, more accurate)
            "getTodayUsageFromTrackingService" -> {
                try {
                    Log.d("AppBlockerChannel", "Getting today's usage from UsageTrackingService")

                    val usageData = usageStatsUtil.getTodayUsageFromTrackingService()

                    if (usageData.isEmpty()) {
                        Log.d("AppBlockerChannel", "UsageTrackingService data is empty or stale")
                        result.success(emptyMap<String, Long>())
                    } else {
                        Log.d("AppBlockerChannel", "Retrieved ${usageData.size} apps from UsageTrackingService")
                        result.success(usageData)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get usage from tracking service", e)
                    result.error("ERROR", "Failed to get usage from tracking service: ${e.message}", null)
                }
            }

            // Get usage for a specific date from UsageTrackingService
            "getUsageForDateFromTracking" -> {
                try {
                    val dateStr = call.argument<String>("date")
                    if (dateStr != null) {
                        Log.d("AppBlockerChannel", "Getting usage for date: $dateStr")

                        val usageData = usageStatsUtil.getUsageForDateFromTracking(dateStr)

                        Log.d("AppBlockerChannel", "Retrieved ${usageData.size} apps for $dateStr")
                        result.success(usageData)
                    } else {
                        result.error("ERROR", "Date string is null", null)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get usage for date", e)
                    result.error("ERROR", "Failed to get usage for date: ${e.message}", null)
                }
            }

            // Get pending snapshot dates
            "getPendingSnapshotDates" -> {
                try {
                    val prefs = activity.getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
                    val pendingSnapshots = prefs.getStringSet("pending_snapshots", emptySet()) ?: emptySet()

                    val datesList = pendingSnapshots.toList()
                    Log.d("AppBlockerChannel", "Found ${datesList.size} pending snapshots")

                    result.success(datesList)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get pending snapshots", e)
                    result.error("ERROR", "Failed to get pending snapshots: ${e.message}", null)
                }
            }

            // Clear pending snapshot dates
            "clearPendingSnapshotDates" -> {
                try {
                    val prefs = activity.getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
                    prefs.edit()
                        .remove("pending_snapshots")
                        .apply()

                    Log.d("AppBlockerChannel", "Cleared pending snapshots list")
                    result.success(null)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to clear pending snapshots", e)
                    result.error("ERROR", "Failed to clear pending snapshots: ${e.message}", null)
                }
            }

            // Check if device has OEM restrictions that may affect tracking
            "checkOEMRestrictions" -> {
                try {
                    val manufacturer = android.os.Build.MANUFACTURER.lowercase()
                    val model = android.os.Build.MODEL

                    val hasRestrictions = when {
                        manufacturer.contains("xiaomi") -> true
                        manufacturer.contains("huawei") -> true
                        manufacturer.contains("oppo") -> true
                        manufacturer.contains("vivo") -> true
                        manufacturer.contains("realme") -> true
                        manufacturer.contains("oneplus") -> true
                        else -> false
                    }

                    val resultMap = mapOf(
                        "hasRestrictions" to hasRestrictions,
                        "manufacturer" to manufacturer,
                        "model" to model
                    )

                    Log.d("AppBlockerChannel", "OEM check: $manufacturer $model - restrictions: $hasRestrictions")
                    result.success(resultMap)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to check OEM restrictions", e)
                    result.error("ERROR", "Failed to check OEM restrictions: ${e.message}", null)
                }
            }

            // Clean stored usage data (remove our own app)
            "cleanStoredUsageData" -> {
                try {
                    UsageDataCleaner.cleanAllStoredData(activity)
                    Log.d("AppBlockerChannel", "Successfully cleaned stored usage data")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to clean stored usage data", e)
                    result.error("ERROR", "Failed to clean usage data: ${e.message}", null)
                }
            }

            // Focus Mode Methods
            "startFocusSession" -> {
                try {
                    val packageNames = call.argument<List<String>>("packageNames")
                    val durationMinutes = call.argument<Int>("durationMinutes")

                    if (packageNames != null && durationMinutes != null) {
                        val prefs = activity.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                        val editor = prefs.edit()

                        // Save focus session packages as JSON array
                        val packagesJson = org.json.JSONArray(packageNames).toString()
                        editor.putString("focus_session_packages", packagesJson)

                        // Calculate and save end time
                        val endTime = System.currentTimeMillis() + (durationMinutes * 60 * 1000)
                        editor.putLong("focus_session_end_time", endTime)

                        editor.apply()

                        Log.d("AppBlockerChannel", "Focus session started: $durationMinutes min, ${packageNames.size} apps")
                        result.success(null)
                    } else {
                        result.error("ERROR", "Package names or duration is null", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to start focus session: ${e.message}", null)
                }
            }

            "endFocusSession" -> {
                try {
                    val prefs = activity.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                    val editor = prefs.edit()
                    editor.remove("focus_session_packages")
                    editor.remove("focus_session_end_time")
                    editor.apply()

                    Log.d("AppBlockerChannel", "Focus session ended")
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to end focus session: ${e.message}", null)
                }
            }

            // Background Work Methods
            "scheduleDailySnapshot" -> {
                try {
                    workManagerUtil.scheduleDailySnapshot()
                    Log.d("AppBlockerChannel", "Daily snapshot scheduled")
                    result.success(null)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to schedule daily snapshot", e)
                    result.error("ERROR", "Failed to schedule daily snapshot: ${e.message}", null)
                }
            }

            "runSnapshotNow" -> {
                try {
                    workManagerUtil.runSnapshotNow()
                    Log.d("AppBlockerChannel", "Running snapshot now")
                    result.success(null)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to run snapshot", e)
                    result.error("ERROR", "Failed to run snapshot: ${e.message}", null)
                }
            }

            // Block Screen Style
            "setBlockScreenStyle" -> {
                try {
                    val style = call.argument<String>("style")
                    if (style != null) {
                        val prefs = activity.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                        prefs.edit().putString("block_screen_style", style).apply()
                        Log.d("AppBlockerChannel", "Block screen style set to: $style")
                        result.success(null)
                    } else {
                        result.error("ERROR", "Style is null", null)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to set block screen style", e)
                    result.error("ERROR", "Failed to set block screen style: ${e.message}", null)
                }
            }

            // Get session counts (number of times apps were opened)
            "getSessionCounts" -> {
                try {
                    val startTime = call.argument<Long>("startTime")
                    val endTime = call.argument<Long>("endTime")
                    if (startTime != null && endTime != null) {
                        Log.d("AppBlockerChannel", "Getting session counts from $startTime to $endTime")

                        val sessionCounts = usageStatsUtil.getSessionCounts(startTime, endTime)

                        Log.d("AppBlockerChannel", "Found ${sessionCounts.size} apps with session counts")
                        result.success(sessionCounts)
                    } else {
                        result.error("ERROR", "Start or end time is null", null)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get session counts", e)
                    result.error("ERROR", "Failed to get session counts: ${e.message}", null)
                }
            }

            // Get today's session counts from UsageTrackingService
            "getTodaySessionCountsFromTracking" -> {
                try {
                    Log.d("AppBlockerChannel", "Getting today's session counts from UsageTrackingService")

                    val sessionCounts = usageStatsUtil.getTodaySessionCountsFromTracking()

                    Log.d("AppBlockerChannel", "Retrieved ${sessionCounts.size} session counts from tracking")
                    result.success(sessionCounts)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get session counts from tracking", e)
                    result.error("ERROR", "Failed to get session counts from tracking: ${e.message}", null)
                }
            }

            // Get session counts for a specific date
            "getSessionCountsForDate" -> {
                try {
                    val dateStr = call.argument<String>("date")
                    if (dateStr != null) {
                        Log.d("AppBlockerChannel", "Getting session counts for date: $dateStr")

                        val sessionCounts = usageStatsUtil.getSessionCountsForDate(dateStr)

                        Log.d("AppBlockerChannel", "Retrieved ${sessionCounts.size} session counts for $dateStr")
                        result.success(sessionCounts)
                    } else {
                        result.error("ERROR", "Date string is null", null)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get session counts for date", e)
                    result.error("ERROR", "Failed to get session counts for date: ${e.message}", null)
                }
            }

            // Get today's block attempts from tracking
            "getTodayBlockAttemptsFromTracking" -> {
                try {
                    Log.d("AppBlockerChannel", "Getting today's block attempts from tracking")

                    val blockAttempts = usageStatsUtil.getTodayBlockAttemptsFromTracking()

                    Log.d("AppBlockerChannel", "Retrieved ${blockAttempts.size} block attempts from tracking")
                    result.success(blockAttempts)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get block attempts from tracking", e)
                    result.error("ERROR", "Failed to get block attempts from tracking: ${e.message}", null)
                }
            }

            // Get block attempts for a specific date
            "getBlockAttemptsForDate" -> {
                try {
                    val dateStr = call.argument<String>("date")
                    if (dateStr != null) {
                        Log.d("AppBlockerChannel", "Getting block attempts for date: $dateStr")

                        val blockAttempts = usageStatsUtil.getBlockAttemptsForDate(dateStr)

                        Log.d("AppBlockerChannel", "Retrieved ${blockAttempts.size} block attempts for $dateStr")
                        result.success(blockAttempts)
                    } else {
                        result.error("ERROR", "Date string is null", null)
                    }
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get block attempts for date", e)
                    result.error("ERROR", "Failed to get block attempts for date: ${e.message}", null)
                }
            }

            // Get blocked apps JSON from native (for syncing block attempts)
            "getBlockedAppsJson" -> {
                try {
                    val prefs = activity.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                    val blockedAppsJson = prefs.getString("blocked_apps", null) ?: "[]"
                    Log.d("AppBlockerChannel", "Retrieved blocked apps JSON: $blockedAppsJson")
                    result.success(blockedAppsJson)
                } catch (e: Exception) {
                    Log.e("AppBlockerChannel", "Failed to get blocked apps JSON", e)
                    result.error("ERROR", "Failed to get blocked apps JSON: ${e.message}", null)
                }
            }

            // ✨ NEW: Reset stats command
            "clearUsageData" -> {
                try {
                    usageStatsUtil.clearAllUsageData()
                    result.success(true)
                } catch (e: Exception) {
                     Log.e("AppBlockerChannel", "Failed to clear usage data", e)
                     result.error("ERROR", "Failed to clear usage data: ${e.message}", null)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    // Method to send callbacks to Flutter
    fun notifyAppBlocked(packageName: String, attempts: Int) {
        val args = mapOf(
            "packageName" to packageName,
            "attempts" to attempts
        )
        channel.invokeMethod("onAppBlocked", args)
    }

    fun notifyServiceStatusChanged(isRunning: Boolean) {
        val args = mapOf("isRunning" to isRunning)
        channel.invokeMethod("onServiceStatusChanged", args)
    }
}
