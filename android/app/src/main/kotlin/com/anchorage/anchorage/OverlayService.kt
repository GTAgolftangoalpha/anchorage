package com.anchorage.anchorage

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
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

    // Auto-dismiss safety net: if user has not interacted within 30 s, remove the overlay
    // and bring ANCHORAGE home to the foreground (prevents user from being stuck on a
    // blank Chrome error page with no easy way out).
    private val handler = Handler(Looper.getMainLooper())
    private val autoDismissRunner = Runnable {
        Log.w(TAG, "Auto-dismiss: 30 s with no interaction — navigating to ANCHORAGE home")
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
                    "$domain is blocked.\nANCHORAGE is protecting you."
                applyVpnPrompt()
                resetAutoDismiss()
                Log.d(TAG, "onStartCommand: updated VPN overlay for '$domain'")
            } else if (overlayView == null) {
                isVpnBlockedMode = true
                showVpnBlockedOverlay(domain)
            }
            // If app-guard overlay is already showing, don't interrupt it
        } else {
            // App-guard mode
            val appName = intent?.getStringExtra(EXTRA_APP_NAME) ?: "this app"
            if (overlayView != null && !isVpnBlockedMode) {
                overlayView?.findViewById<TextView>(R.id.tv_subtitle)?.text =
                    "You opened $appName.\nANCHORAGE intercepted it."
                applyAppGuardPrompt()
                resetAutoDismiss()
                Log.d(TAG, "onStartCommand: updated app-guard overlay for '$appName'")
            } else if (overlayView == null) {
                isVpnBlockedMode = false
                showAppGuardOverlay(appName)
            }
            // If VPN overlay is already showing, don't interrupt it
        }
        return START_NOT_STICKY
    }

    // ── ACT prompt generation ───────────────────────────────────────────────────

    private data class ActPrompt(val title: String, val body: String)

    private fun getActPrompt(): ActPrompt {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val name = prefs.getString("flutter.user_first_name", null) ?: ""
        val values = prefs.getStringSet("flutter.user_values", emptySet())?.toList() ?: emptyList()
        val hasName = name.isNotEmpty()

        // 4 categories: 0=defusion, 1=values, 2=urge_surfing, 3=present_moment
        val availableCategories = if (values.isEmpty()) {
            listOf(0, 2, 3) // Skip values category
        } else {
            listOf(0, 1, 2, 3)
        }.filter { it != lastCategoryIndex }

        val category = if (availableCategories.isNotEmpty()) {
            availableCategories[Random.nextInt(availableCategories.size)]
        } else {
            Random.nextInt(4)
        }
        lastCategoryIndex = category

        return when (category) {
            0 -> { // Defusion
                val prompts = listOf(
                    ActPrompt(
                        "Notice the thought.",
                        if (hasName) "$name, you're having the thought that you need this right now. That's just a thought \u2014 not a command."
                        else "You're having the thought that you need this right now. That's just a thought \u2014 not a command."
                    ),
                    ActPrompt(
                        "Observe the urge.",
                        if (hasName) "Notice the urge, $name. You don't have to obey it."
                        else "Notice the urge. You don't have to obey it."
                    ),
                    ActPrompt(
                        "It's just a story.",
                        "Your mind is telling you a story right now. You get to choose whether to follow it."
                    )
                )
                prompts[Random.nextInt(prompts.size)]
            }
            1 -> { // Values
                val v1 = if (values.isNotEmpty()) values[0].lowercase() else "what matters"
                val v2 = if (values.size > 1) values[1].lowercase() else "your goals"
                val v3 = if (values.size > 2) values[2].lowercase() else "your future"
                val prompts = listOf(
                    ActPrompt(
                        "Remember your values.",
                        if (hasName) "$name, you said $v1 matters to you. Does this move you closer to or further from that?"
                        else "You said $v1 matters to you. Does this move you closer to or further from that?"
                    ),
                    ActPrompt(
                        "Who do you want to be?",
                        "Think about $v2 for a moment. What would that version of you do right now?"
                    ),
                    ActPrompt(
                        "Live your values.",
                        if (hasName) "Your values are $v1, $v2, and $v3. This is a moment to live them, $name."
                        else "Your values are $v1, $v2, and $v3. This is a moment to live them."
                    )
                )
                prompts[Random.nextInt(prompts.size)]
            }
            2 -> { // Urge surfing
                val prompts = listOf(
                    ActPrompt(
                        "Ride the wave.",
                        "This urge will peak and pass \u2014 like a wave. You don't have to act on it."
                    ),
                    ActPrompt(
                        "Breathe through it.",
                        if (hasName) "Take three slow breaths, $name. The urge is already losing power."
                        else "Take three slow breaths. The urge is already losing power."
                    ),
                    ActPrompt(
                        "You've survived every one.",
                        "Urges last 15\u201320 minutes. You've survived every one so far."
                    )
                )
                prompts[Random.nextInt(prompts.size)]
            }
            else -> { // Present moment
                val prompts = listOf(
                    ActPrompt(
                        "Name the feeling.",
                        "What are you actually feeling right now \u2014 bored, stressed, lonely, tired? Name it."
                    ),
                    ActPrompt(
                        "Pause and reflect.",
                        if (hasName) "$name, pause. What just happened in the last 10 minutes that brought you here?"
                        else "Pause. What just happened in the last 10 minutes that brought you here?"
                    ),
                    ActPrompt(
                        "Find the trigger.",
                        "You're here because something triggered you. Can you identify what it was?"
                    )
                )
                prompts[Random.nextInt(prompts.size)]
            }
        }
    }

    private fun applyAppGuardPrompt() {
        val prompt = getActPrompt()
        overlayView?.findViewById<TextView>(R.id.tv_prompt_title)?.text = prompt.title
        overlayView?.findViewById<TextView>(R.id.tv_prompt_body)?.text = prompt.body
    }

    private fun applyVpnPrompt() {
        val prompt = getActPrompt()
        overlayView?.findViewById<TextView>(R.id.tv_vpn_prompt_title)?.text = prompt.title
        overlayView?.findViewById<TextView>(R.id.tv_vpn_prompt_body)?.text = prompt.body
    }

    // ── App-guard overlay ─────────────────────────────────────────────────────

    private fun showAppGuardOverlay(appName: String) {
        Log.d(TAG, "showAppGuardOverlay: '$appName'")
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_intercept, null)

        overlayView?.findViewById<TextView>(R.id.tv_subtitle)?.text =
            "You opened $appName.\nANCHORAGE intercepted it."

        applyAppGuardPrompt()

        overlayView?.findViewById<Button>(R.id.btn_reflect)?.setOnClickListener {
            Log.d(TAG, "btn_reflect tapped")
            dismiss()
            launchAnchorage(navigateTo = NAVIGATE_REFLECT)
        } ?: Log.e(TAG, "btn_reflect not found in layout")

        overlayView?.findViewById<Button>(R.id.btn_stay_anchored)?.setOnClickListener {
            Log.d(TAG, "btn_stay_anchored tapped")
            dismiss()
            launchAnchorage(navigateTo = null)
        } ?: Log.e(TAG, "btn_stay_anchored not found in layout")

        overlayView?.findViewById<Button>(R.id.btn_sos)?.setOnClickListener {
            Log.d(TAG, "btn_sos tapped (app-guard)")
            dismiss()
            launchAnchorage(navigateTo = NAVIGATE_SOS)
        } ?: Log.e(TAG, "btn_sos not found in layout")

        addOverlayView()
    }

    // ── VPN-blocked overlay ───────────────────────────────────────────────────

    private fun showVpnBlockedOverlay(domain: String) {
        Log.d(TAG, "showVpnBlockedOverlay: '$domain'")
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_vpn_blocked, null)

        overlayView?.findViewById<TextView>(R.id.tv_domain_msg)?.text =
            "$domain is blocked.\nANCHORAGE is protecting you."

        applyVpnPrompt()

        overlayView?.findViewById<Button>(R.id.btn_vpn_reflect)?.setOnClickListener {
            Log.d(TAG, "btn_vpn_reflect tapped")
            dismissVpn()
            launchAnchorage(navigateTo = NAVIGATE_REFLECT)
        } ?: Log.e(TAG, "btn_vpn_reflect not found in layout")

        overlayView?.findViewById<Button>(R.id.btn_vpn_go_back)?.setOnClickListener {
            Log.d(TAG, "btn_vpn_go_back tapped")
            dismissVpn()
        } ?: Log.e(TAG, "btn_vpn_go_back not found in layout")

        overlayView?.findViewById<Button>(R.id.btn_vpn_sos)?.setOnClickListener {
            Log.d(TAG, "btn_vpn_sos tapped")
            dismissVpn()
            launchAnchorage(navigateTo = NAVIGATE_SOS)
        } ?: Log.e(TAG, "btn_vpn_sos not found in layout")

        addOverlayView()
    }

    // ── Shared helpers ────────────────────────────────────────────────────────

    private fun addOverlayView() {
        val params = buildLayoutParams()
        try {
            windowManager?.addView(overlayView, params)
            Log.d(TAG, "addOverlayView: added (vpnMode=$isVpnBlockedMode height=${params.height}px)")
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

    /** Dismiss app-guard overlay and signal [AppGuardService] to re-arm. */
    private fun dismiss() {
        handler.removeCallbacks(autoDismissRunner)
        AppGuardService.overlayDismissed = true
        Log.d(TAG, "dismiss: signaled AppGuardService.overlayDismissed=true")
        removeOverlayView()
        stopSelf()
    }

    /** Dismiss VPN-blocked overlay — does NOT touch AppGuardService state. */
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

    /**
     * Overlay layout params:
     *
     * TYPE_APPLICATION_OVERLAY — drawn above all other apps (requires SYSTEM_ALERT_WINDOW).
     *
     * FLAG_NOT_FOCUSABLE — the overlay does NOT capture key events. Back / Home / volume
     *   are handled by the system so the user is never trapped. Touch events still
     *   work normally within the overlay bounds.
     *
     * FLAG_LAYOUT_IN_SCREEN — window coordinates start at y=0 (behind status bar) so
     *   the overlay fills from the very top of the screen.
     *
     * Height is (screen height − navigation bar height) so the overlay never extends
     * into the navigation bar.
     */
    private fun buildLayoutParams(): WindowManager.LayoutParams {
        val navBarHeight = getNavigationBarHeight()
        val screenHeight = resources.displayMetrics.heightPixels
        val overlayHeight = screenHeight - navBarHeight

        Log.d(TAG, "buildLayoutParams: screen=$screenHeight navBar=$navBarHeight overlay=$overlayHeight")

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

    private fun launchAnchorage(navigateTo: String?) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (navigateTo != null) putExtra(EXTRA_NAVIGATE_TO, navigateTo)
        }
        startActivity(intent)
        Log.d(TAG, "launchAnchorage: navigateTo=$navigateTo")
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy: vpnMode=$isVpnBlockedMode autoDismiss=$isBeingAutoDismissed overlayView=${overlayView != null}")
        handler.removeCallbacks(autoDismissRunner)

        if (overlayView != null) {
            if (!isVpnBlockedMode && !isBeingAutoDismissed) {
                Log.w(TAG, "onDestroy: unexpected kill of app-guard overlay — signaling overlayDismissed")
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
        const val NAVIGATE_HOME     = "home"
        const val NAVIGATE_REFLECT  = "reflect"
        const val NAVIGATE_SOS      = "sos"

        private const val AUTO_DISMISS_MS = 30_000L

        /**
         * Set to `true` by [AppGuardService] before calling [stopService] for an
         * auto-dismiss (Home / Back pressed during app-guard overlay).
         */
        @Volatile var isBeingAutoDismissed = false

        /** Track last prompt category to avoid repeats (survives across overlay instances). */
        @Volatile var lastCategoryIndex = -1

        private const val TAG = "AnchorageOverlay"
    }
}
