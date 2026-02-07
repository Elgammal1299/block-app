package com.example.block_app.ui

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import android.util.Log
import com.example.block_app.R
import com.example.block_app.utils.AppInfoUtil
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import kotlin.random.Random

class BlockOverlayActivity : Activity() {

    companion object {
        private const val PREFS_NAME = "app_blocker"
        private const val TRACKING_PREFS = "usage_tracking"
    }

    private lateinit var blockedPackage: String
    private lateinit var appInfoUtil: AppInfoUtil
    private var blockReason: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("BlockOverlay", "🎬 onCreate() called")

        // Configuration to show over lockscreen and keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)

        setContentView(R.layout.activity_block_overlay)
        Log.d("BlockOverlay", "✅ Layout set")

        appInfoUtil = AppInfoUtil(this)
        blockedPackage = intent.getStringExtra("blocked_package") ?: ""
        blockReason = intent.getStringExtra("block_reason")
        
        Log.e("BlockOverlay", "🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥")
        Log.e("BlockOverlay", "🟥 OVERLAY SHOWN FOR: $blockedPackage")
        Log.e("BlockOverlay", "🟥 Reason: $blockReason")
        Log.e("BlockOverlay", "🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥")

        setupUI()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Log.d("BlockOverlay", "🔄 onNewIntent() called")
        setIntent(intent)
        blockedPackage = intent?.getStringExtra("blocked_package") ?: ""
        blockReason = intent?.getStringExtra("block_reason")
        Log.d("BlockOverlay", "📋 New blocked app: $blockedPackage, Reason: $blockReason")
        setupUI()
    }

    private fun setupUI() {
        Log.d("BlockOverlay", "🎨 Setting up UI...")
        val rootLayout = findViewById<android.widget.RelativeLayout>(R.id.block_root_layout)
        val titleText = findViewById<TextView>(R.id.tv_blocked_title)
        val messageText = findViewById<TextView>(R.id.tv_blocked_message)
        val statsText = findViewById<TextView>(R.id.tv_stats)
        val motivationalText = findViewById<TextView>(R.id.tv_motivational_quote)
        val appIconView = findViewById<ImageView>(R.id.iv_blocked_app_icon)
        val homeButton = findViewById<Button>(R.id.btn_go_home)
        val closeX = findViewById<TextView>(R.id.btn_close_x)

        // Set close button color to primary app color
        try {
            val primaryColorStr = getString(R.string.color_primary)
            val primaryColorInt = android.graphics.Color.parseColor(primaryColorStr)
            homeButton.backgroundTintList = android.content.res.ColorStateList.valueOf(primaryColorInt)
        } catch (e: Exception) {
            Log.e("BlockOverlay", "Failed to apply primary color", e)
        }

        // 0. Load Customization
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val customColor = prefs.getString("block_screen_color", "#050A1A") ?: "#050A1A"
        val customQuote = prefs.getString("block_screen_quote", "") ?: ""

        try {
            val colorInt = android.graphics.Color.parseColor(customColor)
            rootLayout.setBackgroundColor(colorInt)
            
            // Adjust text colors based on background brightness
            val isLight = isColorLight(colorInt)
            val textColor = if (isLight) android.graphics.Color.BLACK else android.graphics.Color.WHITE
            val subTextColor = if (isLight) android.graphics.Color.argb(200, 0, 0, 0) else android.graphics.Color.argb(200, 255, 255, 255)

            titleText.setTextColor(textColor)
            messageText.setTextColor(textColor)
            statsText.setTextColor(subTextColor)
            motivationalText.setTextColor(subTextColor)
            closeX.setTextColor(textColor)

            homeButton.setTextColor(android.graphics.Color.WHITE)
            
        } catch (e: Exception) {
            Log.e("BlockOverlay", "Failed to parse color: $customColor", e)
        }

        // 1. Get and set the icon of the app being blocked
        val appIcon = appInfoUtil.getAppIcon(blockedPackage)
        if (appIcon != null) {
            appIconView.setImageDrawable(appIcon)
        } else {
            appIconView.setImageResource(android.R.drawable.sym_def_app_icon)
        }

        // 2. Get app name for the message
        val appName = appInfoUtil.getAppName(blockedPackage)

        // 3. Set Localized Texts
        titleText.text = getString(R.string.blocked_app_title)
        messageText.text = getString(R.string.blocked_app_message, appName)

        // 4. Update stats (Today vs Total)
        val todayCount = getTodayBlockCount(blockedPackage)
        val totalCount = getTotalBlockCount(blockedPackage)
        
        val todayStr = getString(R.string.stats_today, todayCount)
        val totalStr = getString(R.string.stats_total, totalCount)
        statsText.text = "$todayStr | $totalStr"

        // 5. Custom or Random Wisdom
        if (customQuote.isNotEmpty()) {
            motivationalText.text = customQuote
        } else {
            motivationalText.text = getRandomWisdom()
        }

        // 6. Navigation
        homeButton.setOnClickListener { goHome() }
        closeX.setOnClickListener { goHome() }
    }

    private fun adjustColorBrightness(color: Int, factor: Float): Int {
        val hsv = FloatArray(3)
        android.graphics.Color.colorToHSV(color, hsv)
        hsv[2] *= factor
        return android.graphics.Color.HSVToColor(hsv)
    }

    private fun isColorLight(color: Int): Boolean {
        val darkness = 1 - (0.299 * android.graphics.Color.red(color) + 
                          0.587 * android.graphics.Color.green(color) + 
                          0.114 * android.graphics.Color.blue(color)) / 255
        return darkness < 0.5
    }

    private fun getTodayBlockCount(packageName: String): Int {
        return try {
            val prefs = getSharedPreferences(TRACKING_PREFS, Context.MODE_PRIVATE)
            val calendar = Calendar.getInstance()
            val today = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
            val storageKey = "block_attempts_$today"
            
            val dataJson = prefs.getString(storageKey, "{}")
            val json = JSONObject(dataJson ?: "{}")
            // If it's the first time recorded today, we return 1 (the current attempt)
            json.optInt(packageName, 1)
        } catch (e: Exception) { 1 }
    }

    private fun getTotalBlockCount(packageName: String): Int {
        return try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val blockedAppsJson = try {
                prefs.getString("blocked_apps", "[]") ?: "[]"
            } catch (e: ClassCastException) {
                "[]"
            }
            val array = JSONArray(blockedAppsJson)
            
            for (i in 0 until array.length()) {
                val app = array.getJSONObject(i)
                if (app.getString("packageName") == packageName) {
                    return app.optInt("blockAttempts", 1)
                }
            }
            1
        } catch (e: Exception) { 1 }
    }

    private fun getRandomWisdom(): String {
        return try {
            val wisdoms = resources.getStringArray(R.array.motivational_quotes)
            if (wisdoms.isNotEmpty()) {
                wisdoms[Random.nextInt(wisdoms.size)]
            } else {
                ""
            }
        } catch (e: Exception) {
            ""
        }
    }

    private fun goHome() {
        Log.d("BlockOverlay", "🏠 Going home...")
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        Log.d("BlockOverlay", "✅ Home intent started")
        finish()
    }

    override fun onBackPressed() {
        goHome()
    }

    override fun onPause() {
        super.onPause()
    }
}
