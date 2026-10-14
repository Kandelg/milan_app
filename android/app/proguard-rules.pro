# ---------------------------------------------------------------------------
# Flutter / ProGuard rules for release builds
# Your plugins ship their own consumer-rules.pro, so most classes are kept
# automatically. The rules below are the standard, safe set that Flutter +
# common plugins expect.
# ---------------------------------------------------------------------------

# --- Flutter engine ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- Play Core (referenced by Flutter deferred components) ---
-dontwarn com.google.android.play.core.**

# --- Keep annotations & signatures (safe; helps any reflection-based lib) ---
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
