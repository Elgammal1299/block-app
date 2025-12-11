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
import com.example.block_app.services.AppMonitorService

class AppBlockerChannel(
    private val activity: Activity,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    private val appInfoUtil = AppInfoUtil(activity)
    private val permissionUtil = PermissionUtil(activity)

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

            // Get app usage stats
            "getAppUsageStats" -> {
                try {
                    val startTime = call.argument<Long>("startTime")
                    val endTime = call.argument<Long>("endTime")
                    if (startTime != null && endTime != null) {
                        // TODO: Get usage stats
                        val usageStats = mapOf<String, Long>()
                        result.success(usageStats)
                    } else {
                        result.error("ERROR", "Start or end time is null", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get usage stats: ${e.message}", null)
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
