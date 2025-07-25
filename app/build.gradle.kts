// 파일 위치: android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // <--- 이 줄이 있는지 확인!
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.calorieburn.calorieburn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // <--- 이렇게 바꿔주세요

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.calorieburn.calorieburn"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
