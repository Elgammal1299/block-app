package com.example.block_app.services

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

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

        // 2. Check General Blocked Apps (Scheduled or Manual)
        // Note: Actual schedule logic is complex in Kotlin, but we can check if the app is in the general blocked list
        // and if ANY schedule is currently active.
        // For simplicity and to match the user's request, we'll check the blocked_apps list.
        
        val blockedAppsJson = prefs.getString("blocked_apps", null)
        if (blockedAppsJson != null) {
            try {
                // It could be a simple list of package names or a complex JSON object
                if (blockedAppsJson.startsWith("[")) {
                    val apps = JSONArray(blockedAppsJson)
                    for (i in 0 until apps.length()) {
                        if (apps.getString(i) == packageName) return true
                    }
                } else {
                    val appsObj = JSONObject(blockedAppsJson)
                    if (appsObj.has(packageName)) return true
                }
            } catch (e: Exception) {
                // Maybe it's a StringSet?
                val blockedAppsSet = prefs.getStringSet("blocked_apps", null)
                if (blockedAppsSet?.contains(packageName) == true) return true
            }
        }

        return false
    }
}
