package com.focusgate.focus_gate

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.accessibility.AccessibilityEvent

private const val TAG = "FocusGateService"

/**
 * Watches which app comes to the foreground. When a "targeted" app is about to
 * open, it sends the user home and opens [ChallengeActivity] instead, which only
 * lets the target app launch once its challenge is solved.
 */
class ForegroundAppWatcherService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private val recentlyTriggered = mutableMapOf<String, Long>()
    private var lastForegroundPackage: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences(Constants.PREFS_NAME, MODE_PRIVATE)
        Log.i(TAG, "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return
        Log.d(TAG, "Window state changed: $packageName")
        if (packageName == applicationContext.packageName) return
        if (TransientForegroundPackages.isTransient(applicationContext, packageName)) return

        // Apps like Instagram fire more TYPE_WINDOW_STATE_CHANGED events for
        // their own internal navigation (opening a comments sheet, a new
        // tab, ...) without ever actually leaving the app. Only re-evaluate
        // the grace period on a genuine switch into a different foreground
        // app — otherwise a long session past the grace window gets
        // re-challenged on the next in-app navigation despite never having
        // left.
        val previousPackage = lastForegroundPackage
        lastForegroundPackage = packageName
        if (packageName == previousPackage) {
            Log.d(TAG, "Still in $packageName, skipping re-evaluation")
            return
        }

        handleForegroundApp(packageName)
    }

    private fun handleForegroundApp(packageName: String) {
        val targets = prefs.getStringSet(Constants.KEY_TARGET_PACKAGES, emptySet()) ?: emptySet()
        if (packageName !in targets) return
        Log.i(TAG, "Target app detected: $packageName")

        val graceUntil = prefs.getLong(Constants.GRACE_UNTIL_PREFIX + packageName, 0L)
        val now = System.currentTimeMillis()
        if (now < graceUntil) {
            Log.i(TAG, "Within grace period for $packageName, skipping")
            return
        }

        val lastTrigger = recentlyTriggered[packageName] ?: 0L
        if (now - lastTrigger < Constants.RETRIGGER_DEBOUNCE_MS) {
            // Don't re-launch ChallengeActivity (it would stack/flicker on
            // top of the one that likely just finished), but don't just
            // leave the target app sitting on screen either — that let
            // someone bypass the challenge entirely by reopening the app
            // fast enough to land inside this window. Send it home instead.
            Log.i(TAG, "Debounced trigger for $packageName, sending home instead of re-showing the challenge")
            performGlobalAction(GLOBAL_ACTION_HOME)
            return
        }
        recentlyTriggered[packageName] = now

        Log.i(TAG, "Launching ChallengeActivity for $packageName")

        val intent = Intent(this, ChallengeActivity::class.java).apply {
            putExtra(Constants.EXTRA_TARGET_PACKAGE, packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        try {
            startActivity(intent)
            Log.i(TAG, "startActivity(ChallengeActivity) called successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start ChallengeActivity", e)
        }
    }

    override fun onInterrupt() {}
}
