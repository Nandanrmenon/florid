# Dhizuku UserService — class name is passed via ComponentName; R8 must not rename it.
-keep class com.nahnah.florid.FloridDhizukuInstallerService { *; }
-keepclassmembers class com.nahnah.florid.FloridDhizukuInstallerService {
    <init>(android.content.Context);
    <init>();
}

# AIDL-generated Stub/Proxy classes for IPC between app and Dhizuku process
-keep class com.nahnah.florid.IDhizukuInstallerService { *; }
-keep class com.nahnah.florid.IDhizukuInstallerService$Stub { *; }
-keep class com.nahnah.florid.IDhizukuInstallerService$Stub$Proxy { *; }

# Dhizuku library internals
-keep class com.rosan.dhizuku.** { *; }
-dontwarn com.rosan.dhizuku.**
