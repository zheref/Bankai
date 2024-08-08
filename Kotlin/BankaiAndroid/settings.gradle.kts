pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "BankaiAndroid"
include(":app")
include(":BankaiAndroid")

includeBuild("../BankaiCore")
includeBuild("../BankaiUDF")