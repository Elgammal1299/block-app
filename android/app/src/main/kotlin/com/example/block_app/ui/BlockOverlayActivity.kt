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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make fullscreen
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )

        // Keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_block_overlay)

        appInfoUtil = AppInfoUtil(this)
        blockedPackage = intent.getStringExtra("blocked_package") ?: ""

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
        titleText.text = "\"$appName\" is Blocked"
        messageText.text = "This app is blocked during your focus time."

        // Set random motivational quote
        motivationalText.text = getRandomMotivationalQuote()

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
        // Don't finish here, let the user choose
    }
}
