# Flutter standard keep rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep WorkManager workers
-keep class com.anchorage.anchorage.HeartbeatWorker { *; }
-keep class com.anchorage.anchorage.BlocklistUpdateWorker { *; }

# Keep device admin receiver
-keep class com.anchorage.anchorage.AnchorageDeviceAdminReceiver { *; }

# Keep VPN service
-keep class com.anchorage.anchorage.AnchorageVpnService { *; }

# Keep overlay and guard services
-keep class com.anchorage.anchorage.OverlayService { *; }
-keep class com.anchorage.anchorage.AppGuardService { *; }

# Keep BootReceiver
-keep class com.anchorage.anchorage.BootReceiver { *; }

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Prevent obfuscation of classes referenced via reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
