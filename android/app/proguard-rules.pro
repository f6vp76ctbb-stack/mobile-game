# Optional R8/ProGuard keep rules. Only used when isMinifyEnabled = true in
# android/app/build.gradle.kts. Test a release build after enabling.

# Flutter engine
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Google Mobile Ads (AdMob) + UMP consent
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.ads.**

# Google Play Billing (in_app_purchase)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Firebase / Google Play services (if enabled later)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
