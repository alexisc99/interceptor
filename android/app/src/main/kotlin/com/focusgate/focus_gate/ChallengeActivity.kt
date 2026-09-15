package com.focusgate.focus_gate

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val TAG = "FocusGateChallenge"

/**
 * Full-screen activity shown instead of a targeted app. Hosts its own Flutter
 * engine (entrypoint: challengeMain) that renders the challenge UI.
 */
class ChallengeActivity : FlutterActivity() {

    private val targetPackage: String by lazy {
        intent.getStringExtra(Constants.EXTRA_TARGET_PACKAGE) ?: ""
    }

    override fun getDartEntrypointFunctionName(): String = "challengeMain"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.i(TAG, "onCreate, targetPackage=$targetPackage")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.i(TAG, "configureFlutterEngine")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.CHANNEL_CHALLENGE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTargetPackage" -> result.success(targetPackage)
                    "getTodayUsageMinutes" -> {
                        result.success(UsageStatsHelper.todayUsageMinutes(this, targetPackage)?.toInt())
                    }
                    "onChallengeSolved" -> {
                        onChallengeSolved()
                        result.success(null)
                    }
                    "onChallengeCancelled" -> {
                        onChallengeCancelled()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun onChallengeSolved() {
        val prefs = getSharedPreferences(Constants.PREFS_NAME, MODE_PRIVATE)
        val graceMinutes = prefs.getInt(
            Constants.GRACE_MINUTES_PREFIX + targetPackage,
            Constants.DEFAULT_GRACE_MINUTES
        )
        val graceUntil = System.currentTimeMillis() + graceMinutes * 60_000L
        prefs.edit().putLong(Constants.GRACE_UNTIL_PREFIX + targetPackage, graceUntil).apply()

        val launchIntent = packageManager.getLaunchIntentForPackage(targetPackage)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
        }
        finish()
    }

    private fun onChallengeCancelled() {
        // Just finishing would reveal the target app's own (already-created)
        // window right underneath, which immediately re-triggers us. Go home
        // instead so "cancel" actually leaves the target app.
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(homeIntent)
        finish()
    }

    // Prevent trivially bypassing the challenge with the system back gesture/button.
    @Suppress("DEPRECATION")
    override fun onBackPressed() {}
}
