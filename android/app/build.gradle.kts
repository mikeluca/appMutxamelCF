import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()

if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    // FL-09: aviso bien visible en el log del build. No se hace fallar la
    // tarea porque assembleRelease/bundleRelease es la misma tarea tanto
    // para `flutter run --release` en una máquina de desarrollo (sin
    // keystore) como para el artefacto real que se sube a la Play
    // Store; un hard-fail aquí rompería ese primer caso, que es
    // intencionado (ver comentario en buildTypes.release más abajo).
    logger.warn(
        "\n" +
            "==================================================================\n" +
            "AVISO: no existe android/key.properties. El APK/AAB de 'release'\n" +
            "se va a firmar con la clave de DEBUG. NUNCA subas este artefacto\n" +
            "a la Play Store -- solo sirve para probar en un dispositivo.\n" +
            "==================================================================\n"
    )
}

android {
    namespace = "com.mutxamelcf.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Necesario para flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mutxamelcf.app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Firma con la clave de producción si existe android/key.properties
            // (no se sube al repositorio). Si no existe, cae de vuelta a la
            // clave de debug para que `flutter run --release` siga funcionando
            // en máquinas de desarrollo sin el keystore.
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    // Necesario para flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}