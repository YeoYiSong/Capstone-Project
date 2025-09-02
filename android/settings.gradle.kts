pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // 這裡可以保留 google-services 外掛的版本
    plugins {
        id("com.google.gms.google-services") version "4.4.1"
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    // 升級到 Kotlin 2.1.x（建議 2.1.10 或 2.1.0 以上）
    id("org.jetbrains.kotlin.android") version "2.1.10" apply false
}

include(":app")
