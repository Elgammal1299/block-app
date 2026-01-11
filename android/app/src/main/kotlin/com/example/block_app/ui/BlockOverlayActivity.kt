package com.example.block_app.ui

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
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

        // Configuration to show over lockscreen and keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)

        setContentView(R.layout.activity_block_overlay)

        appInfoUtil = AppInfoUtil(this)
        blockedPackage = intent.getStringExtra("blocked_package") ?: ""
        blockReason = intent.getStringExtra("block_reason")

        setupUI()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        blockedPackage = intent?.getStringExtra("blocked_package") ?: ""
        blockReason = intent?.getStringExtra("block_reason")
        setupUI()
    }

    private fun setupUI() {
        val titleText = findViewById<TextView>(R.id.tv_blocked_title)
        val messageText = findViewById<TextView>(R.id.tv_blocked_message)
        val statsText = findViewById<TextView>(R.id.tv_stats)
        val motivationalText = findViewById<TextView>(R.id.tv_motivational_quote)
        val appIconView = findViewById<ImageView>(R.id.iv_blocked_app_icon)
        val homeButton = findViewById<Button>(R.id.btn_go_home)
        val closeX = findViewById<TextView>(R.id.btn_close_x)

        // 1. Get and set the icon of the app being blocked
        val appIcon = appInfoUtil.getAppIcon(blockedPackage)
        if (appIcon != null) {
            appIconView.setImageDrawable(appIcon)
        } else {
            appIconView.setImageResource(android.R.drawable.sym_def_app_icon)
        }

        // 2. Get app name for the message
        val appName = appInfoUtil.getAppName(blockedPackage)

        // 3. Set Arabic Texts
        titleText.text = "تم حظره بواسطة AppBlock"
        messageText.text = "تم حظر $appName بواسطة الحظر السريع"

        // 4. Update stats (Today vs Total)
        val todayCount = getTodayBlockCount(blockedPackage)
        val totalCount = getTotalBlockCount(blockedPackage)
        statsText.text = "${todayCount}× اليوم | ${totalCount}× الإجمالي"

        // 5. Random Wisdom
        motivationalText.text = getRandomWisdom()

        // 6. Navigation
        homeButton.setOnClickListener { goHome() }
        closeX.setOnClickListener { goHome() }
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
            val blockedAppsJson = prefs.getString("blocked_apps", "[]") ?: "[]"
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
        val wisdoms = listOf(
            "\"العزيمة هي ما تجعلك تبدأ، والانضباط هو ما يبقيك مستمراً.\"",
            "\"الوقت هو العملة الوحيدة التي تملكها، فاحذر من إنفاقها فيما لا ينفع.\"",
            "\"النجاح لا يأتي من ما تفعله من حين لآخر، بل من ما تفعله باستمرار.\"",
            "\"ركز على أهدافك، فالأماكن المزدحمة لا تصنع القادة.\"",
            "\"إن لم تخطط للنجاح، فأنت تخطط للفشل.\"",
            "\"تذكّر دائماً لماذا بدأت، ولا تستسلم للتوافه.\"",
            "\"قوة الإرادة هي الفرق بين الشخص الذي ينجز والذي يتمنى.\"",
            "\"كل دقيقة تقضيها في تطبيق محظور هي دقيقة ضائعة من مستقبلك.\"",
            "\"أنت من تتحكم في هاتفك، لا تجعل هاتفك يتحكم فيك.\"",
            "\"كن النسخة الأفضل من نفسك اليوم.\""
        )
        return wisdoms[Random.nextInt(wisdoms.size)]
    }

    private fun goHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onBackPressed() {
        goHome()
    }

    override fun onPause() {
        super.onPause()
    }
}
