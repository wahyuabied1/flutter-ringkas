import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Kunci rilis dibaca dari android/key.properties (tidak masuk git).
// Format dan caranya ada di docs/wiki/Panduan-Pengembangan.md.
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties().apply {
    if (keyPropsFile.exists()) FileInputStream(keyPropsFile).use { load(it) }
}

android {
    namespace = "com.fibod.ringkas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fibod.ringkas"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyPropsFile.exists()) {
            create("release") {
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true // R8: perkecil dan samarkan kode Java/Kotlin
            isShrinkResources = true // buang resource yang tidak terpakai (butuh minify)
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Tanpa key.properties, rilis memakai kunci debug agar `flutter run --release`
            // tetap bisa dipakai untuk uji lokal. AAB untuk Play Store dijaga di bawah.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// AAB (format unggahan Play Store) tidak boleh ditandatangani kunci debug. Play menolaknya
// dengan pesan "signed with the wrong key" dan kunci yang salah bisa terlanjur terdaftar.
gradle.taskGraph.whenReady {
    if (!keyPropsFile.exists() && allTasks.any { it.name == "bundleRelease" }) {
        throw GradleException(
            "android/key.properties belum ada, jadi AAB rilis akan ditandatangani kunci debug. " +
                "Buat key.properties dari kunci unggah Play Store (lihat docs/wiki/Panduan-Pengembangan.md).",
        )
    }
}
