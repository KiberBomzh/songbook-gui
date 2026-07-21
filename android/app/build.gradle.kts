import java.io.FileInputStream
import java.util.Properties


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
	keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.songbook"
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
        applicationId = "com.kiber_bomzh.songbook"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

	signingConfigs {
		create("release") {
			keyAlias = keystoreProperties["keyAlias"] as String?
			keyPassword = keystoreProperties["keyPassword"] as String?
			storeFile = (keystoreProperties["storeFile"] as String?)?.let { rootProject.file(it) }
			storePassword = keystoreProperties["storePassword"] as String?

			enableV1Signing = true
			enableV2Signing = true
			enableV3Signing = true
		}
	}

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }

		debug {
			applicationIdSuffix = ".debug"
		}
    }
}

flutter {
    source = "../.."
}
