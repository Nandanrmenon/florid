package com.nahnah.florid

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.RemoteException
import android.util.Log
import androidx.annotation.Keep
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

@Keep
class FloridDhizukuInstallerService @JvmOverloads constructor(
    private val serviceContext: Context? = null,
) : IDhizukuInstallerService.Stub() {

    companion object {
        const val STATUS_SUCCESS = 0
        const val STATUS_FAILURE = -1
        const val STATUS_PENDING_USER_ACTION_REQUIRED = -2

        private const val TAG = "FloridDhizuku"
        private const val DHIZUKU_PACKAGE = "com.rosan.dhizuku"
        private const val INSTALL_TIMEOUT_SECONDS = 120L
        private const val ACTION_INSTALL_RESULT = "com.nahnah.florid.dhizuku.INSTALL_RESULT"
    }

    override fun installPackage(
        pfd: ParcelFileDescriptor,
        fileSize: Long,
        expectedPackageName: String?,
        expectedVersionCode: Long,
        installerPackageName: String?,
    ): Int {
        Log.d(
            TAG,
            "installPackage size=$fileSize expected=$expectedPackageName@$expectedVersionCode " +
                "installer=$installerPackageName uid=${android.os.Process.myUid()}",
        )

        val ctx = resolveContext() ?: run {
            Log.e(TAG, "No application context in Dhizuku process")
            throw RemoteException("No application context in Dhizuku process")
        }
        Log.d(TAG, "using context pkg=${ctx.packageName} uid=${android.os.Process.myUid()}")

        val installer = ctx.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            params.setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
        }
        if (fileSize > 0) {
            params.setSize(fileSize)
        }
        installerPackageName?.takeIf { it.isNotBlank() }?.let { name ->
            try {
                params.setInstallerPackageName(name)
            } catch (e: Exception) {
                Log.w(TAG, "setInstallerPackageName($name) failed: ${e.message}")
            }
        }

        var sessionId = -1
        var session: PackageInstaller.Session? = null
        var receiver: BroadcastReceiver? = null
        var committed = false
        var installError: String? = null
        return try {
            sessionId = installer.createSession(params)
            Log.d(TAG, "createSession id=$sessionId pkg=${ctx.packageName}")
            session = installer.openSession(sessionId)

            session.openWrite("apk", 0, fileSize).use { out ->
                ParcelFileDescriptor.AutoCloseInputStream(pfd).use { input ->
                    val copied = input.copyTo(out)
                    out.flush()
                    session.fsync(out)
                    Log.d(TAG, "streamed $copied bytes to session")
                }
            }

            val latch = CountDownLatch(1)
            val resultRef = AtomicInteger(STATUS_FAILURE)
            val token = UUID.randomUUID().toString()
            val action = "$ACTION_INSTALL_RESULT.$token"

            receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    val status = intent.getIntExtra(
                        PackageInstaller.EXTRA_STATUS,
                        PackageInstaller.STATUS_FAILURE,
                    )
                    val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
                    Log.d(TAG, "install callback status=$status message=$message")
                    when (status) {
                        PackageInstaller.STATUS_SUCCESS -> resultRef.set(STATUS_SUCCESS)
                        PackageInstaller.STATUS_PENDING_USER_ACTION ->
                            resultRef.set(STATUS_PENDING_USER_ACTION_REQUIRED)
                        else -> {
                            installError = message ?: "PackageInstaller status=$status"
                            resultRef.set(STATUS_FAILURE)
                        }
                    }
                    latch.countDown()
                }
            }
            registerInternalReceiver(ctx, receiver, action)

            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(
                ctx,
                token.hashCode(),
                Intent(action).setPackage(ctx.packageName),
                pendingFlags,
            )

            session.commit(pendingIntent.intentSender)
            committed = true
            Log.d(TAG, "session.commit sent, awaiting callback")

            val finished = latch.await(INSTALL_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            val result = if (!finished) {
                Log.w(TAG, "install timed out after ${INSTALL_TIMEOUT_SECONDS}s")
                if (verifyInstallSucceeded(
                        ctx,
                        installer,
                        sessionId,
                        expectedPackageName,
                        expectedVersionCode,
                    )
                ) {
                    STATUS_SUCCESS
                } else {
                    installError = "Install timed out"
                    STATUS_FAILURE
                }
            } else {
                resultRef.get()
            }
            if (result != STATUS_SUCCESS && result != STATUS_PENDING_USER_ACTION_REQUIRED) {
                throw RemoteException(installError ?: "Install failed with code $result")
            }
            result
        } catch (e: RemoteException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "installPackage exception", e)
            throw RemoteException(e.message ?: e.javaClass.simpleName)
        } finally {
            if (!committed && sessionId >= 0) {
                try {
                    installer.abandonSession(sessionId)
                } catch (_: Exception) {
                }
            }
            try {
                session?.close()
            } catch (_: Exception) {
            }
            if (receiver != null) {
                try {
                    ctx.unregisterReceiver(receiver)
                } catch (_: Exception) {
                }
            }
        }
    }

    override fun uninstallPackage(packageName: String?): Int {
        if (packageName.isNullOrBlank()) {
            return STATUS_SUCCESS
        }
        return STATUS_FAILURE
    }

    override fun destroy() {}

    private fun resolveContext(): Context? {
        serviceContext?.let { ctx ->
            return ctx.applicationContext ?: ctx
        }
        val app = currentApplicationOrNull()
        if (app?.packageName == DHIZUKU_PACKAGE) {
            return app.applicationContext ?: app
        }
        return null
    }

    private fun verifyInstallSucceeded(
        ctx: Context,
        installer: PackageInstaller,
        sessionId: Int,
        expectedPackageName: String?,
        expectedVersionCode: Long,
    ): Boolean {
        val targetPackage = expectedPackageName?.takeIf { it.isNotBlank() }
            ?: runCatching { installer.getSessionInfo(sessionId)?.appPackageName }
                .onFailure { Log.e(TAG, "getSessionInfo() failed during verification", it) }
                .getOrNull()
            ?: return false
        val info = packageInfoOrNull(ctx, targetPackage) ?: return false
        if (expectedVersionCode <= 0L) return true
        val installedVersion = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return installedVersion >= expectedVersionCode
    }

    private fun packageInfoOrNull(ctx: Context, packageName: String) = try {
        ctx.packageManager.getPackageInfo(packageName, 0)
    } catch (_: Exception) {
        null
    }

    private fun currentApplicationOrNull(): Context? = try {
        val cls = Class.forName("android.app.ActivityThread")
        cls.getMethod("currentApplication").invoke(null) as? Context
    } catch (e: Exception) {
        try {
            val cls = Class.forName("android.app.AppGlobals")
            cls.getMethod("getInitialApplication").invoke(null) as? Context
        } catch (_: Exception) {
            Log.e(TAG, "Failed to obtain Application context", e)
            null
        }
    }

    private fun registerInternalReceiver(ctx: Context, receiver: BroadcastReceiver, action: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ctx.registerReceiver(receiver, IntentFilter(action), Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            ctx.registerReceiver(receiver, IntentFilter(action))
        }
    }
}
