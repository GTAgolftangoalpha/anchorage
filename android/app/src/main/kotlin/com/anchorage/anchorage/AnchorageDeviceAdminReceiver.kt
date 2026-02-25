package com.anchorage.anchorage

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Device Administrator receiver. Registering ANCHORAGE as a device admin
 * requires the user to manually deactivate it in Settings before uninstalling,
 * adding friction against impulsive removal.
 *
 * No policies are enforced — the only purpose is uninstall friction.
 */
class AnchorageDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        Log.d(TAG, "Device admin enabled — uninstall friction active")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Log.d(TAG, "Device admin disabled — user can now uninstall")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Disabling device admin will make it easier to remove ANCHORAGE " +
                "in a moment of weakness. Are you sure?"
    }

    companion object {
        private const val TAG = "AnchorageDeviceAdmin"
    }
}
