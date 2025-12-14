package com.example.block_app.workers

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.example.block_app.utils.UsageStatsUtil
import org.json.JSONArray
import org.json.JSONObject

/**
 * Worker that saves daily usage snapshot in the background
 * Runs once per day to capture app usage statistics
 */
class DailySnapshotWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private const val TAG = "DailySnapshotWorker"
        const val WORK_NAME = "daily_snapshot_work"
    }

    override fun doWork(): Result {
        return try {
            Log.d(TAG, "Starting daily snapshot work...")

            // Get usage stats for today
            val usageStatsUtil = UsageStatsUtil(applicationContext as android.app.Activity)
            val now = System.currentTimeMillis()
            val startOfDay = getStartOfDay(now)

            val usageStats = usageStatsUtil.getAppUsageStats(startOfDay, now)

            // Save to SharedPreferences as backup
            saveSnapshotToPrefs(usageStats, getTodayDateKey())

            Log.d(TAG, "Daily snapshot saved successfully. ${usageStats.size} apps recorded.")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving daily snapshot: ${e.message}", e)
            Result.failure()
        }
    }

    private fun saveSnapshotToPrefs(usageStats: Map<String, Long>, dateKey: String) {
        val prefs = applicationContext.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
        val editor = prefs.edit()

        // Create JSON array of usage data
        val jsonArray = JSONArray()
        for ((packageName, usageTime) in usageStats) {
            val jsonObject = JSONObject()
            jsonObject.put("packageName", packageName)
            jsonObject.put("usageTime", usageTime)
            jsonObject.put("date", dateKey)
            jsonArray.put(jsonObject)
        }

        // Save with date key
        editor.putString("usage_snapshot_$dateKey", jsonArray.toString())
        editor.apply()

        Log.d(TAG, "Snapshot saved to SharedPreferences for date: $dateKey")
    }

    private fun getStartOfDay(timestamp: Long): Long {
        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = timestamp
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    private fun getTodayDateKey(): String {
        val calendar = java.util.Calendar.getInstance()
        val year = calendar.get(java.util.Calendar.YEAR)
        val month = calendar.get(java.util.Calendar.MONTH) + 1
        val day = calendar.get(java.util.Calendar.DAY_OF_MONTH)
        return String.format("%04d-%02d-%02d", year, month, day)
    }
}
