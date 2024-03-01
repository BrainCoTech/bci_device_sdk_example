-ignorewarnings

-keep class * {
    public private *;
}

## Gson rules
# Gson uses generic type information stored in a class file when working with fields. Proguard
# removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# Gson specific classes
-dontwarn sun.misc.**
#-keep class com.google.gson.stream.** { *; }

# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses with R8 version 3.0 and higher.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

## flutter_local_notification plugin rules
-keep class com.dexterous.** { *; }

## 友盟混淆设置
#-keep class com.umeng.** {*;}
#
#-keep class com.uc.** {*;}

-keepclassmembers class * {
   public <init> (org.json.JSONObject);
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
#-keep class com.zui.** {*;}
#-keep class com.miui.** {*;}
#-keep class com.heytap.** {*;}
#-keep class a.** {*;}
#-keep class com.vivo.** {*;}

#jna
-keep class com.sun.jna.** {
    <fields>;
    <methods>;
}

-keepclassmembers class * extends com.sun.jna.** {
    <fields>;
    <methods>;
}

-dontwarn java.awt.*

-keep class no.nordicsemi.android.dfu.** { *; }

-keep public class tech.brainco.morpheus.R$*{
      public static final int *;
}

#protobuf
-keep class com.google.protobuf.** { *; }
-keep public class * extends com.google.protobuf.** { *; }

#flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep public class * extends io.flutter.embedding.engine.plugins.FlutterPlugin