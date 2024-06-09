plugins {
    kotlin("jvm") version "1.9.23"
}

group = "io.zheref.bankai.udf"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    implementation(files("../BankaiCore/out/artifacts/BankaiCore_main_jar/BankaiCore.main.jar"))
}

tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(20)
}