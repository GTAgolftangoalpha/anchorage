plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.anchorage.anchorage"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            storeFile = file("anchorage-release.keystore")
            storePassword = System.getenv("ANCHORAGE_STORE_PASSWORD") ?: "anchorage2026release"
            keyAlias = "anchorage-release"
            keyPassword = System.getenv("ANCHORAGE_KEY_PASSWORD") ?: "anchorage2026release"
        }
    }

    defaultConfig {
        applicationId = "com.anchorage.app"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Store blocklist.txt uncompressed in the APK so the OS can memory-map it
    // directly from storage rather than decompressing it at runtime. This cuts
    // cold-boot blocklist load time from ~10–30 s to ~1–2 s on mid-range devices.
    androidResources {
        noCompress += "txt"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    // Firebase for HeartbeatWorker (native Kotlin → Firestore)
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    // Coroutines for HeartbeatWorker
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.9.0")
}
