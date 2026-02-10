package com.nahnah.florid

import android.content.Context
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

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
	}
}
