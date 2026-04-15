plugins {
    // We remove the version="..." part so it uses the one already on the classpath
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

// Apply common Android SDK versions to all Android modules.
subprojects {
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null && android is com.android.build.gradle.BaseExtension) {
            android.compileSdkVersion(34)
            android.buildToolsVersion("34.0.0")

            android.defaultConfig {
                minSdkVersion(21)
                targetSdkVersion(34)
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Standard clean task for generated build output.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
