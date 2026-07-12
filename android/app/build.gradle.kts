import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from android/key.properties (git-ignored). When that
// file is absent (fresh clone / CI without secrets) we fall back to debug keys
// so the project still builds. A stable release key means installs UPDATE in
// place instead of forcing an uninstall — which would wipe the on-device DB.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    namespace = "com.macrochef.app"
    // compileSdk 36 + NDK 27 required by flutter_secure_storage / sherpa_onnx /
    // sqlite3_flutter_libs / path_provider plugins.
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Required by flutter_local_notifications: it uses java.time APIs that
        // must be backported on devices below API 26 (our minSdk is 23).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    packaging {
        jniLibs {
            pickFirsts += setOf("**/libonnxruntime.so", "**/libonnxruntime4j_jni.so")
        }
    }

    defaultConfig {
        applicationId = "com.macrochef.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // flutter_gemma (on-device LLM / MediaPipe) requires minSdk 24;
        // flutter_secure_storage needs >=23, so 24 satisfies both.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = (keystoreProperties["storeFile"] as String).let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Prefer the stable release key (android/key.properties); fall back to
            // the debug key when the keystore isn't present so the build still runs.
            signingConfig = if (hasReleaseSigning)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Backports java.time for flutter_local_notifications on API < 26.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
