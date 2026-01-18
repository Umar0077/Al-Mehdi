# Added to fix R8 missing class errors
-dontwarn com.facebook.imagepipeline.nativecode.WebpTranscoder
-dontwarn kotlinx.parcelize.Parcelize

# Keep Firestore model classes and their fields
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Keep all Firestore serialization
-keep class com.google.firebase.firestore.** { *; }
-keepclassmembers class * {
    @com.google.firebase.firestore.** <methods>;
    @com.google.firebase.firestore.** <fields>;
}

# Keep all data classes used with Firestore
-keep class com.almehdi.onlineschool.models.** { *; }
-keepclassmembers class com.almehdi.onlineschool.models.** { *; }

# Keep Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Keep generic signatures for Firestore
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep Flutter-related classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.** 

# Jitsi Meet SDK rules
-keep class org.jitsi.meet.** { *; }
-keep class org.jitsi.meet.sdk.** { *; }
-keep class com.facebook.react.** { *; }
-keep class com.facebook.hermes.** { *; }
-keep class com.oney.** { *; }
-dontwarn org.jitsi.meet.**
-dontwarn com.facebook.react.**
-dontwarn com.facebook.hermes.**

# WebRTC
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep JitsiMeetSDK Bridge
-keep class com.gustavocmarques.jitsimeetfluttersdk.** { *; }
-keep class jitsi_meet_flutter_sdk.** { *; }