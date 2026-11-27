# Release-only ProGuard/R8 rules (Yes Sir AI).
#
# Flutter's engine classes are kept by the Flutter Gradle plugin.
# Plugins that reflectively look up classes must be kept explicitly;
# the rules below cover the ones this app ships (Play Billing,
# Supabase/Gotrue, shared_preferences, secure storage, image picker).

# Flutter embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Billing (in_app_purchase_android)
-keep class com.android.billingclient.** { *; }
-keep class com.android.billingclient.api.** { *; }

# Kotlin metadata used by reflection-based serializers
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep generic signatures for Supabase/Gotrue JSON models
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# AndroidX security / secure storage
-keep class androidx.security.crypto.** { *; }

# Flutter deferred components (Play Core) are not used by this app;
# R8 only sees references from the Flutter embedding.
-dontwarn com.google.android.play.core.**
# google_sign_in / Play services reflection
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**


# flutter_local_notifications reschedules via Gson TypeToken; R8
# must keep the plugin + Gson generic signatures (release crashed
# with 'Missing type parameter' on the boot receiver).
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

