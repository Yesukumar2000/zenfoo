#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface
-keepattributes *Annotation*

-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

-optimizations !method/inlining/*

-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# Fix for SharedPreferences pigeon channel issue
# See: https://github.com/flutter/flutter/issues/153075
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin {
    public static void registerWith(...);
    public <init>();
}

# Keep all pigeon generated code
-keep class ** extends io.flutter.plugin.common.GeneratedCodec { *; }
-keep interface io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep method names for pigeon methods
-keepclassmembernames class * {
    @dev.flutter.pigeon.* *;
}

# Keep generated pigeon adapters
-keep class **$GeneratedCodec { *; }
-keep class **Api { *; }
-keep interface **Api { *; }

# Paytm SDK
-keep class com.paytm.** { *; }
-keep class com.paytm.pgsdk.** { *; }
-keep class net.one97.paytm.** { *; }