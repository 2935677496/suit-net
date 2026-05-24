plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.suit_net"
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
            // 你的 jks 文件名（必须放在 android/app/ 下）
            keyAlias = "myapp"
            keyPassword = "2508210211"
            storeFile = file("myapp.jks") // 改成你的jks文件名
            storePassword = "2508210211"
        }
    }
    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.suit_net"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
    }
    
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            isMinifyEnabled = true        // 代码压缩
            isShrinkResources = true      // 资源压缩
            isDebuggable = false
            signingConfig = signingConfigs.getByName("release")
        }
        
    }
}

flutter {
    source = "../.."
}
