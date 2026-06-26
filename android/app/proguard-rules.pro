# proguard-rules.pro
# قواعد ابتدائية لـ R8/ProGuard تناسب Flutter + Firebase + شبكات HTTP
# راجع الإضافات (plugins) لديك وأضف قواعد إضافية إذا ظهرت تحطّمات.

# ===== Flutter core & embedding =====
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep platform channels and GeneratedPluginRegistrant
-keep class io.flutter.plugins.registrant.** { *; }
-keep class io.flutter.plugins.** { *; }

# ===== Firebase (Messaging / Core / Analytics) =====
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class com.google.firebase.iid.FirebaseInstanceId { *; }
-keep class com.google.firebase.messaging.FirebaseMessaging { *; }

# ===== Kotlin metadata =====
-keepclassmembers class kotlin.Metadata { *; }

# ===== Reflection / JSON mappers (Gson / Moshi / Jackson) =====
# If you use Gson with @SerializedName, keep fields annotated
-keep class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
# Keep classes that may be used by reflection (adjust package if needed)
-keepclassmembers class * {
    public <init>(...);
}

# ===== Native methods =====
-keepclasseswithmembers class * {
    native <methods>;
}

# ===== OkHttp / Retrofit warnings =====
-dontwarn okio.**
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# ===== Protobuf / Generated code (if any) =====
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# ===== Keep model classes used by platform channels (adjust your package) =====
#-keep class your.package.name.** { *; }

# ===== Misc safe defaults (reduces aggressive obfuscation risk) =====
# Keep annotation retention
-keep @interface * { *; }

# ===== If you see missing classes at runtime, add explicit -keep for them =====

# Keep Play Core (SplitInstall / SplitCompat) used by Flutter deferred components
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**
