// android/build.gradle.kts  (ROOT)

import java.io.File
import org.gradle.api.tasks.Delete

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
    // Google Services على مستوى المشروع
    id("com.google.gms.google-services") version "4.4.2" apply false
}

// نخلي كل مخرجات الـ build تحت مجلد المشروع الرئيسي مثل قالب Flutter الأصلي
rootProject.buildDir = rootDir.resolve("../build")

subprojects {
    // كل مشروع فرعي (مثل :app) نحطله مجلد build خاصه جوّا ../build
    project.buildDir = File(rootProject.buildDir, project.name)
    project.evaluationDependsOn(":app")
}

// task clean
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
