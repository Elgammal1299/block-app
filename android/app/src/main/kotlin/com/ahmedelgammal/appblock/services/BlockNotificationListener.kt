package com.ahmedelgammal.appblock.services

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class BlockNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        
        if (isBlockingActive(packageName)) {
            cancelNotification(sbn.key)
            Log.d("NotificationListener", "Blocked notification from: $packageName")
        }
    }

    private fun isBlockingActive(packageName: String): Boolean {
        val prefs = getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
        
        // 1. Check Focus Session
        val focusEndTime = prefs.getLong("focus_session_end_time", 0)
        if (System.currentTimeMillis() < focusEndTime) {
            val focusPackagesStr = prefs.getString("focus_session_packages", "[]")
            try {
                val focusPackages = JSONArray(focusPackagesStr)
                for (i in 0 until focusPackages.length()) {
                    if (focusPackages.getString(i) == packageName) return true
                }
            } catch (e: Exception) {
                Log.e("NotificationListener", "Error parsing focus packages", e)
            }
        }

        // 2. Check Dynamic Blocked Apps (Usage Limits)
        val dynamicBlocksJson = prefs.getString("dynamic_blocked_apps", "{}")
        if (dynamicBlocksJson != null && dynamicBlocksJson != "{}") {
            try {
                val dynamicObj = JSONObject(dynamicBlocksJson)
                if (dynamicObj.has(packageName)) {
                    val appObj = dynamicObj.getJSONObject(packageName)
                    if (appObj.optBoolean("isBlocked", false)) return true
                }
            } catch (e: Exception) {
                Log.e("NotificationListener", "Error parsing dynamic blocks", e)
            }
        }

        // 3. Check General Blocked Apps & Schedules
        val blockedAppsJson = prefs.getString("blocked_apps", "[]")
        if (blockedAppsJson != null && blockedAppsJson != "[]") {
            try {
                val blockedAppsArray = JSONArray(blockedAppsJson)
                for (i in 0 until blockedAppsArray.length()) {
                    val appObj = blockedAppsArray.getJSONObject(i)
                    if (appObj.getString("packageName") == packageName) {
                        // If specifically unblocked, don't block
                        if (!appObj.optBoolean("isBlocked", true)) continue

                        val scheduleIdsArray = appObj.optJSONArray("scheduleIds")
                        if (scheduleIdsArray == null || scheduleIdsArray.length() == 0) {
                            // No schedules means block 24/7 as long as isBlocked is true
                            return true
                        }

                        // Check schedules
                        val scheduleIds = mutableListOf<String>()
                        for (j in 0 until scheduleIdsArray.length()) {
                            scheduleIds.add(scheduleIdsArray.getString(j))
                        }
                        
                        if (isWithinAnySchedule(scheduleIds, prefs)) return true
                    }
                }
            } catch (e: Exception) {
                Log.e("NotificationListener", "Error parsing blocked apps", e)
            }
        }

        return false
    }

    private fun isWithinAnySchedule(scheduleIds: List<String>, prefs: android.content.SharedPreferences): Boolean {
        val schedulesJson = prefs.getString("schedules", "[]") ?: "[]"
        if (schedulesJson == "[]") return false

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

            for (i in 0 until schedulesArray.length()) {
                val schedule = schedulesArray.getJSONObject(i)
                val id = schedule.getString("id")
                
                if (scheduleIds.contains(id) && schedule.optBoolean("isEnabled", false)) {
                    val daysArray = schedule.getJSONArray("daysOfWeek")
                    var dayMatch = false
                    for (j in 0 until daysArray.length()) {
                        if (daysArray.getInt(j) == dayOfWeek) {
                            dayMatch = true
                            break
                        }
                    }

                    if (dayMatch) {
                        val startTime = schedule.getJSONObject("startTime")
                        val endTime = schedule.getJSONObject("endTime")
                        val startMinutes = startTime.getInt("hour") * 60 + startTime.getInt("minute")
                        val endMinutes = endTime.getInt("hour") * 60 + endTime.getInt("minute")

                        // Check if current time is within this schedule
                        val isWithinTime = if (endMinutes < startMinutes) {
                            // Schedule crosses midnight
                            currentMinutes >= startMinutes || currentMinutes <= endMinutes
                        } else {
                            currentMinutes in startMinutes..endMinutes
                        }

                        if (isWithinTime) return true
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("NotificationListener", "Error checking schedules", e)
        }
        return false
    }
}
