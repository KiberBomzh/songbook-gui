import java.io.FileInputStream
import java.util.Properties


plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
	keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kiber_bomzh.songbook"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.kiber_bomzh.songbook"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

	signingConfigs {
		create("release") {
			if (keystorePropertiesFile.exists()) {
				keyAlias = keystoreProperties["keyAlias"] as String?
				keyPassword = keystoreProperties["keyPassword"] as String?
				storeFile = (keystoreProperties["storeFile"] as String?)?.let { rootProject.file(it) }
				storePassword = keystoreProperties["storePassword"] as String?

				enableV1Signing = true
				enableV2Signing = true
				enableV3Signing = true
			} else {
				println("Keystore properties file not found. No signing configuration will be applied.")
			}
		}
	}

    buildTypes {
        release {
			if (keystorePropertiesFile.exists()) {
				signingConfig = signingConfigs.findByName("release")
			}
        }

		debug {
			applicationIdSuffix = ".debug"
		}
    }

    dependenciesInfo {
        // Disables dependency metadata when building APKs (for IzzyOnDroid/F-Droid)
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles (for Google Play)
        includeInBundle = false
    }
}

kotlin {
	complilerOptions {
		jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTargetJVM_17
	}
}

flutter {
    source = "../.."
}
