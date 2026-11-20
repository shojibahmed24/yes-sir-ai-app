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
