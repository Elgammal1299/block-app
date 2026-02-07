package com.example.block_app.utils

import android.app.ActivityManager
import android.content.Context
import android.util.Log

/**
 * Utility to check if a service is currently running
 * Prevents double initialization of services
 */
object ServiceRunningUtil {

    private const val TAG = "ServiceRunningUtil"

    /**
     * Check if a service is currently running
     * @param context Application context
     * @param serviceClass The service class to check
     * @return true if service is running, false otherwise
     */
    fun isServiceRunning(context: Context, serviceClass: Class<*>): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        if (activityManager != null) {
            try {
                val runningServices = activityManager.getRunningServices(Integer.MAX_VALUE)
                for (serviceInfo in runningServices) {
                    if (serviceClass.name == serviceInfo.service.className) {
                        Log.d(TAG, "${serviceClass.simpleName} is running")
                        return true
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking if service is running: ${e.message}", e)
            }
        }
        Log.d(TAG, "${serviceClass.simpleName} is NOT running")
        return false
    }

    /**
     * Log current running services (debug only)
     */
    fun logRunningServices(context: Context) {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        if (activityManager != null) {
            try {
                val runningServices = activityManager.getRunningServices(Integer.MAX_VALUE)
                Log.d(TAG, "=== Running Services (${runningServices.size}) ===")
                for (serviceInfo in runningServices) {
                    Log.d(TAG, "Service: ${serviceInfo.service.className}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error logging services: ${e.message}")
            }
        }
    }
}
