plugins {
    kotlin("android") version "2.1.21" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure the root build directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Apply custom build directory to each subproject
subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure subprojects evaluate after ":app"
subprojects {
    evaluationDependsOn(":app")
}

// Define a clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
