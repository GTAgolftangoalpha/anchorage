package com.anchorage.anchorage

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat

class AppGuardService : Service() {

    // ── State machine ─────────────────────────────────────────────────────────

    private enum class GuardState {
        /** No guarded app in foreground — polling normally. */
        IDLE,
        /** Overlay is visible over a guarded app. */
        OVERLAY_SHOWING,
        /** Overlay was dismissed by user; 2-second cooldown before re-intercept. */
        POST_DISMISS_COOLDOWN
    }

    private var guardState = GuardState.IDLE
    private var dismissedAt = 0L

    /** Package name of the app currently being intercepted (set when entering OVERLAY_SHOWING). */
    private var interceptedPkg = ""

    /** Timestamp when we entered OVERLAY_SHOWING; used to time-out stale overlays. */
    private var overlayShowingSince = 0L

    // Track last seen foreground package (for change detection and ANCHORAGE reset)
    private var lastForegroundPkg = ""

    private val handler = Handler(Looper.getMainLooper())
    private var isRunning = false
    private val guardedApps = mutableSetOf<String>()

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                checkForeground()
                handler.postDelayed(this, POLL_INTERVAL_MS)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        serviceRunning = true
        if (intent != null) {
            val apps = intent.getStringArrayListExtra(EXTRA_GUARDED_APPS) ?: arrayListOf()
            guardedApps.clear()
            guardedApps.addAll(apps)
            Log.d(TAG, "onStartCommand: received ${apps.size} apps from intent: $apps")
            persistGuardedApps()
        } else {
            Log.w(TAG, "onStartCommand: null intent (START_STICKY restart), restoring from prefs")
            restoreGuardedApps()
        }

        Log.d(TAG, "onStartCommand: guardedApps=$guardedApps")

        startForegroundWithNotification()

        if (!isRunning) {
            isRunning = true
            lastForegroundPkg = ""
            guardState = GuardState.IDLE
            interceptedPkg = ""
            overlayDismissed = false
            handler.post(pollRunnable)
            Log.d(TAG, "Polling started")
        }

