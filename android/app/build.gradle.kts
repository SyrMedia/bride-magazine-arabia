// android/app/build.gradle.kts
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// نحاول التحميل من مكانين: android/key.properties أو key.properties
val keystoreProperties = Properties()
val keyPropsAndroid = rootProject.file("android/key.properties")
val keyPropsRoot = rootProject.file("key.properties")
val hasKeyProps: Boolean = when {
    keyPropsAndroid.exists() -> { keystoreProperties.load(FileInputStream(keyPropsAndroid)); true }
    keyPropsRoot.exists()    -> { keystoreProperties.load(FileInputStream(keyPropsRoot)); true }
    else -> false
}

android {
    namespace = "com.bma.arabia"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    defaultConfig {
        applicationId = "com.bma.arabia"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeyProps) {
                val p = keystoreProperties.getProperty("storeFile") ?: ""
                if (p.isNotBlank()) storeFile = file(p) // نسبي إلى android/app
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias      = keystoreProperties.getProperty("keyAlias")
                keyPassword   = keystoreProperties.getProperty("keyPassword")
                // storeType = "JKS" // اختياري
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // debug يوقّع تلقائيًا (لا نغيّر)
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            signingConfig = if (hasKeyProps) signingConfigs.getByName("release")
            else signingConfigs.getByName("debug")

            // ---------------------
            // Enable R8 / ProGuard
            // ---------------------
            // فعّل minify (R8) و shrink resources، واربط ملفات القواعد
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // يمكنك الاحتفاظ ببعض القيم كما كانت
            // مثلاً: shrinkResources = true (مفعّل أعلاه)
        }
    }

    // (اختياري) إذا أردت تعيين flavorDimensions أو productFlavors ضعها هنا
}

flutter {
    source = "../.."
}

// ... (الكود السابق)

// near the bottom of android/app/build.gradle.kts (بعد تعريف android { ... })
dependencies {
    // إصدارات Core القديمة غير المتوافقة مع SDK 34 (يجب حذفها أو تعليقها)
    // // implementation("com.google.android.play:core:1.10.3")
    // // implementation("com.google.android.play:core-ktx:1.8.1")

    // الحل: استخدام المكتبات المنفصلة (Per-Feature Libraries) وهي الطريقة الموصى بها،
    // أو استخدام أحدث إصدار من المكتبة المتكاملة (Monolithic Library) إذا لم تكن تستخدم ميزات محددة.

    // الخيار 1: استخدام أحدث إصدار مستقر للمكتبة المتكاملة (Monolithic Core Library)
    // *ملاحظة:* تم إيقاف تحديث هذه المكتبة (Core 1.x) اعتباراً من أبريل 2022، ولكن إذا كنت تحتاجها،
    // الإصدار الأحدث المتوفر هو 1.10.3.
    // ولكن نظرًا لعدم توافق هذا الإصدار مع SDK 34، يفضل استخدام الخيار 2.

    // الخيار 2: استخدام المكتبات المنفصلة (Recommended)
    // يجب استبدال المكتبة المتكاملة بمكتبات الميزات المنفصلة بناءً على الميزات التي تستخدمها (App Update, In-App Review, Feature Delivery).

    // إذا كنت تستخدم فقط الميزات الأساسية التي كانت موجودة في core:1.10.3:

    // المكتبة الأساسية لمراجعة التطبيق (In-App Review)
    implementation("com.google.android.play:review:2.0.1")     // أحدث إصدار مستقر حتى الآن
    // المكتبة الأساسية لتحديثات التطبيق (In-App Update)
    implementation("com.google.android.play:app-update:2.1.0")  // أحدث إصدار مستقر حتى الآن

    // إذا كنت تستخدم مكتبات KTX (لـ Kotlin/Flutter) استبدلها أيضاً
    // implementation("com.google.android.play:review-ktx:2.0.1")
    // implementation("com.google.android.play:app-update-ktx:2.1.0")

    // يمكنك إزالة الـ core و core-ktx القديمين نهائياً، والاعتماد على المكتبات المنفصلة.
}
