package com.anchorage.anchorage

import android.app.AlertDialog
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.CountDownTimer
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import kotlin.random.Random

class OverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isVpnBlockedMode = false
    private var countdownTimer: CountDownTimer? = null
    private var selectedEmotion: String? = null

    private val handler = Handler(Looper.getMainLooper())
    private val autoDismissRunner = Runnable {
        Log.w(TAG, "Auto-dismiss: 120s with no interaction, navigating to ANCHORAGE home")
        bringAnchorageToForeground()
        removeOverlayView()
        if (!isVpnBlockedMode) AppGuardService.overlayDismissed = true
        launchAnchorage(navigateTo = NAVIGATE_HOME)
        stopSelf()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val domain = intent?.getStringExtra(EXTRA_DOMAIN)
        if (domain != null) {
            // VPN-blocked mode
            if (overlayView != null && isVpnBlockedMode) {
                overlayView?.findViewById<TextView>(R.id.tv_domain_msg)?.text =
                    "$domain is blocked\nANCHORAGE is protecting you"
                applyVpnPrompt()
                resetAutoDismiss()
            } else if (overlayView == null) {
                isVpnBlockedMode = true
                showVpnBlockedOverlay(domain)
            }
        } else {
            // App-guard mode
            val appName = intent?.getStringExtra(EXTRA_APP_NAME) ?: "this app"
            if (overlayView != null && !isVpnBlockedMode) {
                overlayView?.findViewById<TextView>(R.id.tv_subtitle)?.text =
                    "You opened $appName\nANCHORAGE intercepted it"
                resetAutoDismiss()
            } else if (overlayView == null) {
                isVpnBlockedMode = false
                showAppGuardOverlay(appName)
            }
        }
        return START_NOT_STICKY
    }

    // ── Emotional states and suggestions ──────────────────────────────────────

    private val suggestions = mapOf(
        "Bored" to listOf(
            "Go for a 10-minute walk. No destination needed.",
            "Make a cup of tea or coffee. Focus on the process.",
            "Text someone you have not spoken to this week.",
            "Do 20 push-ups, sit-ups, or stretches.",
            "Pick up a book or article and read for 5 minutes.",
            "Tidy one small area. A desk, a shelf, a drawer.",
            "Put on a playlist and listen to 3 songs start to finish."
        ),
        "Stressed" to listOf(
            "Step outside for 2 minutes. Just breathe the air.",
            "Write down 3 things stressing you. Get them out of your head.",
            "Put on a song you like at full volume.",
            "Splash cold water on your face and wrists.",
            "Drop your shoulders. Unclench your jaw. Take 3 slow breaths.",
            "Set a timer for 10 minutes and do nothing. Actually nothing.",
            "Call someone and talk about anything other than what is stressing you."
        ),
        "Lonely" to listOf(
            "Call or text one person right now. Anyone.",
            "Go somewhere with other people. A cafe, a shop, a park.",
            "Write in your journal about what you are missing.",
            "Listen to a podcast or audiobook. A human voice helps.",
            "Message an old friend you have lost touch with.",
            "Go for a walk in a busy area. Being around people counts."
        ),
        "Tired" to listOf(
            "Set a 20-minute nap timer and actually lie down.",
            "Go to bed. Put the phone in another room.",
            "Have a glass of water and a small snack.",
            "Do a gentle 5-minute stretch.",
            "Splash cold water on your face to reset."
        ),
        "Anxious" to listOf(
            "Write down the worry. Getting it on paper takes it out of the loop.",
            "Walk around the block once. Movement interrupts the spiral.",
            "Call someone you trust and tell them you are feeling on edge.",
            "Hold something cold. Ice cube, cold drink, frozen peas.",
            "Reorganise something. A drawer, your desk, your bag. Small control helps.",
            "Make a cup of tea. Focus on every step of making it."
        ),
        "Down" to listOf(
            "Have a shower or change your clothes. A small physical reset.",
            "Go outside for even 2 minutes. Daylight matters.",
            "Write one thing you did today, no matter how small.",
            "Listen to music that matches your mood. Not to fix it, just to be with it.",
            "Text someone \"Hey, how are you?\" Connection helps even when you initiate it.",
            "Eat something. Low blood sugar makes everything harder."
        ),
        "Angry" to listOf(
            "Walk fast for 10 minutes. Let your body burn it off.",
            "Cold water on your face and wrists.",
            "Write down what you are angry about. Do not send it to anyone.",
            "Do push-ups, squats, or anything physical until you feel the edge drop.",
            "Put on loud music. Scream along if you need to."
        ),
        "Aroused" to listOf(
            "Set a 20-minute timer. Do literally anything else until it goes off.",
            "Get out of the room you are in. Change your physical environment.",
            "Do something physical. Walk, exercise, cold shower.",
            "Call or text your partner or a friend.",
            "Go outside. Fresh air and a change of scenery."
        ),
        "Numb" to listOf(
            "Hold something cold. An ice cube or a cold glass.",
            "Step outside barefoot for 30 seconds. Feel the ground.",
            "Splash cold water on your face.",
            "Do 10 jumping jacks or star jumps. Shock the system gently.",
            "Put on a song that used to make you feel something.",
            "Eat something with a strong flavour. Lemon, chilli, mint."
        ),
        "Rewarding Myself" to listOf(
            "You had a good day. Protect it. Choose a reward that matches your values.",
            "What would Future You thank you for doing right now?",
            "Go out for food. Treat yourself to something you actually enjoy.",
            "Call someone and share the good news.",
            "Write down what went well today. Savour it properly."
        ),
        "Not sure" to listOf(
            "Go for a walk. Movement helps when you cannot name what you feel.",
            "Write down whatever comes to mind. No filter, just get it out.",
            "Call or text someone. Connection can help you figure out what you need.",
            "Do something physical. Walk, stretch, cold water on your face.",
            "Step outside for 2 minutes. A change of environment can bring clarity."
        )
    )

    // ── ACT prompts per emotional state ───────────────────────────────────────

    private data class ActPrompt(val title: String, val body: String)

    private val fullPhrasePool = listOf(
        "You can choose what happens next.",
        "Notice it. You don't have to follow it.",
        "This feeling will pass. What matters to you right now?",
        "There is space between this feeling and what you do next.",
        "You don't have to act on it."
    )

    private val notSurePhrasePool = listOf(
        "You can choose what happens next.",
        "This feeling will pass. What matters to you right now?"
    )

    private val emotionOpenings = mapOf(
        "Bored" to "Boredom brought you here.",
        "Stressed" to "Stress brought you here.",
        "Lonely" to "Loneliness brought you here.",
        "Tired" to "Being tired brought you here.",
        "Anxious" to "Anxiety brought you here.",
        "Down" to "Feeling down brought you here.",
        "Angry" to "Anger brought you here.",
        "Aroused" to "You noticed feeling aroused.",
        "Numb" to "You noticed feeling numb.",
        "Rewarding Myself" to "You noticed the desire to reward yourself.",
        "Not sure" to "You paused to check in. That matters."
    )

    private fun getPromptForEmotion(emotion: String): ActPrompt {
        val opening = emotionOpenings[emotion] ?: "You paused to check in. That matters."
        val isNotSure = emotion == "Not sure"
        val pool = if (isNotSure) notSurePhrasePool else fullPhrasePool
        val phrase = pool[Random.nextInt(pool.size)]
        return ActPrompt(opening, phrase)
    }

    private fun getVpnPrompt(): ActPrompt {
        val phrase = fullPhrasePool[Random.nextInt(fullPhrasePool.size)]
        return ActPrompt("You paused to check in. That matters.", phrase)
    }

    // ── App-guard overlay (with emotion selection) ────────────────────────────

    private fun showAppGuardOverlay(appName: String) {
        Log.d(TAG, "showAppGuardOverlay: '$appName'")
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_intercept, null)

        overlayView?.findViewById<TextView>(R.id.tv_subtitle)?.text =
            "You opened $appName\nANCHORAGE intercepted it"

        setupEmotionGrid()
        setupActionButtons()

        addOverlayView()
    }

    private fun setupEmotionGrid() {
        val emotionIds = mapOf(
            R.id.emo_bored to "Bored",
            R.id.emo_stressed to "Stressed",
            R.id.emo_lonely to "Lonely",
            R.id.emo_tired to "Tired",
            R.id.emo_anxious to "Anxious",
            R.id.emo_down to "Down",
            R.id.emo_angry to "Angry",
            R.id.emo_aroused to "Aroused",
            R.id.emo_numb to "Numb",
            R.id.emo_rewarding to "Rewarding Myself",
            R.id.emo_not_sure to "Not sure"
        )

        for ((viewId, emotion) in emotionIds) {
            overlayView?.findViewById<TextView>(viewId)?.setOnClickListener {
                onEmotionSelected(emotion)
            }
        }
    }

    private fun onEmotionSelected(emotion: String) {
        selectedEmotion = emotion
        Log.d(TAG, "Emotion selected: $emotion")

        // Transition to phase 2
        overlayView?.findViewById<View>(R.id.phase_emotion)?.visibility = View.GONE
        overlayView?.findViewById<View>(R.id.phase_prompt)?.visibility = View.VISIBLE

        // Set ACT prompt
        val prompt = getPromptForEmotion(emotion)
        overlayView?.findViewById<TextView>(R.id.tv_prompt_title)?.text = prompt.title
        overlayView?.findViewById<TextView>(R.id.tv_prompt_body)?.text = prompt.body

        // Set 2 random suggestions
        val emotionSuggestions = suggestions[emotion] ?: emptyList()
        val picked = emotionSuggestions.shuffled().take(2)
        overlayView?.findViewById<TextView>(R.id.tv_suggestion_1)?.text =
            if (picked.isNotEmpty()) picked[0] else ""
        overlayView?.findViewById<TextView>(R.id.tv_suggestion_2)?.text =
            if (picked.size > 1) picked[1] else ""
        overlayView?.findViewById<TextView>(R.id.tv_suggestion_2)?.visibility =
            if (picked.size > 1) View.VISIBLE else View.GONE

        // Setup exercise button
        overlayView?.findViewById<Button>(R.id.btn_exercise)?.setOnClickListener {
            showExerciseChooser()
        }

        // Start countdown
        startCountdown()
    }

    private fun startCountdown() {
        overlayView?.findViewById<View>(R.id.action_buttons)?.visibility = View.GONE
        overlayView?.findViewById<TextView>(R.id.tv_timer_label)?.text = "Take this time to pause"

        countdownTimer?.cancel()
        countdownTimer = object : CountDownTimer(TIMER_DURATION_MS, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = (millisUntilFinished / 1000).toInt() + 1
                overlayView?.findViewById<TextView>(R.id.tv_timer)?.text = seconds.toString()
            }

            override fun onFinish() {
                overlayView?.findViewById<TextView>(R.id.tv_timer)?.text = "0"
                overlayView?.findViewById<TextView>(R.id.tv_timer_label)?.text = "You can continue now"
                overlayView?.findViewById<View>(R.id.action_buttons)?.visibility = View.VISIBLE
            }
        }.start()
    }

    private fun showExerciseChooser() {
        // Inflate the exercise chooser as a secondary overlay (dialog-style)
        val dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_exercise_chooser, null)

        val dialogParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        windowManager?.addView(dialogView, dialogParams)

        data class ExerciseEntry(val route: String, val key: String)

        val exercises = mapOf(
            R.id.btn_ex_breathing to ExerciseEntry("exercise/box-breathing", "box_breathing"),
            R.id.btn_ex_phys_sigh to ExerciseEntry("exercise/physiological-sigh", "physiological_sigh"),
            R.id.btn_ex_grounding to ExerciseEntry("exercise/grounding", "grounding"),
            R.id.btn_ex_urge_surfing to ExerciseEntry("exercise/urge-surfing", "urge_surfing"),
            R.id.btn_ex_body_scan to ExerciseEntry("exercise/body-scan", "body_scan")
        )

        for ((btnId, entry) in exercises) {
            dialogView.findViewById<Button>(btnId)?.setOnClickListener {
                Log.d(TAG, "Exercise selected: ${entry.key}")
                try { windowManager?.removeView(dialogView) } catch (_: Exception) {}
                dismiss()
                launchAnchorage(
                    navigateTo = entry.route,
                    extraEmotion = selectedEmotion,
                    extraExercise = entry.key
                )
            }
        }

        dialogView.findViewById<Button>(R.id.btn_ex_cancel)?.setOnClickListener {
            try { windowManager?.removeView(dialogView) } catch (_: Exception) {}
        }
    }

    private fun setupActionButtons() {
        overlayView?.findViewById<Button>(R.id.btn_reflect)?.setOnClickListener {
            Log.d(TAG, "btn_reflect tapped")
            bringAnchorageToForeground()
            dismiss()
            launchAnchorage(navigateTo = NAVIGATE_REFLECT, extraEmotion = selectedEmotion)
        }

        overlayView?.findViewById<Button>(R.id.btn_stay_anchored)?.setOnClickListener {
            Log.d(TAG, "btn_stay_anchored tapped")
            bringAnchorageToForeground()
            dismiss()
            launchAnchorage(navigateTo = null, extraEmotion = selectedEmotion)
        }

        overlayView?.findViewById<Button>(R.id.btn_white_flag)?.setOnClickListener {
            Log.d(TAG, "btn_white_flag tapped")
            dismiss()
        }
    }

    // ── VPN-blocked overlay (unchanged flow, no emotion selection) ─────────

    private fun showVpnBlockedOverlay(domain: String) {
        Log.d(TAG, "showVpnBlockedOverlay: '$domain'")
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_vpn_blocked, null)

        overlayView?.findViewById<TextView>(R.id.tv_domain_msg)?.text =
            "$domain is blocked\nANCHORAGE is protecting you"

        applyVpnPrompt()

        overlayView?.findViewById<Button>(R.id.btn_vpn_reflect)?.setOnClickListener {
            Log.d(TAG, "btn_vpn_reflect tapped")
            dismissVpn()
            launchAnchorage(navigateTo = NAVIGATE_REFLECT)
        }

        overlayView?.findViewById<Button>(R.id.btn_vpn_go_back)?.setOnClickListener {
            Log.d(TAG, "btn_vpn_go_back tapped")
            dismissVpn()
        }

        addOverlayView()
    }

    private fun applyVpnPrompt() {
        val prompt = getVpnPrompt()
        overlayView?.findViewById<TextView>(R.id.tv_vpn_prompt_title)?.text = prompt.title
        overlayView?.findViewById<TextView>(R.id.tv_vpn_prompt_body)?.text = prompt.body
    }

    // ── Shared helpers ────────────────────────────────────────────────────────

    private fun bringAnchorageToForeground() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        }
        if (intent != null) {
            startActivity(intent)
            Log.d(TAG, "bringAnchorageToForeground: launched ANCHORAGE to prevent guarded app re-entry")
        } else {
            Log.w(TAG, "bringAnchorageToForeground: getLaunchIntentForPackage returned null")
        }
    }

    private fun addOverlayView() {
        val params = buildLayoutParams()
        try {
            windowManager?.addView(overlayView, params)
            Log.d(TAG, "addOverlayView: added (vpnMode=$isVpnBlockedMode)")
            scheduleAutoDismiss()
        } catch (e: Exception) {
            Log.e(TAG, "addOverlayView: failed to add view", e)
            if (!isVpnBlockedMode) AppGuardService.overlayDismissed = true
            overlayView = null
            stopSelf()
        }
    }

    private fun scheduleAutoDismiss() {
        handler.removeCallbacks(autoDismissRunner)
        handler.postDelayed(autoDismissRunner, AUTO_DISMISS_MS)
    }

    private fun resetAutoDismiss() {
        handler.removeCallbacks(autoDismissRunner)
        handler.postDelayed(autoDismissRunner, AUTO_DISMISS_MS)
    }

    private fun dismiss() {
        countdownTimer?.cancel()
        handler.removeCallbacks(autoDismissRunner)
        AppGuardService.overlayDismissed = true
        Log.d(TAG, "dismiss: signaled AppGuardService.overlayDismissed=true, emotion=$selectedEmotion")
        removeOverlayView()
        stopSelf()
    }

    private fun dismissVpn() {
        handler.removeCallbacks(autoDismissRunner)
        Log.d(TAG, "dismissVpn: removing VPN overlay")
        removeOverlayView()
        stopSelf()
    }

    private fun removeOverlayView() {
        try {
            overlayView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {
            Log.e(TAG, "removeOverlayView: ${e.message}")
        }
        overlayView = null
    }

    private fun buildLayoutParams(): WindowManager.LayoutParams {
        val navBarHeight = getNavigationBarHeight()
        val screenHeight = resources.displayMetrics.heightPixels
        val overlayHeight = screenHeight - navBarHeight

        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            overlayHeight,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP
        }
    }

    private fun getNavigationBarHeight(): Int {
        val resourceId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
        return if (resourceId > 0) resources.getDimensionPixelSize(resourceId) else 0
    }

    private fun launchAnchorage(
        navigateTo: String?,
        extraEmotion: String? = null,
        extraExercise: String? = null
    ) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (navigateTo != null) putExtra(EXTRA_NAVIGATE_TO, navigateTo)
            if (extraEmotion != null) putExtra(EXTRA_EMOTION, extraEmotion)
            if (extraExercise != null) putExtra(EXTRA_EXERCISE, extraExercise)
        }
        startActivity(intent)
        Log.d(TAG, "launchAnchorage: navigateTo=$navigateTo emotion=$extraEmotion exercise=$extraExercise")
    }

    override fun onDestroy() {
        countdownTimer?.cancel()
        handler.removeCallbacks(autoDismissRunner)

        if (overlayView != null) {
            if (!isVpnBlockedMode && !isBeingAutoDismissed) {
                AppGuardService.overlayDismissed = true
            }
            try {
                overlayView?.let { windowManager?.removeView(it) }
            } catch (e: Exception) {
                Log.e(TAG, "onDestroy: removeView failed: ${e.message}")
            }
            overlayView = null
        }

        isBeingAutoDismissed = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val EXTRA_APP_NAME    = "OVERLAY_APP_NAME"
        const val EXTRA_DOMAIN      = "OVERLAY_DOMAIN"
        const val EXTRA_NAVIGATE_TO = "NAVIGATE_TO"
        const val EXTRA_EMOTION     = "OVERLAY_EMOTION"
        const val EXTRA_EXERCISE    = "OVERLAY_EXERCISE"
        const val NAVIGATE_HOME     = "home"
        const val NAVIGATE_REFLECT  = "reflect"

        private const val AUTO_DISMISS_MS = 120_000L
        private const val TIMER_DURATION_MS = 60_000L

        @Volatile var isBeingAutoDismissed = false

        private const val TAG = "AnchorageOverlay"
    }
}
