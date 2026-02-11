package com.nahnah.florid

import android.content.pm.IPackageInstaller
import android.content.pm.IPackageManager
import android.content.pm.PackageInstaller
import android.os.ParcelFileDescriptor
import rikka.shizuku.ShizukuBinderWrapper
import rikka.shizuku.SystemServiceHelper
import java.io.File
import java.io.FileInputStream

object ShizukuInstaller {
    
    fun installApk(apkPath: String): Boolean {
        return try {
            val file = File(apkPath)
            if (!file.exists()) {
                return false
            }

            // Get IPackageManager through Shizuku
            val iPackageManager = IPackageManager.Stub.asInterface(
                ShizukuBinderWrapper(SystemServiceHelper.getSystemService("package"))
            )
            
            // Get the package installer
            val iPackageInstaller = IPackageInstaller.Stub.asInterface(
                ShizukuBinderWrapper(iPackageManager.packageInstaller.asBinder())
            )
            
            // Create installation session parameters
            val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
            
            // Create the session
            val sessionId = iPackageInstaller.createSession(params, "com.nahnah.florid", null, 0)
            
            // Open the session
            val sessionBinder = iPackageInstaller.openSession(sessionId)
            val session = android.content.pm.IPackageInstallerSession.Stub.asInterface(
                ShizukuBinderWrapper(sessionBinder.asBinder())
            )
            
            // Open write stream for the APK
            val pfd = ParcelFileDescriptor.open(
                file,
                ParcelFileDescriptor.MODE_READ_ONLY
            )
            
            // Write the APK data to the session
            val inputStream = FileInputStream(pfd.fileDescriptor)
            try {
                val out = session.openWrite("base.apk", 0, file.length())
                val outputStream = ParcelFileDescriptor.AutoCloseOutputStream(out)
                try {
                    val buffer = ByteArray(65536)
                    var bytesRead: Int
                    while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                        outputStream.write(buffer, 0, bytesRead)
                    }
                    outputStream.flush()
                    session.fsync(out)
                } finally {
                    outputStream.close()
                }
            } finally {
                inputStream.close()
            }
            
            pfd.close()
            
            // Commit the session to install
            session.commit(null, 0)
            session.close()
            
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
