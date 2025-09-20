// android/build.gradle.kts

plugins {
    // nothing to apply at root; versions come from settings.gradle.kts
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
