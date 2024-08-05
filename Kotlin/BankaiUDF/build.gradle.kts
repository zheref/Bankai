plugins {
    kotlin("jvm") version "1.9.23"
}

group = "io.zheref.bankai.udf"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    implementation(files("../BankaiCore/out/artifacts/BankaiCore_main_jar/BankaiCore.main.jar"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.4")
}

tasks.test {
    useJUnitPlatform()
}
tasks.named<Test>("test") {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(20)
}