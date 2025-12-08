package com.example.block_app.ui

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import com.example.block_app.R
import kotlin.random.Random

class UnlockChallengeActivity : Activity() {

    companion object {
        private const val PREFS_NAME = "app_blocker"
        private const val KEY_CHALLENGE_TYPE = "unlock_challenge_type"
        private const val DEFAULT_UNLOCK_DURATION = 5 // minutes
    }

    private var challengeType: String = "math"
    private var correctAnswer: String = ""
    private var countDownTimer: CountDownTimer? = null

    private lateinit var titleText: TextView
    private lateinit var questionText: TextView
    private lateinit var answerInput: EditText
    private lateinit var submitButton: Button
    private lateinit var cancelButton: Button
    private lateinit var timerText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_unlock_challenge)

        // Get challenge type from preferences
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        challengeType = prefs.getString(KEY_CHALLENGE_TYPE, "math") ?: "math"

        initializeViews()
        setupChallenge()
    }

    private fun initializeViews() {
        titleText = findViewById(R.id.tv_challenge_title)
        questionText = findViewById(R.id.tv_challenge_question)
        answerInput = findViewById(R.id.et_answer)
        submitButton = findViewById(R.id.btn_submit)
        cancelButton = findViewById(R.id.btn_cancel)
        timerText = findViewById(R.id.tv_timer)

        submitButton.setOnClickListener {
            checkAnswer()
        }

        cancelButton.setOnClickListener {
            setResult(RESULT_CANCELED)
            finish()
        }
    }

    private fun setupChallenge() {
        when (challengeType) {
            "math" -> setupMathChallenge()
            "typing" -> setupTypingChallenge()
            "timer" -> setupTimerChallenge()
            else -> setupMathChallenge()
        }
    }

    private fun setupMathChallenge() {
        titleText.text = "Math Challenge"

        // Generate random math problem
        val num1 = Random.nextInt(10, 50)
        val num2 = Random.nextInt(10, 50)
        val operation = Random.nextInt(0, 2) // 0 = addition, 1 = multiplication

        if (operation == 0) {
            questionText.text = "What is $num1 + $num2 ?"
            correctAnswer = (num1 + num2).toString()
        } else {
            questionText.text = "What is $num1 × $num2 ?"
            correctAnswer = (num1 * num2).toString()
        }

        answerInput.hint = "Enter your answer"
        answerInput.visibility = View.VISIBLE
        timerText.visibility = View.GONE
    }

    private fun setupTypingChallenge() {
        titleText.text = "Typing Challenge"

        val sentences = listOf(
            "I am focused on my goals and nothing will distract me.",
            "Success requires sacrifice and I choose to sacrifice distractions.",
            "My future is more valuable than temporary entertainment.",
            "I control my time, my time does not control me.",
            "Every moment of focus brings me closer to my dreams."
        )

        correctAnswer = sentences[Random.nextInt(sentences.size)]
        questionText.text = "Type this sentence exactly:\n\n\"$correctAnswer\""

        answerInput.hint = "Type here..."
        answerInput.visibility = View.VISIBLE
        timerText.visibility = View.GONE
    }

    private fun setupTimerChallenge() {
        titleText.text = "Timer Challenge"
        questionText.text = "Please wait before unlocking..."

        answerInput.visibility = View.GONE
        submitButton.isEnabled = false
        timerText.visibility = View.VISIBLE

        val timerDuration = 30 * 1000L // 30 seconds

        countDownTimer = object : CountDownTimer(timerDuration, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsRemaining = (millisUntilFinished / 1000).toInt()
                timerText.text = "Wait $secondsRemaining seconds..."
            }

            override fun onFinish() {
                timerText.text = "You can now unlock!"
                submitButton.isEnabled = true
                submitButton.text = "Unlock"
            }
        }.start()
    }

    private fun checkAnswer() {
        if (challengeType == "timer") {
            // Timer challenge passed
            unlockSuccess()
            return
        }

        val userAnswer = answerInput.text.toString().trim()

        if (userAnswer.isEmpty()) {
            Toast.makeText(this, "Please enter an answer", Toast.LENGTH_SHORT).show()
            return
        }

        // Check answer
        val isCorrect = when (challengeType) {
            "math" -> userAnswer == correctAnswer
            "typing" -> userAnswer == correctAnswer
            else -> false
        }

        if (isCorrect) {
            unlockSuccess()
        } else {
            Toast.makeText(this, "Wrong answer! Try again.", Toast.LENGTH_SHORT).show()
            answerInput.text.clear()

            // For typing challenge, don't regenerate - let them try again
            // For math challenge, optionally regenerate
            if (challengeType == "math") {
                setupMathChallenge()
            }
        }
    }

    private fun unlockSuccess() {
        val resultIntent = Intent().apply {
            putExtra("unlock_duration", DEFAULT_UNLOCK_DURATION)
        }
        setResult(RESULT_OK, resultIntent)
        Toast.makeText(this, "Unlocked for $DEFAULT_UNLOCK_DURATION minutes", Toast.LENGTH_SHORT).show()
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }

    override fun onBackPressed() {
        // Allow back button to cancel
        setResult(RESULT_CANCELED)
        finish()
    }
}
