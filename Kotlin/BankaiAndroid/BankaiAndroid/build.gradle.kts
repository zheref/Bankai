plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

object Versions {
    const val gradleTools = "4.2.0-alpha12"
    const val compileSdk = 30
    const val targetSdk = compileSdk
    const val minSdk = 23
    const val buildTools = "$compileSdk.0.2"

    const val kotlin = "1.9.0"
    const val core = "1.5.0-alpha02"
    const val core_ktx = core
    const val lifecycle = "2.2.0"
    const val composeCompiler = "1.5.1"
    const val composeLib = "1.6.7"
    const val junit = "4.12"
    const val material = "1.2.1"
    const val appcompat = "1.7.0"
}

android {
    namespace = "io.zheref.bankai.android"
    compileSdk = 34

    defaultConfig {
        minSdk = 29

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }

    composeOptions {
        kotlinCompilerExtensionVersion = Versions.composeCompiler
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:${Versions.appcompat}")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.2")

    implementation("androidx.compose.ui:ui:${Versions.composeLib}")
    implementation("androidx.compose.ui:ui-tooling:${Versions.composeLib}")
    implementation("androidx.compose.material:material:${Versions.composeLib}")
    implementation("androidx.compose.runtime:runtime-livedata:${Versions.composeLib}")

    compileOnly("io.zheref.bankai.udf:BankaiUDF")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.4")

    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.4")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("org.mockito:mockito-core:3.+")
    androidTestImplementation("org.mockito.kotlin:mockito-kotlin:3.+")
}