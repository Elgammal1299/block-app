package com.example.block_app.utils

import android.content.Context
import android.util.Log
import androidx.work.*
import com.example.block_app.workers.DailySnapshotWorker
import java.util.concurrent.TimeUnit

/**
 * Utility class for managing background work with WorkManager
 */
class WorkManagerUtil(private val context: Context) {

    companion object {
        private const val TAG = "WorkManagerUtil"
    }

    /**
     * Schedule daily snapshot work
     * Runs once per day at midnight
     */
    fun scheduleDailySnapshot() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
            .setRequiresBatteryNotLow(false)
            .build()

        // Calculate time until next midnight
        val currentTime = System.currentTimeMillis()
        val nextMidnight = getNextMidnight(currentTime)
        val initialDelay = nextMidnight - currentTime

        val dailyWorkRequest = PeriodicWorkRequestBuilder<DailySnapshotWorker>(
            1, TimeUnit.DAYS
        )
            .setConstraints(constraints)
            .setInitialDelay(initialDelay, TimeUnit.MILLISECONDS)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            DailySnapshotWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP, // Keep existing if already scheduled
            dailyWorkRequest
        )

        Log.d(TAG, "Daily snapshot work scheduled. Next run in ${initialDelay / 1000 / 60} minutes")
    }

    /**
     * Cancel daily snapshot work
     */
    fun cancelDailySnapshot() {
        WorkManager.getInstance(context).cancelUniqueWork(DailySnapshotWorker.WORK_NAME)
        Log.d(TAG, "Daily snapshot work cancelled")
    }

    /**
     * Run snapshot work immediately (for testing)
     */
    fun runSnapshotNow() {
        val oneTimeWorkRequest = OneTimeWorkRequestBuilder<DailySnapshotWorker>()
            .build()

        WorkManager.getInstance(context).enqueue(oneTimeWorkRequest)
        Log.d(TAG, "Running snapshot work immediately")
    }

    /**
     * Calculate time until next midnight
     */
    private fun getNextMidnight(currentTime: Long): Long {
        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = currentTime

        // Move to next day
        calendar.add(java.util.Calendar.DAY_OF_MONTH, 1)

        // Set to midnight
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)

        return calendar.timeInMillis
    }
}
