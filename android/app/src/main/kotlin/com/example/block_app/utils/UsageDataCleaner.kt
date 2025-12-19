package com.example.block_app.utils

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONObject

/**
 * Utility class for cleaning usage data
 * Removes our own app from stored statistics
 */
object UsageDataCleaner {
    private const val TAG = "UsageDataCleaner"
    private const val PREFS_NAME = "usage_tracking"
    private const val KEY_DAILY_USAGE = "daily_usage_"
    private const val OUR_PACKAGE = "com.example.block_app"

    /**
     * Remove our own app from all stored daily usage data
     */
    fun cleanAllStoredData(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        var cleanedCount = 0

        // Get all keys from SharedPreferences
        val allKeys = prefs.all.keys

        // Iterate through all daily usage keys
        for (key in allKeys) {
            if (key.startsWith(KEY_DAILY_USAGE)) {
                val dataJson = prefs.getString(key, "{}")
                if (!dataJson.isNullOrEmpty() && dataJson != "{}") {
                    try {
                        val usageData = JSONObject(dataJson)

                        // Check if our app is in the data
                        if (usageData.has(OUR_PACKAGE)) {
                            // Remove our app
                            usageData.remove(OUR_PACKAGE)

                            // Save cleaned data back
                            editor.putString(key, usageData.toString())
                            cleanedCount++

                            Log.d(TAG, "Cleaned $OUR_PACKAGE from $key")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error cleaning data for $key: ${e.message}", e)
                    }
                }
            }
        }

        if (cleanedCount > 0) {
            editor.apply()
            Log.i(TAG, "Successfully cleaned $cleanedCount daily usage entries")
        } else {
            Log.i(TAG, "No data to clean - our app was not found in any entries")
        }
    }

    /**
     * Remove our own app from a specific date's usage data
     */
    fun cleanDateData(context: Context, dateKey: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val storageKey = KEY_DAILY_USAGE + dateKey
        val dataJson = prefs.getString(storageKey, "{}")

        if (!dataJson.isNullOrEmpty() && dataJson != "{}") {
            try {
                val usageData = JSONObject(dataJson)

                if (usageData.has(OUR_PACKAGE)) {
                    usageData.remove(OUR_PACKAGE)

                    prefs.edit()
                        .putString(storageKey, usageData.toString())
                        .apply()

                    Log.d(TAG, "Cleaned $OUR_PACKAGE from $dateKey")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error cleaning data for $dateKey: ${e.message}", e)
            }
        }
    }
}
