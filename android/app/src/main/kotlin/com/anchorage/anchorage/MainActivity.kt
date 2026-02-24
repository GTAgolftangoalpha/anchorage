package com.anchorage.anchorage

import android.app.AppOpsManager
import android.content.Intent
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val channelName = "com.anchorage.app/guard"
    private val vpnChannelName = "com.anchorage.app/vpn"
    private var channel: MethodChannel? = null
    private var vpnChannel: MethodChannel? = null

    // Guard intent that arrived before Flutter was ready
    private var pendingGuardedApp: String? = null

    // Pending result for VPN consent dialog (returned to Flutter after onActivityResult)
    private var pendingVpnResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine: setting up MethodChannel '$channelName'")

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "MethodChannel call: ${call.method} args=${call.arguments}")
            when (call.method) {
                "isUsagePermissionGranted" -> {
                    val granted = isUsagePermissionGranted()
                    Log.d(TAG, "isUsagePermissionGranted → $granted")
                    result.success(granted)
                }
                "requestUsagePermission" -> {
                    Log.d(TAG, "requestUsagePermission: opening Settings")
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "startGuardService" -> {
                    @Suppress("UNCHECKED_CAST")
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    Log.d(TAG, "startGuardService: apps=$apps")
                    startGuardService(apps)
                    result.success(null)
                }
                "stopGuardService" -> {
                    Log.d(TAG, "stopGuardService: stopping service")
                    stopService(Intent(this, AppGuardService::class.java))
                    result.success(null)
                }
                "hasOverlayPermission" -> {
                    val has = Settings.canDrawOverlays(this)
                    Log.d(TAG, "hasOverlayPermission → $has")
                    result.success(has)
                }
                "requestOverlayPermission" -> {
                    Log.d(TAG, "requestOverlayPermission: opening Settings")
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(null)
                }
                "isBatteryOptimizationExempt" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    val exempt = pm.isIgnoringBatteryOptimizations(packageName)
                    Log.d(TAG, "isBatteryOptimizationExempt → $exempt")
                    result.success(exempt)
                }
                "requestBatteryOptimizationExempt" -> {
                    Log.d(TAG, "requestBatteryOptimizationExempt: opening dialog")
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    } catch (e: Exception) {
                        Log.e(TAG, "requestBatteryOptimizationExempt: failed", e)
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    }
                    result.success(null)
                }
                else -> {
                    Log.w(TAG, "MethodChannel: unknown method '${call.method}'")
                    result.notImplemented()
                }
            }
        }

        // VPN method channel
        vpnChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, vpnChannelName)
        vpnChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent == null) {
                        // Permission already granted
                        result.success(true)
                    } else {
                        pendingVpnResult = result
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, REQUEST_VPN_PERMISSION)
                    }
                }
                "startVpn" -> {
                    val intent = Intent(this, AnchorageVpnService::class.java).apply {
                        action = AnchorageVpnService.ACTION_START
                    }
                    startService(intent)
                    result.success(null)
                }
                "stopVpn" -> {
                    val intent = Intent(this, AnchorageVpnService::class.java).apply {
                        action = AnchorageVpnService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                "isVpnActive" -> result.success(AnchorageVpnService.isRunning)
                "reloadCustomBlocklist" -> {
                    @Suppress("UNCHECKED_CAST")
                    val domains = call.arguments as? List<String> ?: emptyList()
                    Log.d(TAG, "reloadCustomBlocklist: ${domains.size} domains")
                    // Write domains to file for VPN service to load
                    val file = File(filesDir, "custom_blocklist.txt")
                    file.writeText(domains.joinToString("\n"))
                    // Hot-reload if VPN is running
                    AnchorageVpnService.reloadCustomDomains()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Wire VPN domain-blocked events to Flutter
        AnchorageVpnService.blockedDomainListener = { domain ->
            runOnUiThread {
                vpnChannel?.invokeMethod("onDomainBlocked", domain)
            }
        }

        // Deliver any intercept that arrived before the engine was ready
        pendingGuardedApp?.let { appName ->
            Log.d(TAG, "configureFlutterEngine: delivering pending intercept for '$appName'")
            pendingGuardedApp = null
            channel?.invokeMethod("onGuardedAppDetected", appName)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_VPN_PERMISSION) {
            val granted = resultCode == RESULT_OK
            Log.d(TAG, "onActivityResult: VPN consent granted=$granted")
            pendingVpnResult?.success(granted)
            pendingVpnResult = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d(TAG, "onNewIntent: extras=${intent.extras?.keySet()}")
        deliverGuardIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume: checking intent for guard extras")
        deliverGuardIntent(intent)
    }

    private fun deliverGuardIntent(intent: Intent?) {
        // Handle overlay → Flutter navigation (from OverlayService button taps)
        val navigateTo = intent?.getStringExtra(OverlayService.EXTRA_NAVIGATE_TO)
        if (navigateTo != null) {
            intent.removeExtra(OverlayService.EXTRA_NAVIGATE_TO)
            Log.d(TAG, "deliverGuardIntent: navigateTo='$navigateTo'")
            channel?.invokeMethod("navigateTo", navigateTo)
        }

        // Handle fallback activity-based intercept (overlay permission not granted)
        val appName = intent?.getStringExtra(AppGuardService.EXTRA_APP_NAME) ?: return
        Log.d(TAG, "deliverGuardIntent: intercepted app='$appName' channel=${if (channel != null) "ready" else "NOT READY"}")
        intent.removeExtra(AppGuardService.EXTRA_APP_NAME)
        if (channel != null) {
            channel?.invokeMethod("onGuardedAppDetected", appName)
        } else {
            Log.w(TAG, "deliverGuardIntent: channel not ready, storing as pendingGuardedApp")
            pendingGuardedApp = appName
        }
    }

    private fun isUsagePermissionGranted(): Boolean {
        return try {
            val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            }
            val granted = mode == AppOpsManager.MODE_ALLOWED
            Log.d(TAG, "isUsagePermissionGranted: mode=$mode granted=$granted")
            granted
        } catch (e: Exception) {
            Log.e(TAG, "isUsagePermissionGranted: exception", e)
            false
        }
    }

    private fun startGuardService(apps: List<String>) {
        try {
            val intent = Intent(this, AppGuardService::class.java).apply {
                putStringArrayListExtra(AppGuardService.EXTRA_GUARDED_APPS, ArrayList(apps))
            }
            startForegroundService(intent)
            Log.d(TAG, "startGuardService: startForegroundService called with ${apps.size} apps")
        } catch (e: Exception) {
            Log.e(TAG, "startGuardService: FAILED to start foreground service", e)
        }
    }

    override fun onDestroy() {
        AnchorageVpnService.blockedDomainListener = null
        super.onDestroy()
    }

    companion object {
        private const val TAG = "AnchorageMain"
        private const val REQUEST_VPN_PERMISSION = 100
    }
}
