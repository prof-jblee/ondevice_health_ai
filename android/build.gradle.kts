// [1] buildscript 블록 추가 (Chaquopy 플러그인을 가져오기 위해 필요)
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://chaquo.com/maven") } // Chaquopy 저장소
    }
    dependencies {
        // Chaquopy Gradle 플러그인 버전 지정
        classpath("com.chaquo.python:gradle:15.0.1")
        // gradle 버전은 android/settings.gradle.kts id("com.android.application") version 참조
        classpath("com.android.tools.build:gradle:8.9.1") 
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()   

        // [2] 여기에도 Chaquopy 저장소 추가
        maven { url = uri("https://chaquo.com/maven") }     
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

