plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ==================== LOAD KEYSTORE PROPERTIES ====================
// Membaca file key.properties untuk konfigurasi signing
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// ================================================================

android {
    namespace = "com.smkn1garut.sip"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Unique Application ID untuk SMKN 1 Garut - SIP
        applicationId = "com.smkn1garut.sip"
        
        // SDK versions dari Flutter
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        // Version dari Flutter pubspec.yaml
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // MultiDex support untuk kompatibilitas dengan banyak dependencies
        multiDexEnabled = true

        // Test instrumentation runner
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // ==================== SIGNING CONFIGURATION ====================
    // Konfigurasi signing untuk release build menggunakan keystore
    signingConfigs {
        create("release") {
            // Baca nilai dari file key.properties
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
        
        // Debug config (menggunakan debug.keystore default)
        create("debug") {
            // Debug build otomatis pakai debug keystore
        }
    }
    // ===============================================================

    buildTypes {
        // Release build - untuk production / Play Store
        release {
            // ✅ Gunakan release signing config (dari keystore asli)
            signingConfig = signingConfigs.getByName("release")
            
            // Optimasi: Minify kode untuk mengurangi ukuran APK
            isMinifyEnabled = true
            
            // Optimasi: Hapus resource yang tidak dipakai
            isShrinkResources = true
            
            // Proguard rules untuk obfuscation & optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        // Debug build - untuk development
        debug {
            // Debug build pakai debug keystore default Android
            signingConfig = signingConfigs.getByName("debug")
            
            // Tidak perlu minify/shrink di debug (biar cepat build)
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Debuggable agar bisa inspect
            isDebuggable = true
        }
    }

    // Kompilasi options
    aaptOptions {
        noCompress += listOf("tflite", "litemodel")
    }

    // Packaging options (opsional, untuk menghindari duplicate files)
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

// ==================== DEPENDENCIES ====================
dependencies {
    // MultiDex support untuk aplikasi dengan method count > 64K
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Testing dependencies
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}