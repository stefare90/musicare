import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val releaseSigningConfigured = keystorePropertiesFile.exists()
if (releaseSigningConfigured) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// Release builds are only ever signed with the release keystore: there is no
// fallback to the debug key, so a release build without key.properties fails
// instead of shipping an APK that cannot be updated.
if (!releaseSigningConfigured) {
    tasks.configureEach {
        if (name == "preReleaseBuild" || name == "assembleRelease" || name == "bundleRelease") {
            doFirst {
                throw GradleException(
                    "Release signing is not configured: android/key.properties is missing. " +
                        "Create the release keystore and write android/key.properties with " +
                        "storeFile, storePassword, keyAlias and keyPassword. " +
                        "Release builds are never signed with the Android debug key.",
                )
            }
        }
    }
}

android {
    namespace = "com.musicare.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.musicare.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