        return START_STICKY
    }

    // ── Foreground detection ──────────────────────────────────────────────────

    private fun checkForeground() {
        val usm = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()

        // Process user-initiated dismiss signal from OverlayService
        if (overlayDismissed) {
            overlayDismissed = false
            Log.d(TAG, "checkForeground: user dismissed overlay → POST_DISMISS_COOLDOWN (was $guardState)")
            guardState = GuardState.POST_DISMISS_COOLDOWN
            dismissedAt = now
            interceptedPkg = ""
            overlayShowingSince = 0L
            // Reset so we re-detect the foreground app cleanly after dismiss
            lastForegroundPkg = ""
        }

        var foregroundPkg = detectViaQueryEvents(usm, now)
        if (foregroundPkg.isEmpty()) {
            foregroundPkg = detectViaQueryUsageStats(usm, now)
        }

        if (foregroundPkg.isEmpty()) {
            // Samsung doze/screen-off causes queryEvents to return 0 results, leaving
            // the guard stuck in OVERLAY_SHOWING indefinitely. After OVERLAY_TIMEOUT_MS
            // without being able to confirm the guarded app is still in foreground,
            // auto-dismiss so the overlay doesn't linger over unrelated apps (e.g. Netflix).
            if (guardState == GuardState.OVERLAY_SHOWING && overlayShowingSince > 0L &&
                now - overlayShowingSince > OVERLAY_TIMEOUT_MS
            ) {
                Log.w(TAG, "checkForeground: OVERLAY_SHOWING timed out (${now - overlayShowingSince}ms) — auto-dismissing")
                guardState = GuardState.IDLE
                interceptedPkg = ""
                overlayShowingSince = 0L
                OverlayService.isBeingAutoDismissed = true
                stopService(Intent(this, OverlayService::class.java))
            }
            Log.v(TAG, "checkForeground: no foreground app detected (state=$guardState)")
            return
        }

        val isNewForeground = foregroundPkg != lastForegroundPkg
        lastForegroundPkg = foregroundPkg
        lastKnownForeground = foregroundPkg

        // ANCHORAGE itself came to foreground — fully reset the state machine so
        // the same guarded app can be caught again the next time it opens.
        if (foregroundPkg == packageName) {
            if (isNewForeground) {
                Log.d(TAG, "checkForeground: ANCHORAGE in foreground — reset to IDLE (was $guardState)")
                // If an overlay is active, dismiss it — it must never persist over ANCHORAGE's own UI.
                if (guardState == GuardState.OVERLAY_SHOWING) {
                    OverlayService.isBeingAutoDismissed = true
                    stopService(Intent(this, OverlayService::class.java))
                }
                guardState = GuardState.IDLE
                interceptedPkg = ""
                overlayShowingSince = 0L
                dismissedAt = 0L
            }
            return
        }

        // Skip re-processing if nothing changed, UNLESS we're in POST_DISMISS_COOLDOWN
        // (which is time-based and must keep evaluating even without a foreground change).
        if (!isNewForeground && guardState != GuardState.POST_DISMISS_COOLDOWN) return

        Log.d(TAG, "checkForeground: foreground=$foregroundPkg state=$guardState guarded=$guardedApps")

        if (guardedApps.isEmpty()) {
            Log.w(TAG, "checkForeground: guardedApps is EMPTY — service running but nothing to guard")
            return
        }

        // ── State machine transitions ────────────────────────────────────────

        when (guardState) {
            GuardState.IDLE -> {
                if (!guardedApps.contains(foregroundPkg)) return
                Log.d(TAG, "checkForeground: IDLE → OVERLAY_SHOWING for $foregroundPkg")
                interceptedPkg = foregroundPkg
                guardState = GuardState.OVERLAY_SHOWING
                overlayShowingSince = now
                launchIntercept(foregroundPkg)
            }

            GuardState.OVERLAY_SHOWING -> {
                if (foregroundPkg == interceptedPkg) {
                    // Overlay is already up for this exact app — no-op
                    Log.v(TAG, "checkForeground: OVERLAY_SHOWING — still on $interceptedPkg, no-op")
                    return
                }
                // Foreground switched to something other than the intercepted app
                // (user pressed Home, Back, or Recents). Auto-dismiss the overlay
                // and return to IDLE — no cooldown, so next open re-intercepts immediately.
                Log.d(TAG, "checkForeground: OVERLAY_SHOWING — user left $interceptedPkg (now $foregroundPkg) — auto-dismiss overlay")
                guardState = GuardState.IDLE
                interceptedPkg = ""
                overlayShowingSince = 0L
                OverlayService.isBeingAutoDismissed = true
                stopService(Intent(this, OverlayService::class.java))
                // Don't set overlayDismissed — auto-dismiss goes straight to IDLE, no cooldown.
            }

            GuardState.POST_DISMISS_COOLDOWN -> {
                if (!guardedApps.contains(foregroundPkg)) return
                val elapsed = now - dismissedAt
                if (elapsed >= POST_DISMISS_COOLDOWN_MS) {
                    Log.d(TAG, "checkForeground: POST_DISMISS cooldown elapsed (${elapsed}ms) → re-intercepting $foregroundPkg")
                    interceptedPkg = foregroundPkg
                    guardState = GuardState.OVERLAY_SHOWING
                    overlayShowingSince = now
                    launchIntercept(foregroundPkg)
                } else {
                    Log.v(TAG, "checkForeground: POST_DISMISS cooldown active — ${POST_DISMISS_COOLDOWN_MS - elapsed}ms remaining")
                }
            }
        }
    }

    private fun detectViaQueryEvents(usm: UsageStatsManager, now: Long): String {
        val events = usm.queryEvents(now - QUERY_WINDOW_MS, now)
        var foregroundPkg = ""
        var eventCount = 0
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            eventCount++
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                foregroundPkg = event.packageName
            }
        }

        Log.v(TAG, "detectViaQueryEvents: $eventCount events, foreground='$foregroundPkg'")
        return foregroundPkg
    }

    private fun detectViaQueryUsageStats(usm: UsageStatsManager, now: Long): String {
        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST,
            now - STATS_WINDOW_MS,
            now
        ) ?: return ""

        if (stats.isEmpty()) {
            Log.v(TAG, "detectViaQueryUsageStats: empty stats list")
            return ""
        }

        val recent = stats
            .filter { it.packageName != null && it.lastTimeUsed > 0 }
            .maxByOrNull { it.lastTimeUsed }
            ?: return ""

        if (recent.lastTimeUsed < now - 5_000L) return ""

        Log.v(TAG, "detectViaQueryUsageStats: recent='${recent.packageName}' lastUsed=${now - recent.lastTimeUsed}ms ago")
        return recent.packageName
    }

    // ── Intercept launch ─────────────────────────────────────────────────────

    private fun launchIntercept(pkg: String) {
        // Absolute guard: ANCHORAGE must never intercept itself under any circumstances.
        if (pkg == packageName) {
            Log.e(TAG, "launchIntercept: BUG — tried to intercept own package '$pkg' — skipping")
            guardState = GuardState.IDLE
            interceptedPkg = ""
            return
        }

        // Hard safety gate: never intercept a package not explicitly in the guard list.
        // Protects against stale SharedPreferences, race conditions, or state machine bugs.
        if (!guardedApps.contains(pkg)) {
            Log.w(TAG, "launchIntercept: SAFETY GATE — '$pkg' not in guardedApps $guardedApps — skipping")
            guardState = GuardState.IDLE
            interceptedPkg = ""
            return
        }

        val appName = try {
            val info = packageManager.getApplicationInfo(pkg, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            Log.w(TAG, "launchIntercept: could not get label for $pkg", e)
            pkg
        }

        Log.d(TAG, "launchIntercept: intercepting '$appName' ($pkg)")

        if (Settings.canDrawOverlays(this)) {
            Log.d(TAG, "launchIntercept: using OverlayService")
            val intent = Intent(this, OverlayService::class.java).apply {
                putExtra(OverlayService.EXTRA_APP_NAME, appName)
            }
            startService(intent)
        } else {
            Log.w(TAG, "launchIntercept: overlay permission not granted, falling back to activity")
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra(EXTRA_APP_NAME, appName)
            }
            startActivity(intent)
        }
    }

    // ── SharedPreferences persistence ─────────────────────────────────────────

    private fun persistGuardedApps() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(PREFS_KEY_APPS, guardedApps.joinToString(",")).apply()
        Log.d(TAG, "persistGuardedApps: saved ${guardedApps.size} apps")
    }

    private fun restoreGuardedApps() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(PREFS_KEY_APPS, "") ?: ""
        guardedApps.clear()
        if (raw.isNotEmpty()) {
            guardedApps.addAll(raw.split(",").map { it.trim() }.filter { it.isNotEmpty() })
        }
        Log.d(TAG, "restoreGuardedApps: restored ${guardedApps.size} apps: $guardedApps")
    }

    // ── Notification ─────────────────────────────────────────────────────────

    private fun startForegroundWithNotification() {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        if (nm.getNotificationChannel(NOTIFICATION_CHANNEL_ID) == null) {
            NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "ANCHORAGE Guard",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors for guarded apps"
                setShowBadge(false)
            }.also { nm.createNotificationChannel(it) }
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification: Notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("ANCHORAGE Active ⚓")
            .setContentText("Guarding ${guardedApps.size} app(s): ${guardedApps.joinToString { it.substringAfterLast('.') }}")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE -> {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            }
            else -> startForeground(NOTIFICATION_ID, notification)
        }

        Log.d(TAG, "startForegroundWithNotification: posted, guarding ${guardedApps.size} apps")
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy: service stopping")
        isRunning = false
        serviceRunning = false
        handler.removeCallbacks(pollRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val EXTRA_GUARDED_APPS = "GUARDED_APPS"
        const val EXTRA_APP_NAME = "GUARDED_APP_NAME"

        /**
         * Set to `true` by [OverlayService] when the user taps a dismiss button.
         * Consumed by [AppGuardService.checkForeground] to transition to POST_DISMISS_COOLDOWN.
         * NOT set on auto-dismiss (home/back nav) — that goes straight to IDLE.
         */
        @Volatile var overlayDismissed = false

        /**
         * True while AppGuardService is running (set in onStartCommand, cleared in onDestroy).
         * Read by BootReceiver to skip a duplicate startForegroundService call.
         */
        @Volatile var serviceRunning = false

        /**
         * Last package name detected in the foreground by the guard poll loop.
         * Read by [AnchorageVpnService.notifyDomainBlocked] to suppress the VPN blocked-domain
         * overlay when ANCHORAGE itself is the foreground app (our own SDKs may hit blocked domains).
         * Empty string until the first poll completes.
         */
        @Volatile var lastKnownForeground = ""

        private const val TAG = "AnchorageGuard"
        private const val NOTIFICATION_ID = 1001
        private const val NOTIFICATION_CHANNEL_ID = "anchorage_guard"
        private const val POLL_INTERVAL_MS = 300L
        private const val QUERY_WINDOW_MS = 10_000L
        private const val STATS_WINDOW_MS = 10_000L
        private const val POST_DISMISS_COOLDOWN_MS = 2_000L
        /** Auto-dismiss overlay if we can't detect any foreground app for this long (Samsung doze). */
        private const val OVERLAY_TIMEOUT_MS = 15_000L

        private const val PREFS_NAME = "anchorage_guard_prefs"
        private const val PREFS_KEY_APPS = "guarded_apps"
    }
}
