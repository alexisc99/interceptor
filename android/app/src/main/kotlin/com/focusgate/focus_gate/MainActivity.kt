package com.focusgate.focus_gate

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.CHANNEL_INTERCEPTION)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(Constants.PREFS_NAME, MODE_PRIVATE)
                when (call.method) {
                    "setTargetPackages" -> {
                        @Suppress("UNCHECKED_CAST")
                        val packages = (call.arguments as List<String>).toSet()
                        prefs.edit().putStringSet(Constants.KEY_TARGET_PACKAGES, packages).apply()
                        result.success(null)
                    }
                    "setGraceMinutes" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as Map<String, Any>
                        val pkg = args["package"] as String
                        val minutes = args["minutes"] as Int
                        prefs.edit().putInt(Constants.GRACE_MINUTES_PREFIX + pkg, minutes).apply()
                        result.success(null)
                    }
                    "isAccessibilityServiceEnabled" -> {
                        result.success(AccessibilityUtils.isServiceEnabled(this))
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
