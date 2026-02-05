# Your existing Qoreid rules
-keep class com.qoreid.sdk.** { *; }

# Keep Guava and reflection classes (fixes the R8 error)
-dontwarn java.lang.reflect.AnnotatedType
-keep class java.lang.** { *; }
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**

# Keep reflection attributes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Firebase rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Your existing optimization settings
-dontshrink
-dontobfuscate
-dontoptimize