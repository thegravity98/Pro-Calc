plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    ndkVersion = "27.0.12077973"
    namespace = "com.example.myapp"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.myapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // buildTypes {
    //     release {
    //         // TODO: Add your own signing config for the release build.
    //         // Signing with the debug keys for now, so `flutter run --release` works.
    //         // signingConfig = signingConfigs.getByName("debug")
    //     }
    // }

      signingConfigs {
        create("release") {
            val storeFilePath = System.getenv("ANDROID_STORE_FILE") ?: project.property("MYAPP_RELEASE_STORE_FILE").toString()
            println("Store file path: $storeFilePath")
            storeFile = file(storeFilePath)
            storePassword = System.getenv("ANDROID_STORE_PASSWORD") ?: project.property("MYAPP_RELEASE_STORE_PASSWORD").toString()
            keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: project.property("MYAPP_RELEASE_KEY_ALIAS").toString()
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: project.property("MYAPP_RELEASE_KEY_PASSWORD").toString()
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = if (System.getenv("CI") == "true") null else signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

}

flutter {
    source = "../.."
}
