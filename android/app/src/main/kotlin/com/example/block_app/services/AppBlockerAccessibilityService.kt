package com.example.block_app.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.block_app.ui.BlockOverlayActivity
import com.example.block_app.utils.AdaptiveThrottleManager
import org.json.JSONArray
import org.json.JSONObject
import java.util.*
import kotlinx.coroutines.*
import android.content.SharedPreferences
import android.app.usage.UsageStatsManager
import android.os.PowerManager
import android.content.BroadcastReceiver
import android.content.IntentFilter

class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerAccessibility"
        private const val PREFS_NAME = "app_blocker"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_SCHEDULES = "schedules"
        private const val KEY_USAGE_LIMITS = "usage_limits"
        private const val KEY_TEMP_UNLOCK = "temp_unlock_until"
        private const val KEY_DYNAMIC_BLOCKS = "dynamic_blocked_apps" // Persistent usage-limit blocks
        private const val KEY_FOCUS_SESSION_PACKAGES = "focus_session_packages"
        private const val KEY_FOCUS_SESSION_END = "focus_session_end_time"

        // Method to set temporary unlock (called from BlockOverlayActivity)
        fun setTemporaryUnlock(context: Context, durationMinutes: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val unlockUntil = System.currentTimeMillis() + (durationMinutes * 60 * 1000)
            prefs.edit().putLong(KEY_TEMP_UNLOCK, unlockUntil).apply()
            Log.d(TAG, "Temporary unlock set for $durationMinutes minutes")
        }

        // ✨ Phase 4: Singleton pattern for MethodChannel access
        var instance: AppBlockerAccessibilityService? = null
            private set
    }

    // --- Data Classes for Performance (Pre-parsed Cache) ---
    private data class BlockConfig(
        val packageName: String,
        var isBlocked: Boolean,
        var blockAttempts: Int,
        val scheduleIds: List<String>
    )

    private data class ScheduleConfig(
        val id: String,
        val isEnabled: Boolean,
        val daysOfWeek: List<Int>,
        val startTimeMinutes: Int, // Total minutes from midnight
        val endTimeMinutes: Int
    )

    private data class UsageLimitConfig(
        val packageName: String,
        val isEnabled: Boolean,
        val dailyLimitMillis: Long
    )

    private var currentSessionPackage: String? = null
    private var sessionStartTime: Long = 0
    private var screenOffReceiver: BroadcastReceiver? = null
    
    // Cache for settings - Typed for zero-parsing access
    private var cachedBlockedApps = mutableMapOf<String, BlockConfig>()
    private var cachedSchedules = mutableMapOf<String, ScheduleConfig>()
    private var cachedUsageLimits = mutableMapOf<String, UsageLimitConfig>()
    private var cachedDynamicBlocks = mutableMapOf<String, BlockConfig>()
    
    // New caches for usage and focus
    private var cachedTodayUsage = mutableMapOf<String, Long>()
    private var cachedFocusPackages = mutableSetOf<String>()
    private var cachedFocusEndTime = 0L
    
    private var lastCacheRefreshTime = 0L

    // Coroutine scope for background tasks
    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var usageMonitorJob: Job? = null
    private var prefs: SharedPreferences? = null

    private val prefChangeListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        Log.e(TAG, "🔔 SharedPreferences changed: $key")
        Log.e(TAG, "🔄 Refreshing cache due to preference change...")
        refreshCache()
    }

    private var lastOverlayTime = 0L
    private var lastTargetPackage: String? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service Created")
        
        // ✨ Phase 4 Fix: Early initialization
        if (prefs == null) {
            prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            Log.d(TAG, "SharedPreferences initialized in onCreate")
        }
    }

    override fun onServiceConnected() {
        instance = this // Set instance for external access
        super.onServiceConnected()
        // 🔥 CRITICAL LOG - لو ما شفت الرسالة دي → الخدمة مش شغالة!
        Log.e(TAG, "🔥🔥🔥 *** ACCESSIBILITY SERVICE CONNECTED *** 🔥🔥🔥")
        Log.e(TAG, "🔥 Service is RUNNING and ACTIVE - Ready to block apps!")
        Log.d(TAG, "🟢 Accessibility Service Connected - Performance Optimized")

        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs?.registerOnSharedPreferenceChangeListener(prefChangeListener)

        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        info.notificationTimeout = 100
        serviceInfo = info

        // Refresh cache initially
        Log.d(TAG, "📚 Refreshing cache on service connection...")
        refreshCache()

        // Register receiver for screen events to handle session closing
        registerScreenReceiver()
        
        // Notify UsageTrackingService to yield/pause
        disableLegacyTracking()

        // Start background usage monitor
        startUsageMonitor()
        
        Log.d(TAG, "✅ Service fully initialized and ready to block apps")
    }
    
    override fun onDestroy() {
        instance = null // Clear instance
        super.onDestroy()
        prefs?.unregisterOnSharedPreferenceChangeListener(prefChangeListener)
        unregisterScreenReceiver()
        // Close any open session
        endCurrentSession()
        // Re-enable legacy tracking service as fallback
        enableLegacyTracking()
        // Cancel background tasks
        serviceScope.cancel()
    }

    fun refreshCache() { // Made public
        serviceScope.launch(Dispatchers.IO) {
            try {
                val p = prefs
                if (p == null) {
                    Log.e(TAG, "❌ CRITICAL: prefs is NULL! Cannot load blocked apps!")
                    return@launch
                }
                
                Log.d(TAG, "🔄 Starting cache refresh...")
                
                // 1. Blocked Apps
                val blockedAppsJson = try {
                    p.getString(KEY_BLOCKED_APPS, "[]") ?: "[]"
                } catch (e: ClassCastException) {
                    // Handle migration from old format (StringSet)
                    "[]"
                }
                
                Log.e(TAG, "📥 Raw JSON from SharedPrefs (Length: ${blockedAppsJson.length}): ${blockedAppsJson.take(500)}")
                
                if (blockedAppsJson == "[]") {
                    Log.w(TAG, "⚠️ Blocked apps JSON is EMPTY! Checking if KEY_BLOCKED_APPS exists...")
                    if (!p.contains(KEY_BLOCKED_APPS)) {
                        Log.e(TAG, "❌ KEY_BLOCKED_APPS ($KEY_BLOCKED_APPS) does NOT exist in prefs!")
                    }
                }
                
                val blockedAppsArray = JSONArray(blockedAppsJson)
                val newBlockedApps = mutableMapOf<String, BlockConfig>()
                for (i in 0 until blockedAppsArray.length()) {
                    val app = blockedAppsArray.getJSONObject(i)
                    val pkg = app.getString("packageName")
                    val sIds = mutableListOf<String>()
                    val sArray = app.optJSONArray("scheduleIds")
                    if (sArray != null) {
                        for (j in 0 until sArray.length()) sIds.add(sArray.getString(j))
                    }
                    newBlockedApps[pkg] = BlockConfig(
                        packageName = pkg,
                        isBlocked = app.optBoolean("isBlocked", true), // ✨ Phase 4 Fix: Default to true
                        blockAttempts = app.optInt("blockAttempts", 0),
                        scheduleIds = sIds
                    )
                }
                Log.d(TAG, "✅ Loaded ${newBlockedApps.size} blocked apps from cache")
                for ((pkg, config) in newBlockedApps) {
                    Log.d(TAG, "  - $pkg (blocked: ${config.isBlocked}, schedules: ${config.scheduleIds})")
                }

                // 2. Schedules
                val schedulesJson = p.getString(KEY_SCHEDULES, "[]") ?: "[]"
                val schedulesArray = JSONArray(schedulesJson)
                val newSchedules = mutableMapOf<String, ScheduleConfig>()
                for (i in 0 until schedulesArray.length()) {
                    val schedule = schedulesArray.getJSONObject(i)
                    val id = schedule.getString("id")
                    
                    val days = mutableListOf<Int>()
                    val daysArray = schedule.getJSONArray("daysOfWeek")
                    for (j in 0 until daysArray.length()) days.add(daysArray.getInt(j))
                    
                    val startTime = schedule.getJSONObject("startTime")
                    val endTime = schedule.getJSONObject("endTime")
                    
                    newSchedules[id] = ScheduleConfig(
                        id = id,
                        isEnabled = schedule.getBoolean("isEnabled"),
                        daysOfWeek = days,
                        startTimeMinutes = startTime.getInt("hour") * 60 + startTime.getInt("minute"),
                        endTimeMinutes = endTime.getInt("hour") * 60 + endTime.getInt("minute")
                    )
                }

                // 3. Usage Limits
                val usageLimitsJson = p.getString(KEY_USAGE_LIMITS, "[]") ?: "[]"
                val limitsArray = JSONArray(usageLimitsJson)
                val newUsageLimits = mutableMapOf<String, UsageLimitConfig>()
                for (i in 0 until limitsArray.length()) {
                    val limit = limitsArray.getJSONObject(i)
                    val pkg = limit.getString("packageName")
                    newUsageLimits[pkg] = UsageLimitConfig(
                        packageName = pkg,
                        isEnabled = limit.optBoolean("isEnabled", true),
                        dailyLimitMillis = limit.getInt("dailyLimitMinutes") * 60 * 1000L
                    )
                }

                // 4. ✨ Dynamic Blocks
                val dynamicJson = p.getString(KEY_DYNAMIC_BLOCKS, "{}") ?: "{}"
                val dynamicObj = JSONObject(dynamicJson)
                val newDynamicBlocks = mutableMapOf<String, BlockConfig>()
                val keys = dynamicObj.keys()
                while (keys.hasNext()) {
                    val pkg = keys.next()
                    val app = dynamicObj.getJSONObject(pkg)
                    val sIds = mutableListOf<String>()
                    val sArray = app.optJSONArray("scheduleIds")
                    if (sArray != null) {
                        for (j in 0 until sArray.length()) sIds.add(sArray.getString(j))
                    }
                    newDynamicBlocks[pkg] = BlockConfig(
                        packageName = pkg,
                        isBlocked = app.optBoolean("isBlocked", true), // ✨ Phase 4 Fix: Default to true
                        blockAttempts = app.optInt("blockAttempts", 0),
                        scheduleIds = sIds
                    )
                }

                // Update memory cache
                synchronized(this@AppBlockerAccessibilityService) {
                    cachedBlockedApps = newBlockedApps
                    cachedSchedules = newSchedules
                    cachedUsageLimits = newUsageLimits
                    cachedDynamicBlocks = newDynamicBlocks
                    
                    // ✨ IMPORTANT: Merge persistent dynamic blocks into cachedBlockedApps
                    // This ensures that apps blocked by usage limits are actually blocked
                    for (pkg in newDynamicBlocks.keys) {
                        val dynamicApp = newDynamicBlocks[pkg] ?: continue
                        if (dynamicApp.isBlocked) {
                            // If it's already in official, merge schedule IDs if needed, 
                            // otherwise override with dynamic block status
                            val officialApp = newBlockedApps[pkg]
                            if (officialApp != null) {
                                newBlockedApps[pkg] = officialApp.copy(
                                    isBlocked = true,
                                    blockAttempts = maxOf(officialApp.blockAttempts, dynamicApp.blockAttempts)
                                )
                            } else {
                                newBlockedApps[pkg] = dynamicApp
                            }
                        }
                    }
                }
                
                lastCacheRefreshTime = System.currentTimeMillis()
                Log.e(TAG, "🚨 *** CACHE REFRESHED *** 🚨")
                Log.e(TAG, "✅ Total blocked apps loaded: ${newBlockedApps.size}")
                for ((pkg, config) in newBlockedApps) {
                    Log.e(TAG, "   ✓ $pkg (blocked: ${config.isBlocked}, schedules: ${config.scheduleIds})")
                }
                synchronized(this@AppBlockerAccessibilityService) {
                    Log.e(TAG, "📋 Final Cache State: cachedBlockedApps.size = ${cachedBlockedApps.size}")
                }
                Log.e(TAG, "   Ready to use for blocking decisions")
                Log.d(TAG, "Cache refreshed and pre-parsed into objects")
                
                refreshUsageAndFocusCache()
            } catch (e: Exception) {
                Log.e(TAG, "Error refreshing cache: ${e.message}")
            }
        }
    }

    private fun refreshUsageAndFocusCache() {
        try {
            // 1. Refresh Today's Usage Cache
            val trackingPrefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val calendar = Calendar.getInstance()
            val today = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
            val storageKey = "daily_usage_$today"
            
            val dataJson = trackingPrefs.getString(storageKey, "{}")
            val jsonObject = JSONObject(dataJson ?: "{}")
            val newUsage = mutableMapOf<String, Long>()
            val keys = jsonObject.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                newUsage[key] = jsonObject.optLong(key, 0)
            }
            
            // 2. Refresh Focus Session Cache
            val mainPrefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val focusJson = mainPrefs.getString(KEY_FOCUS_SESSION_PACKAGES, null)
            val focusEndTime = mainPrefs.getLong(KEY_FOCUS_SESSION_END, 0)
            val newFocusPackages = mutableSetOf<String>()
            
            if (focusJson != null && System.currentTimeMillis() <= focusEndTime) {
                val array = JSONArray(focusJson)
                for (i in 0 until array.length()) {
                    newFocusPackages.add(array.getString(i))
                }
            }

            synchronized(this) {
                cachedTodayUsage = newUsage
                cachedFocusPackages = newFocusPackages
                cachedFocusEndTime = focusEndTime
            }
            Log.v(TAG, "Usage/Focus cache updated: ${newUsage.size} usage entries, ${newFocusPackages.size} focus apps")
        } catch (e: Exception) {
            Log.e(TAG, "Error refreshing usage/focus cache: ${e.message}")
        }
    }

    private fun startUsageMonitor() {
        if (usageMonitorJob?.isActive == true) return
        
        usageMonitorJob?.cancel()
        Log.d(TAG, "Starting Usage Monitor Loop (1s interval) - Heartbeat Enabled")
        usageMonitorJob = serviceScope.launch {
            var heartbeatCount = 0
            while (isActive) {
                try {
                    val currentPackage = currentSessionPackage
                    if (currentPackage != null) {
                        // Periodic Heartbeat Log (Every 10 seconds to avoid spam)
                        if (heartbeatCount++ % 10 == 0) {
                            Log.v(TAG, "Monitor Heartbeat: Tracking $currentPackage")
                        }

                        val isLimitReached = hasReachedUsageLimit(currentPackage)
                        val isFocusBlocked = isInActiveFocusSession(currentPackage)
                        val isScheduleBlocked = shouldBlockApp(currentPackage)

                        if (isLimitReached || isFocusBlocked || isScheduleBlocked) {
                            if (!isTemporarilyUnlocked()) {
                                val reason = when {
                                    isFocusBlocked -> "focus_mode"
                                    isLimitReached -> "usage_limit_reached"
                                    else -> "schedule"
                                }

                                withContext(Dispatchers.Main) {
                                    handleBlockAction(currentPackage, reason, source = "Heartbeat")
                                }
                                
                                // Delay slightly to allow UI transition and avoid CPU thrashing
                                delay(500)
                            }
                        }
                    } else {
                        heartbeatCount = 0 // Reset when no app open
                    }
                    delay(1000)
                } catch (e: Exception) {
                    if (e !is CancellationException) {
                        Log.e(TAG, "Error in usage monitor loop: ${e.message}")
                    }
                }
            }
        }
    }

    private fun registerScreenReceiver() {
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        
        screenOffReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        Log.d(TAG, "Screen OFF - Finding and closing active session")
                        endCurrentSession()
                    }
                    Intent.ACTION_USER_PRESENT, Intent.ACTION_SCREEN_ON -> {
                        Log.d(TAG, "Screen ON - Ready for next app")
                    }
                }
            }
        }
        registerReceiver(screenOffReceiver, filter)
    }

    private fun unregisterScreenReceiver() {
        screenOffReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering receiver: ${e.message}")
            }
        }
    }
    
    // Disable legacy UsageTrackingService writing to prevent double counting
    private fun disableLegacyTracking() {
         getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("is_accessibility_tracking_active", true)
            .apply()
    }

    // Enable legacy UsageTrackingService writing as fallback
    private fun enableLegacyTracking() {
         getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("is_accessibility_tracking_active", false)
            .apply()
    }

    // Cache for default launcher package
    private var defaultLauncherPackage: String? = null

    // Logic to update Launcher package (call periodically or on demand)
    private fun updateDefaultLauncher() {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val resolveInfo = packageManager.resolveActivity(intent, 0)
        defaultLauncherPackage = resolveInfo?.activityInfo?.packageName
    }

    // Packages that should be ignored (Transparent/Interruption)
    // Switching to these does NOT end the current session
    private fun isInterruption(packageName: String): Boolean {
        return packageName == "com.android.systemui" ||
               packageName == "android" ||
               packageName.contains("inputmethod") || // Keyboards
               packageName == "com.google.android.inputmethod.latin" ||
               packageName == "com.samsung.android.honeyboard" ||
               packageName == "com.google.android.packageinstaller" ||
               packageName == "com.android.permissioncontroller"
    }

    // Packages that stop usage but are not counted as usage themselves (e.g. Launcher)
    private fun isStopper(packageName: String): Boolean {
        if (defaultLauncherPackage == null) {
            updateDefaultLauncher()
        }
        
        return packageName == defaultLauncherPackage || 
               packageName == "com.miui.home" || 
               packageName == "com.sec.android.app.launcher" || 
               packageName == "com.google.android.apps.nexuslauncher" ||
               packageName.contains("launcher")
    }

    private fun handleAppChange(newPackage: String) {
        // If it's the same app, ignore
        if (newPackage == currentSessionPackage) {
            return
        }

        // 1. Check if it's an INTERRUPTION (SystemUI, Keyboard, etc.)
        // If so, IGNORE completely. Let the current session continue running.
        if (isInterruption(newPackage)) {
            Log.v(TAG, "Ignoring interruption package: $newPackage")
            return
        }

        // 2. Whatever it is (App or Launcher), the previous session MUST end now
        endCurrentSession()

        // 3. Check if it's a STOPPER (Launcher/Home)
        // If so, stop tracking. Don't start a new session.
        if (isStopper(newPackage)) {
            Log.d(TAG, "Stopper package detected (Home): $newPackage")
            return
        }

        // 4. It's a valid new app -> Start new session
        startNewSession(newPackage)
        
        // 5. Ensure monitor is running
        startUsageMonitor()
    }

    private fun startNewSession(packageName: String) {
        currentSessionPackage = packageName
        sessionStartTime = System.currentTimeMillis()
        
        // Note: We do NOT increment open count here anymore (Waiting for Debounce validation)
        
        // Save current session to shared prefs for real-time UI "Active Now" status
        saveCurrentSessionToPrefs(packageName, sessionStartTime)
        
        Log.d(TAG, "Started session for $packageName")
    }

    private fun endCurrentSession() {
        val packageName = currentSessionPackage ?: return
        val startTime = sessionStartTime
        
        if (startTime == 0L) return

        val endTime = System.currentTimeMillis()
        val duration = endTime - startTime

        // ✨ DEBOUNCE LOGIC: Only count sessions longer than 3 seconds
        // This filters out accidental clicks and system noise blips (e.g. 411ms sessions)
        if (duration > 3000) {
            // 🚀 RACE CONDITION FIX: Update MEMORY cache immediately
            // This stops the monitor loop (1s heartbeat) from seeing the 'stale' usage
            // while the asynchronous updateDailyUsage (I/O) is still processing.
            synchronized(this) {
                val currentStored = cachedTodayUsage[packageName] ?: 0L
                cachedTodayUsage[packageName] = currentStored + duration
            }
            
            // Valid Session -> Save Usage (Async I/O)
            updateDailyUsage(packageName, duration)
            
            // Valid Session -> Increment Open Count
            trackSessionOpen(packageName, startTime)
            
            Log.d(TAG, "Ended session for $packageName: ${duration}ms (Valid)")
        } else {
            Log.d(TAG, "Discarded short session for $packageName: ${duration}ms (< 3s)")
        }

        currentSessionPackage = null
        sessionStartTime = 0
        
        // Clear current session from prefs
        clearCurrentSessionFromPrefs()
    }

    // --- Persistence Methods (Matching UsageTrackingService logic) ---

    private fun updateDailyUsage(packageName: String, duration: Long) {
        serviceScope.launch(Dispatchers.IO) {
            try {
                val trackingPrefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
                val calendar = Calendar.getInstance()
                val today = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
                
                val storageKey = "daily_usage_$today"
                val dataJson = trackingPrefs.getString(storageKey, "{}")
                val jsonObject = JSONObject(dataJson ?: "{}")
                
                val currentUsage = jsonObject.optLong(packageName, 0L)
                jsonObject.put(packageName, currentUsage + duration)
                
                trackingPrefs.edit()
                    .putString(storageKey, jsonObject.toString())
                    .putLong("last_update", System.currentTimeMillis())
                    .apply()
                    
            } catch (e: Exception) {
                Log.e(TAG, "Error saving usage: ${e.message}")
            }
        }
    }

    private fun trackSessionOpen(packageName: String, timestamp: Long) {
        serviceScope.launch(Dispatchers.IO) {
            try {
                val trackingPrefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
                val calendar = Calendar.getInstance()
                calendar.timeInMillis = timestamp
                val dateKey = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
                
                val storageKey = "session_count_$dateKey"
                val dataJson = trackingPrefs.getString(storageKey, "{}")
                val jsonObject = JSONObject(dataJson ?: "{}")
                
                val currentCount = jsonObject.optInt(packageName, 0)
                jsonObject.put(packageName, currentCount + 1)
                
                trackingPrefs.edit().putString(storageKey, jsonObject.toString()).apply()
                
            } catch (e: Exception) {
                Log.e(TAG, "Error tracking open count: ${e.message}")
            }
        }
    }
    
    private fun saveCurrentSessionToPrefs(packageName: String, startTime: Long) {
        try {
            val prefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            val sessionsJson = JSONObject()
            sessionsJson.put(packageName, startTime)
            
            prefs.edit().putString("current_sessions", sessionsJson.toString()).apply()
        } catch (e: Exception) {
           Log.e(TAG, "Error saving current session: ${e.message}") 
        }
    }

    private fun clearCurrentSessionFromPrefs() {
         try {
            val prefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
            prefs.edit().putString("current_sessions", "{}").apply()
        } catch (e: Exception) {
           Log.e(TAG, "Error clearing current session: ${e.message}") 
        }
    }

    private var lastEventTime = 0L
    // ⏱ Phase 3 Optimization: Adaptive Throttling based on performance
    // Uses AdaptiveThrottleManager to dynamically adjust:
    // - Excellent FPS (55+): 500ms → responsive
    // - Good FPS (45-55): 800ms → balanced
    // - Poor FPS (<45): 1200ms → conservative
    // - Memory pressure: 1200ms → protect from OOM
    private var lastCheckedPackage: String? = null

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // 🥇 1. Strict Event Filtering: Only listen to WINDOW_STATE_CHANGED
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val currentTime = System.currentTimeMillis()
        val packageName = event.packageName?.toString() ?: ""
        
        // 💓 HEARTBEAT: Update every ~5s to tell the app we are alive and processing events
        if (currentTime % 5000 < 500) {
            prefs?.edit()?.putLong("service_last_seen", currentTime)?.apply()
        }
        
        // 🔵 CRITICAL LOG: Use ERROR level so it shows up even in filtered logs
        Log.e(TAG, "🔵 EVENT: $packageName [${event.eventType}]")
        
        // 🥉 3. Adaptive Debounce: Use performance-based throttle
        val adaptiveDebounceMs = AdaptiveThrottleManager.getAdaptiveThrottleDuration()
        
        // If it's a DIFFERENT package, bypass throttle to be responsive to app switches
        val isDifferentPackage = packageName != lastCheckedPackage
        
        // 🚨 CRITICAL: Update lastCheckedPackage IMMEDIATELY to detect toggle
        lastCheckedPackage = packageName
        
        if (!isDifferentPackage && (currentTime - lastEventTime < adaptiveDebounceMs)) {
            Log.v(TAG, "⏱ Debounce throttled: $packageName (waited: ${currentTime - lastEventTime}ms)")
            return
        }
        
        // Update tracking
        lastEventTime = currentTime

        // Don't block our own app OR let it be counted as usage
        if (packageName == this.packageName) {
            Log.d(TAG, "📱 Our own app detected: $packageName - ending session")
            // If we are showing the blocker, end the session for the previously open app
            endCurrentSession()
            return
        }
        
        // 🟢 4. Filter System Interruptions (Input Methods, Launchers, Permission Dialogs)
        if (isInterruption(packageName) || isStopper(packageName)) {
            Log.v(TAG, "🚫 System interruption/stopper detected: $packageName")
             // Handle stopper logic (End session if home or our app)
             if (isStopper(packageName)) {
                 Log.d(TAG, "🏠 Home/Launcher detected: $packageName - ending session")
                 endCurrentSession()
             }
             return
        }

        // Check if there's a temporary unlock
        if (isTemporarilyUnlocked()) {
            Log.v(TAG, "🔓 App is temporarily unlocked: $packageName")
            return
        }
        
        // 🥈 2. State Guard
        val isSamePackage = !isDifferentPackage
        Log.d(TAG, "✅ Processing package: $packageName (same as last: $isSamePackage)")

        // ✨ NEW: Track App Usage (Source of Truth)
        handleAppChange(packageName)

        // If it's the same package we just checked and authorized, skip heavy blocking checks
        // UNLESS we are at a minute boundary (to catch schedule starts)
        // But for now, let's rely on the Debounce to throttle this.
        
        // Check for block reasons in priority order
        val isInFocus = isInActiveFocusSession(packageName)
        val hasLimitReached = hasReachedUsageLimit(packageName)
        val shouldBlock = shouldBlockApp(packageName)
        
        Log.d(TAG, "🔍 Block checks for $packageName - Focus:$isInFocus, Limit:$hasLimitReached, Schedule:$shouldBlock")
        
        val reason = when {
            isInFocus -> "focus_mode"
            hasLimitReached -> "usage_limit_reached"
            shouldBlock -> "schedule"
            else -> null
        }

        if (reason != null && !isTemporarilyUnlocked()) {
            Log.w(TAG, "🚫 BLOCKING TRIGGERED: $packageName - Reason: $reason")
            handleBlockAction(packageName, reason, source = "AccessibilityEvent")
            lastCheckedPackage = packageName // Update tracking
        } else {
            Log.d(TAG, "✅ ALLOWED: $packageName - No blocking reason")
        }
    }

    /**
     * Centralized blocking logic to prevent loops and race conditions.
     */
    private fun handleBlockAction(packageName: String, reason: String, source: String) {
        val currentTime = System.currentTimeMillis()
        
        // 1. ✨ THROTTLE GUARD: Reduced to 1.5s to allow quick re-blocking if user tries to bypass
        if (packageName == lastTargetPackage && (currentTime - lastOverlayTime < 1500)) {
            Log.v(TAG, " Blocking logic throttled for $packageName ($source) - recently blocked at $lastOverlayTime")
            return
        }

        Log.e(TAG, "🚀 TRIGGERING BLOCK OVERLAY for $packageName (Source: $source)")
    Log.e(TAG, "🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥")
    Log.e(TAG, "🚀 BLOCK TRIGGERED → $packageName")
    Log.e(TAG, "🚀 Reason: $reason | Source: $source")
    Log.e(TAG, "🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥")

        // 2. 🚀 IMMEDIATE STATE UPDATE
        lastTargetPackage = packageName
        lastOverlayTime = currentTime

        // Note: We no longer modify cachedBlockedApps here to prevent apps
        // from staying blocked after being removed from Flutter.
        // Blocking still works via shouldBlockApp(), hasReachedUsageLimit(), 
        // and isInActiveFocusSession() checks.

        Log.w(TAG, "🚫 Block Trigger [$source] for $packageName. Reason: $reason")
        
        // 4. Launch Overlay
        launchBlockOverlay(packageName, reason)
        
        // 6. Persistence: Officially promote and increment count (Background thread)
        incrementBlockAttempts(packageName)
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    private fun shouldBlockApp(packageName: String): Boolean {
        // Check both official blocks and dynamic blocks (usage limit persistent blocks)
        val appConfig = synchronized(this) { 
            cachedBlockedApps[packageName] ?: cachedDynamicBlocks[packageName] 
        }
        
        if (appConfig == null) {
            Log.d(TAG, "🟢 App NOT tracked for blocking: $packageName")
            return false
        }

        if (!appConfig.isBlocked) {
            Log.d(TAG, "🟢 App found in cache but isBlocked is FALSE: $packageName")
            return false
        }

        Log.w(TAG, "🔍 App IS in blocked list and ACTIVE: $packageName (Schedules: ${appConfig.scheduleIds.size})")

        try {
            // If no schedules assigned, block 24/7
            if (appConfig.scheduleIds.isEmpty()) {
                Log.w(TAG, "🔒 BLOCKING: $packageName (blocked 24/7, no schedule)")
                return true
            }

            // Check if current time is within any of the assigned schedules
            val isWithinSchedule = isWithinAnySchedule(appConfig.scheduleIds)
            Log.d(TAG, "📅 Schedule check for $packageName: $isWithinSchedule (schedules: ${appConfig.scheduleIds})")
            
            if (isWithinSchedule) {
                Log.w(TAG, "🔒 BLOCKING: $packageName (within schedule time)")
            } else {
                Log.d(TAG, "✅ ALLOWED: $packageName (outside schedule time)")
            }
            
            return isWithinSchedule
        } catch (e: Exception) {
            Log.e(TAG, "Error checking schedules for $packageName: ${e.message}")
        }

        return false
    }

    private fun isWithinAnySchedule(scheduleIds: List<String>): Boolean {
        try {
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

            // Check each assigned schedule using memory cache
            for (scheduleId in scheduleIds) {
                val schedule = synchronized(this) { cachedSchedules[scheduleId] }
                    ?: continue

                if (schedule.isEnabled) {
                    // Check if today is in the schedule's days
                    if (schedule.daysOfWeek.contains(dayOfWeek)) {
                        val startMinutes = schedule.startTimeMinutes
                        val endMinutes = schedule.endTimeMinutes

                        // Check if current time is within this schedule
                        val isWithinTime = if (endMinutes < startMinutes) {
                            // Schedule crosses midnight
                            currentMinutes >= startMinutes || currentMinutes <= endMinutes
                        } else {
                            currentMinutes in startMinutes..endMinutes
                        }

                        if (isWithinTime) {
                            return true
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking schedules: ${e.message}")
        }

        return false
    }

    private fun isInActiveFocusSession(packageName: String): Boolean {
        val (focusPackages, endTime) = synchronized(this) {
            Pair(cachedFocusPackages, cachedFocusEndTime)
        }

        // Check if session is still active
        if (System.currentTimeMillis() > endTime) {
            return false
        }

        return focusPackages.contains(packageName)
    }

    private fun hasReachedUsageLimit(packageName: String): Boolean {
        val limit = synchronized(this) { cachedUsageLimits[packageName] } ?: return false

        try {
            if (!limit.isEnabled) return false

            val dailyLimitMillis = limit.dailyLimitMillis

            // Get stored usage from cache
            val storedUsage = synchronized(this) {
                cachedTodayUsage[packageName] ?: 0L
            }
            
            // Critical calculation: Stored + Time since session started
            var currentTotalUsage = storedUsage
            if (packageName == currentSessionPackage && sessionStartTime > 0) {
                val sessionDuration = System.currentTimeMillis() - sessionStartTime
                currentTotalUsage += sessionDuration
            }
            
            // Check if limit exceeded
            if (currentTotalUsage >= dailyLimitMillis) {
                Log.w(TAG, "Limit reached for $packageName! ${currentTotalUsage / 1000}s / ${dailyLimitMillis / 1000}s")
                return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in hasReachedUsageLimit: ${e.message}")
        }

        return false
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
        serviceScope.launch(Dispatchers.IO) {
            val p = prefs ?: return@launch
            val blockedAppsJson = p.getString(KEY_BLOCKED_APPS, "[]") ?: "[]"
            val dynamicJson = p.getString(KEY_DYNAMIC_BLOCKS, "{}") ?: "{}"

            try {
                // 1. Update Official List (JSON)
                val blockedAppsArray = JSONArray(blockedAppsJson)
                var foundInOfficial = false
                var updatedAttempts = 0
                var scheduleIds = JSONArray()

                for (i in 0 until blockedAppsArray.length()) {
                    val appObj = blockedAppsArray.getJSONObject(i)
                    if (appObj.getString("packageName") == packageName) {
                        updatedAttempts = appObj.optInt("blockAttempts", 0) + 1
                        appObj.put("blockAttempts", updatedAttempts)
                        appObj.put("isBlocked", true)
                        scheduleIds = appObj.optJSONArray("scheduleIds") ?: JSONArray()
                        foundInOfficial = true
                        break
                    }
                }

                // 2. Update Dynamic List (JSON)
                val dynamicObj = JSONObject(dynamicJson)
                val existingDynamic = dynamicObj.optJSONObject(packageName)
                
                if (existingDynamic != null) {
                    // It's a dynamic block - update it even if not in official list
                    if (!foundInOfficial) {
                        updatedAttempts = existingDynamic.optInt("blockAttempts", 0) + 1
                        scheduleIds = existingDynamic.optJSONArray("scheduleIds") ?: JSONArray()
                    }
                    existingDynamic.put("blockAttempts", updatedAttempts)
                    existingDynamic.put("isBlocked", true)
                    dynamicObj.put(packageName, existingDynamic)
                } else if (foundInOfficial) {
                    // Not in dynamic yet, but in official - create dynamic entry
                    val newDynamic = JSONObject().apply {
                        put("packageName", packageName)
                        put("scheduleIds", scheduleIds)
                        put("blockAttempts", updatedAttempts)
                        put("isBlocked", true)
                    }
                    dynamicObj.put(packageName, newDynamic)
                }

                // If not found in either, this app is officially unblocked. Stop.
                if (!foundInOfficial && existingDynamic == null) {
                    Log.d(TAG, "Not incrementing attempts for $packageName: App is not blocked.")
                    trackDailyBlockAttempt(packageName) 
                    return@launch
                }

                // 3. Save Both
                p.edit().apply {
                    if (foundInOfficial) {
                        putString(KEY_BLOCKED_APPS, blockedAppsArray.toString())
                    }
                    putString(KEY_DYNAMIC_BLOCKS, dynamicObj.toString())
                }.commit()

                // 4. Update Memory Cache (Typed)
                val sIdsRef = mutableListOf<String>()
                for (j in 0 until scheduleIds.length()) sIdsRef.add(scheduleIds.getString(j))
                
                synchronized(this@AppBlockerAccessibilityService) {
                    val config = BlockConfig(
                        packageName = packageName,
                        isBlocked = true,
                        blockAttempts = updatedAttempts,
                        scheduleIds = sIdsRef
                    )
                    cachedBlockedApps[packageName] = config
                }
                
                trackDailyBlockAttempt(packageName)
                Log.d(TAG, "🚀 Session Promoted & Persisted for $packageName (Attempts: $updatedAttempts)")
            } catch (e: Exception) {
                Log.e(TAG, "Error incrementing block attempts: ${e.message}")
            }
        }
    }

    /**
     * ✨ NEW: Track daily block attempts for statistics
     * Similar to session counting in UsageTrackingService
     */
    private fun trackDailyBlockAttempt(packageName: String) {
        serviceScope.launch(Dispatchers.IO) {
            try {
                val trackingPrefs = getSharedPreferences("usage_tracking", Context.MODE_PRIVATE)
                val calendar = Calendar.getInstance()
                val today = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
                
                val storageKey = "block_attempts_$today"
                val existingDataJson = trackingPrefs.getString(storageKey, "{}")
                val blockAttemptsData = JSONObject(existingDataJson ?: "{}")
                
                val currentCount = blockAttemptsData.optInt(packageName, 0)
                blockAttemptsData.put(packageName, currentCount + 1)
                
                trackingPrefs.edit()
                    .putString(storageKey, blockAttemptsData.toString())
                    .apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error tracking daily block attempt: ${e.message}")
            }
        }
    }

    private fun launchBlockOverlay(packageName: String, blockReason: String? = null) {
        Log.w(TAG, "🎬 LAUNCHING BLOCK OVERLAY for: $packageName (Reason: $blockReason)")
        val intent = Intent(this, BlockOverlayActivity::class.java).apply {
            // Using REORDER_TO_FRONT and SINGLE_TOP to bring existing instance to front 
            // instead of recreating and causing flicker
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                     Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                     Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("blocked_package", packageName)
            if (blockReason != null) {
                putExtra("block_reason", blockReason)
            }
        }
        try {
            startActivity(intent)
            Log.d(TAG, "✅ Block overlay activity started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start block overlay: ${e.message}", e)
        }
    }
}
