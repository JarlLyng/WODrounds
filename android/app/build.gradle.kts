import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

// The Sentry DSN stays out of the repo, as Sentry.xcconfig does on iOS: the environment's
// SENTRY_DSN, else `sentry.dsn` in the gitignored local.properties. Empty means no Sentry.
val localProps = Properties().apply {
    rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}
val sentryDsn: String = System.getenv("SENTRY_DSN") ?: localProps.getProperty("sentry.dsn", "")
// `production` only for a build meant for the store, so internal and debug runs aren't read
// as real crashes (iOS splits on TestFlight's receipt; Play has no such signal).
val sentryEnvironment: String = System.getenv("WODROUNDS_SENTRY_ENVIRONMENT") ?: "internal"

android {
    namespace = "com.iamjarl.wodrounds"
    compileSdk = 36

    defaultConfig {
        // The final ID (owner, 2026-11-22): permanent from the first upload to Play.
        applicationId = "com.iamjarl.wodrounds"
        minSdk = 29
        targetSdk = 36
        versionCode = 2
        versionName = "0.2-trial"
        buildConfigField("String", "SENTRY_DSN", "\"$sentryDsn\"")
    }

    // The upload key lives outside the repo. Release builds read its path and password from
    // the environment (android/scripts/bundle-release.sh fills them from the macOS keychain);
    // Play App Signing holds the app signing key. Debug builds need none of it.
    signingConfigs {
        create("upload") {
            System.getenv("WODROUNDS_UPLOAD_STORE")?.let { storeFile = file(it) }
            storePassword = System.getenv("WODROUNDS_UPLOAD_PASSWORD")
            keyAlias = "upload"
            keyPassword = System.getenv("WODROUNDS_UPLOAD_PASSWORD")
        }
    }

    buildTypes {
        debug {
            buildConfigField("String", "SENTRY_ENVIRONMENT", "\"debug\"")
        }
        release {
            if (System.getenv("WODROUNDS_UPLOAD_STORE") != null) signingConfig = signingConfigs.getByName("upload")
            buildConfigField("String", "SENTRY_ENVIRONMENT", "\"$sentryEnvironment\"")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.05.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.12.4")
    implementation("androidx.core:core-ktx:1.16.0")
    // Crash reports and crash-free sessions only: the core SDK, without NDK, replay or
    // the Gradle plugin. Anonymous by Telemetry.kt (docs/SENTRY.md).
    implementation("io.sentry:sentry-android-core:8.63.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("com.google.code.gson:gson:2.11.0")
}

// The shared timelines live outside android/ so the Swift tests read the same file.
tasks.withType<Test>().configureEach {
    systemProperty("engineTimelines", rootProject.file("../test-fixtures/engine-timelines.json").absolutePath)
    inputs.file(rootProject.file("../test-fixtures/engine-timelines.json"))
}
