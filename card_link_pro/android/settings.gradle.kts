// android/settings.gradle.kts

rootProject.name = "card_link_pro"

// Plugin management: resolve the Flutter SDK path and include Flutter’s Gradle build
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // Read flutter.sdk from local.properties without relying on an import
    val localPropsFile = java.io.File(settingsDir, "local.properties")
    val flutterSdkPath: String =
        if (localPropsFile.exists()) {
            val props = java.util.Properties().apply {
                localPropsFile.inputStream().use { load(it) }
            }
            props.getProperty("flutter.sdk")
                ?: throw GradleException("flutter.sdk not set in local.properties")
        } else {
            // Fallback to environment variables
            (System.getenv("FLUTTER_HOME") ?: System.getenv("FLUTTER_SDK"))?.trim()
                ?: throw GradleException(
                    "Flutter SDK path not found. Add 'flutter.sdk=/path/to/flutter' to android/local.properties " +
                            "or set FLUTTER_HOME/FLUTTER_SDK environment variable."
                )
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

// Apply the Flutter plugin loader and AGP/Kotlin versions
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
