package com.focusgate.focus_gate

import android.content.Context
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings

/**
 * Packages that can briefly report themselves as the foreground app/window
 * without the user actually switching away from whatever they were using:
 * system chrome (status bar, nav gestures, notification shade, immersive-
 * mode flashes) and the on-screen keyboard. Used by both foreground-app
 * tracking ([ForegroundAppWatcherService]) and session-length reconstruction
 * ([UsageStatsHelper]) — kept in one place so a fix to one doesn't silently
 * miss the other, as happened once already.
 */
object TransientForegroundPackages {
    private val systemPackages = setOf("com.android.systemui")

    // The on-screen keyboard's package, cached instead of queried via
    // Settings.Secure (a Binder IPC to the Settings provider) on every call —
    // isTransient() runs on every window-state-change event device-wide, so
    // that IPC was paid far more often than the keyboard actually changes.
    // Kept fresh by a ContentObserver instead of polling/staleness, so this
    // stays exactly as accurate as the old per-call query.
    @Volatile private var cachedImePackage: String? = null
    @Volatile private var observerRegistered = false

    fun isTransient(context: Context, packageName: String): Boolean {
        return packageName in systemPackages || packageName == currentImePackage(context)
    }

    private fun currentImePackage(context: Context): String? {
        ensureObserver(context)
        return cachedImePackage
    }

    @Synchronized
    private fun ensureObserver(context: Context) {
        if (observerRegistered) return
        observerRegistered = true
        val appContext = context.applicationContext
        refreshImePackage(appContext)
        val uri = Settings.Secure.getUriFor(Settings.Secure.DEFAULT_INPUT_METHOD)
        appContext.contentResolver.registerContentObserver(
            uri,
            false,
            object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) {
                    refreshImePackage(appContext)
                }
            },
        )
    }

    private fun refreshImePackage(context: Context) {
        cachedImePackage = try {
            Settings.Secure.getString(context.contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
                ?.substringBefore('/')
        } catch (e: Exception) {
            null
        }
    }
}
