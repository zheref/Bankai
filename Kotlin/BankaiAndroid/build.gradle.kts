plugins {
    kotlin("jvm") version "1.9.23"
}

group = "io.zheref.bankai.android"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test")
}

tasks.test {
    useJUnitPlatform()
}