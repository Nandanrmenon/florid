package com.nahnah.florid

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.io.File

class MainActivity : FlutterActivity() {
	private val SHIZUKU_CHANNEL = "com.nahnah.florid/shizuku"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		// Battery optimizations channel
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"florid/battery_optimizations"
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"isIgnoringBatteryOptimizations" -> {
					val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
					val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
						powerManager.isIgnoringBatteryOptimizations(packageName)
					} else {
						true
					}
					result.success(isIgnoring)
				}
				else -> result.notImplemented()
			}
		}

		// Shizuku channel
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			SHIZUKU_CHANNEL
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"isShizukuAvailable" -> {
					result.success(isShizukuAvailable())
				}
				"checkPermission" -> {
					result.success(checkShizukuPermission())
				}
				"requestPermission" -> {
					requestShizukuPermission(result)
				}
				"installApk" -> {
					val filePath = call.argument<String>("filePath")
					if (filePath != null) {
						installApkViaShizuku(filePath, result)
					} else {
						result.error("INVALID_ARGUMENT", "File path is required", null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun isShizukuAvailable(): Boolean {
		return try {
			Shizuku.pingBinder()
		} catch (e: Exception) {
			false
		}
	}

	private fun checkShizukuPermission(): Boolean {
		return try {
			if (Shizuku.pingBinder()) {
				Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
			} else {
				false
			}
		} catch (e: Exception) {
			false
		}
	}

	private fun requestShizukuPermission(result: MethodChannel.Result) {
		try {
			if (!Shizuku.pingBinder()) {
				result.success(false)
				return
			}

			if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
				result.success(true)
				return
			}

			// Request permission
			val requestCode = 1
			Shizuku.addRequestPermissionResultListener(object : Shizuku.OnRequestPermissionResultListener {
				override fun onRequestPermissionResult(reqCode: Int, grantResult: Int) {
					if (reqCode == requestCode) {
						Shizuku.removeRequestPermissionResultListener(this)
						result.success(grantResult == PackageManager.PERMISSION_GRANTED)
					}
				}
			})
			Shizuku.requestPermission(requestCode)
		} catch (e: Exception) {
			result.error("PERMISSION_ERROR", e.message, null)
		}
	}

	private fun installApkViaShizuku(filePath: String, result: MethodChannel.Result) {
		try {
			if (!checkShizukuPermission()) {
				result.error("NO_PERMISSION", "Shizuku permission not granted", null)
				return
			}

			val file = File(filePath)
			if (!file.exists()) {
				result.error("FILE_NOT_FOUND", "APK file not found: $filePath", null)
				return
			}

			// Use Shizuku to install the APK
			val success = ShizukuInstaller.installApk(filePath)
			result.success(success)
		} catch (e: Exception) {
			result.error("INSTALL_ERROR", e.message, null)
		}
	}
}
