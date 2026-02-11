package com.nahnah.florid

import android.content.pm.IPackageInstaller
import android.content.pm.IPackageInstallerSession
import android.content.pm.PackageInstaller
import android.os.Build
import rikka.shizuku.Shizuku
import rikka.shizuku.ShizukuBinderWrapper
import rikka.shizuku.SystemServiceHelper
import java.io.File
import java.io.FileInputStream

object ShizukuInstaller {
    
    fun installApk(apkPath: String): Boolean {
        try {
            val file = File(apkPath)
            if (!file.exists()) {
                return false
            }

            // Get IPackageManager through Shizuku
            val packageManager = IPackageInstaller.Stub.asInterface(
                ShizukuBinderWrapper(
                    SystemServiceHelper.getSystemService("package")
                        .let { 
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                it.getClass().getMethod("getPackageInstaller").invoke(it) as android.os.IBinder
                            } else {
                                it.getClass().getMethod("getPackageInstaller").invoke(it) as android.os.IBinder
                            }
                        }
                )
            )

            // Create session
            val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
            val sessionId = packageManager.createSession(params, "com.nahnah.florid", null, 0)
            
            val session = IPackageInstallerSession.Stub.asInterface(
                ShizukuBinderWrapper(packageManager.openSession(sessionId).asBinder())
            )

            // Write APK to session
            FileInputStream(file).use { input ->
                session.openWrite("base.apk", 0, -1).use { output ->
                    input.copyTo(output)
                    session.fsync(output)
                }
            }

            // Commit the session
            session.commit(null, 0)
            session.close()

            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
}
