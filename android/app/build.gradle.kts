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
  namespace = "za.co.zarply"
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
    applicationId = "za.co.zarply"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
  }

  signingConfigs {
    create("release") {
      keyAlias = keystoreProperties["keyAlias"] as? String ?: ""
      keyPassword = keystoreProperties["keyPassword"] as? String ?: ""
      storeFile = keystoreProperties["storeFile"]?.let { file(it) }
      storePassword = keystoreProperties["storePassword"] as? String ?: ""
    }
  }

  buildTypes {
    getByName("debug") {}
    getByName("release") {
      isMinifyEnabled = true
      isShrinkResources = true
      signingConfig = signingConfigs.getByName("release")
    }
  }

  // Environment-specific product flavors to mirror QA / PROD behaviour
  flavorDimensions += "environment"
  productFlavors {
    create("qa") {
      dimension = "environment"
      applicationIdSuffix = ".qa"
      resValue(
        type = "string",
        name = "app_name",
        value = "Zarply QA"
      )
    }
    create("prod") {
      dimension = "environment"
      resValue(
        type = "string",
        name = "app_name",
        value = "Zarply"
      )
    }
  }
}

flutter {
  source = "../.."
}

dependencies {
  implementation("androidx.multidex:multidex:2.0.1")
}
