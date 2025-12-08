package com.example.block_app.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.block_app.ui.BlockOverlayActivity
import java.util.*

class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerAccessibility"
        private const val PREFS_NAME = "app_blocker"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_SCHEDULES = "schedules"
        private const val KEY_TEMP_UNLOCK = "temp_unlock_until"

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

            // Check if app is blocked and within schedule
            if (isAppBlocked(packageName) && isWithinSchedule()) {
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

    private fun isAppBlocked(packageName: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val blockedApps = prefs.getStringSet(KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
        return blockedApps.contains(packageName)
    }

    private fun isWithinSchedule(): Boolean {
        // Get current time
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

        // TODO: Read schedules from SharedPreferences and check if current time matches
        // For now, return true (always block if app is in blocked list)
        return true
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

    private fun launchBlockOverlay(packageName: String) {
        val intent = Intent(this, BlockOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            putExtra("blocked_package", packageName)
        }
        startActivity(intent)
    }
}
