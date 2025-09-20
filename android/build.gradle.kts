allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build output to ../../build (shared Flutter structure)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Ensure every module disables shrinkResources by default
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            buildTypes {
                getByName("release") {
                    isMinifyEnabled = false
                    isShrinkResources = false   // ✅ force-disable resource shrinking
                }
                getByName("debug") {
                    isMinifyEnabled = false
                    isShrinkResources = false   // ✅ also disable in debug
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
