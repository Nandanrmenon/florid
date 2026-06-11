package com.nahnah.florid

import android.content.Context
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterFragmentActivity() {
	private lateinit var dhizukuHelper: DhizukuHelper
	private val dhizukuExecutor = Executors.newSingleThreadExecutor()

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		dhizukuHelper = DhizukuHelper(this)

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

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"florid/dhizuku"
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"pingBinder" -> {
					result.success(dhizukuHelper.init())
				}
				"checkPermission" -> {
					try {
						result.success(dhizukuHelper.isPermissionGranted())
					} catch (e: Exception) {
						result.success(false)
					}
				}
				"requestPermission" -> {
					val replied = AtomicBoolean(false)
					dhizukuHelper.requestPermission { granted ->
						runOnUiThread {
							if (replied.compareAndSet(false, true)) {
								result.success(granted)
							}
						}
					}
				}
				"installApk" -> {
					val path = call.argument<String>("path")
					if (path == null) {
						result.error("INVALID_ARGUMENT", "path is required", null)
						return@setMethodCallHandler
					}
					dhizukuExecutor.execute {
						try {
							val output = dhizukuHelper.installApk(path)
							runOnUiThread { result.success(output) }
						} catch (e: Exception) {
							runOnUiThread {
								result.error("DHIZUKU_ERROR", e.message, null)
							}
						}
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
