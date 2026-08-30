import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile =
    rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(
            keystorePropertiesFile
        )
    )
}

android {
    namespace = "com.tugvote.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility =
            JavaVersion.VERSION_21
        targetCompatibility =
            JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId =
            "com.tugvote.app"

        minSdk =
            flutter.minSdkVersion
        targetSdk =
            flutter.targetSdkVersion

        versionCode =
            flutter.versionCode
        versionName =
            flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias =
                keystoreProperties[
                    "keyAlias"
                ] as String

            keyPassword =
                keystoreProperties[
                    "keyPassword"
                ] as String

            storeFile =
                keystoreProperties[
                    "storeFile"
                ]?.let {
                    file(it)
                }

            storePassword =
                keystoreProperties[
                    "storePassword"
                ] as String
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName(
                    "release"
                )
        }
    }
}

flutter {
    source = "../.."
}