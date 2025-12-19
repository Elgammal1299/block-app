package com.example.block_app.ui

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import com.example.block_app.R
import com.example.block_app.services.AppBlockerAccessibilityService
import com.example.block_app.utils.AppInfoUtil
import kotlin.random.Random

class BlockOverlayActivity : Activity() {

    companion object {
        private const val REQUEST_UNLOCK = 1001
        private const val PREFS_NAME = "app_blocker"
    }

    private lateinit var blockedPackage: String
    private lateinit var appInfoUtil: AppInfoUtil
    private var blockReason: String? = null
    private var blockScreenStyle: String = "classic"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make fullscreen
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )

        // Keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Show over other apps and prevent dismissing
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)

        setContentView(R.layout.activity_block_overlay)

        appInfoUtil = AppInfoUtil(this)
        blockedPackage = intent.getStringExtra("blocked_package") ?: ""
        blockReason = intent.getStringExtra("block_reason")

        // Read selected block screen style from shared preferences
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        blockScreenStyle = prefs.getString("block_screen_style", "classic") ?: "classic"

        setupUI()
    }

    private fun setupUI() {
        val titleText = findViewById<TextView>(R.id.tv_blocked_title)
        val messageText = findViewById<TextView>(R.id.tv_blocked_message)
        val motivationalText = findViewById<TextView>(R.id.tv_motivational_quote)
        val unlockButton = findViewById<Button>(R.id.btn_unlock)
        val homeButton = findViewById<Button>(R.id.btn_go_home)

        // Set app name
        val appName = appInfoUtil.getAppName(blockedPackage)

        // Configure UI based on selected style and block reason
        when (blockScreenStyle) {
            "minimal" -> {
                // Minimal style: short message, no motivational quote, no unlock button
                if (blockReason == "usage_limit_reached") {
                    titleText.text = "تم استهلاك الحد اليومي"
                    messageText.text = "لقد استخدمت الحد اليومي لتطبيق \"$appName\". جرّب غدًا مرة أخرى."
                } else {
                    titleText.text = "التطبيق \"$appName\" محظور الآن"
                    messageText.text = "هذا التطبيق محظور في وقت التركيز."
                }
                motivationalText.visibility = View.GONE
                unlockButton.visibility = View.GONE
            }
            "hardcore" -> {
                // Hardcore style: strong message + motivational quote, no unlock button
                if (blockReason == "usage_limit_reached") {
                    titleText.text = "كفاية كده!"
                    messageText.text = "لقد تجاوزت وقتك المسموح لتطبيق \"$appName\" اليوم. ركّز في أهدافك الآن."
                } else {
                    titleText.text = "لا تضعف الآن!"
                    messageText.text = "\"$appName\" محظور لأن وقتك أهم من أي إلهاء."
                }
                motivationalText.text = getRandomMotivationalQuote()
                unlockButton.visibility = View.GONE
            }
            else -> {
                // Classic style (default): original behavior with unlock and quote
                if (blockReason == "usage_limit_reached") {
                    titleText.text = "Daily Limit Reached!"
                    messageText.text = "You've used your daily limit for \"$appName\". Come back tomorrow!"
                } else {
                    titleText.text = "\"$appName\" is Blocked"
                    messageText.text = "This app is blocked during your focus time."
                }
                motivationalText.text = getRandomMotivationalQuote()
                unlockButton.visibility = View.VISIBLE
            }
        }

        // Unlock button
        unlockButton.setOnClickListener {
            launchUnlockChallenge()
        }

        // Home button
        homeButton.setOnClickListener {
            goHome()
        }
    }

    private fun getRandomMotivationalQuote(): String {
        val quotes = listOf(
            "Focus on your goal! Your success depends on your concentration now.",
            "Every minute you waste now, you'll regret later.",
            "Studying now is better than regret tomorrow.",
            "You are stronger than your temptations! Focus.",
            "Do you want success? Stay away from distractions.",
            "Your future is being made now, not on social media.",
            "Focus now = Success tomorrow.",
            "A few minutes of focus is better than hours of distraction.",
            "Your dreams are waiting for you, don't waste your time.",
            "Make today a productive day!",
            "Success doesn't come by chance, but by focus and work.",
            "Every attempt to open this app is a missed opportunity for progress.",
            "You don't need this app now, you need to focus.",
            "Remember why you started! Don't give up now.",
            "Your future is more important than any notification.",
            "Time waits for no one, invest it wisely.",
            "You are building your future now, brick by brick.",
            "Sacrifice today means success tomorrow.",
            "Don't let your phone steal your dreams.",
            "True strength is in self-control."
        )
        return quotes[Random.nextInt(quotes.size)]
    }

    private fun launchUnlockChallenge() {
        val intent = Intent(this, UnlockChallengeActivity::class.java)
        intent.putExtra("blocked_package", blockedPackage)
        startActivityForResult(intent, REQUEST_UNLOCK)
    }

    private fun goHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_UNLOCK) {
            if (resultCode == RESULT_OK) {
                // Challenge passed - set temporary unlock
                val unlockDuration = data?.getIntExtra("unlock_duration", 5) ?: 5
                AppBlockerAccessibilityService.setTemporaryUnlock(this, unlockDuration)

                // Show success message (optional)
                // Toast.makeText(this, "Unlocked for $unlockDuration minutes", Toast.LENGTH_SHORT).show()

                finish()
            }
            // If challenge failed, stay on this screen
        }
    }

    override fun onBackPressed() {
        // Prevent back button - go to home instead
        goHome()
    }

    // Prevent the activity from being destroyed when the user leaves
    override fun onPause() {
        super.onPause()
        // If the block reason is usage limit, we should finish the activity
        // because the AppMonitorService will re-launch it if user tries to open the app again
        if (blockReason == "usage_limit_reached") {
            finish()
        }
        // For other block reasons (schedules, focus mode), don't finish
    }
}
