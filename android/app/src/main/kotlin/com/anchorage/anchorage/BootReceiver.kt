package com.anchorage.anchorage

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.util.Log

/**
 * Starts ANCHORAGE protection automatically after device boot.
 *
 * Listens for:
 *   - android.intent.action.BOOT_COMPLETED    (standard Android)
 *   - android.intent.action.QUICKBOOT_POWERON (Samsung fast/warm reboot)
 *
 * BOOT_COMPLETED is delivered only after the user's first unlock, so
 * CE-encrypted SharedPreferences (guarded app list) are accessible.
 *
 * Starting foreground services from a BOOT_COMPLETED receiver is explicitly
 * permitted by Android — this is one of the allowed background-start exceptions.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON") {
            return
        }

        Log.d(TAG, "onReceive: action=$action — starting ANCHORAGE services")

        startVpn(context)
        startGuard(context)
    }

    private fun startVpn(context: Context) {
        // VpnService.prepare() returns null when the VPN permission is already held.
        // On boot there is no UI, so we can only start if consent was previously granted.
        val needsConsent = VpnService.prepare(context)
        if (needsConsent != null) {
            Log.w(TAG, "startVpn: VPN consent not yet granted — skipping (user must open app once)")
            return
        }

        if (AnchorageVpnService.isRunning) {
            Log.d(TAG, "startVpn: already running — skipping")
            return
        }

        val intent = Intent(context, AnchorageVpnService::class.java).apply {
            action = AnchorageVpnService.ACTION_START
        }
        context.startForegroundService(intent)
        Log.d(TAG, "startVpn: startForegroundService called")
    }

    private fun startGuard(context: Context) {
        if (AppGuardService.serviceRunning) {
            Log.d(TAG, "startGuard: already running — skipping")
            return
        }

        // Read the guarded-app list that AppGuardService persisted during the
        // last user session. If the list is empty, the guard service starts but
        // has nothing to monitor — it will re-arm when the user next opens the app.
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(PREFS_KEY_APPS, "") ?: ""
        val apps = if (raw.isNotEmpty()) {
            raw.split(",").map { it.trim() }.filter { it.isNotEmpty() }
        } else {
            emptyList()
        }

        Log.d(TAG, "startGuard: restoring ${apps.size} guarded apps: $apps")

        val intent = Intent(context, AppGuardService::class.java).apply {
            putStringArrayListExtra(AppGuardService.EXTRA_GUARDED_APPS, ArrayList(apps))
        }
        context.startForegroundService(intent)
        Log.d(TAG, "startGuard: startForegroundService called")
    }

    companion object {
        private const val TAG = "AnchorageBootReceiver"

        // Must match AppGuardService constants exactly
        private const val PREFS_NAME     = "anchorage_guard_prefs"
        private const val PREFS_KEY_APPS = "guarded_apps"
    }
}
