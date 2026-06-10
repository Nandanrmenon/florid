package com.nahnah.florid

import android.content.Context
import android.content.pm.PackageManager
import com.rosan.dhizuku.api.Dhizuku
import com.rosan.dhizuku.api.DhizukuRequestPermissionListener
import java.util.concurrent.atomic.AtomicBoolean

class DhizukuHelper(private val context: Context) {
    private val installManager = DhizukuInstallManager(context)

    fun init(): Boolean = Dhizuku.init(context)

    fun isPermissionGranted(): Boolean {
        if (!init()) {
            return false
        }
        return Dhizuku.isPermissionGranted()
    }

    fun requestPermission(onResult: (Boolean) -> Unit) {
        val completed = AtomicBoolean(false)
        fun complete(granted: Boolean) {
            if (completed.compareAndSet(false, true)) {
                onResult(granted)
            }
        }

        if (!init()) {
            complete(false)
            return
        }
        if (Dhizuku.isPermissionGranted()) {
            complete(true)
            return
        }
        Dhizuku.requestPermission(object : DhizukuRequestPermissionListener() {
            override fun onRequestPermission(grantResult: Int) {
                complete(grantResult == PackageManager.PERMISSION_GRANTED)
            }
        })
    }

    fun installApk(apkPath: String): String = installManager.installApk(apkPath)
}
