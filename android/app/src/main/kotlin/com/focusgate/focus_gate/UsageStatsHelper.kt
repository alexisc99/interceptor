package com.focusgate.focus_gate

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process
import java.util.Calendar

/**
 * Reads today's foreground usage time for a package via Android's
 * UsageStatsManager. Requires the user to grant the special "Usage access"
 * permission from system settings (there is no runtime prompt for it).
 */
object UsageStatsHelper {

    fun hasAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /** Minutes of foreground usage for [packageName] since midnight, or null without access. */
    fun todayUsageMinutes(context: Context, packageName: String): Long? {
        val startOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        return usageMinutesInRange(context, packageName, startOfDay, System.currentTimeMillis())
    }

    /** Minutes of foreground usage for [packageName] within [startMillis, endMillis), or null without access. */
    fun usageMinutesInRange(context: Context, packageName: String, startMillis: Long, endMillis: Long): Long? {
        if (!hasAccess(context)) return null
        if (endMillis <= startMillis) return 0L

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usageStatsManager.queryAndAggregateUsageStats(startMillis, endMillis)
        val totalMs = stats[packageName]?.totalTimeInForeground ?: 0L
        // UsageStatsManager is known to occasionally report inflated totals
        // for older/wider ranges (it aggregates internal buckets that don't
        // always align cleanly with the requested window). A single app can
        // never have been in the foreground longer than the window itself.
        val clampedMs = totalMs.coerceAtMost(endMillis - startMillis)
        return clampedMs / 60_000L
    }

    /**
     * Average minutes per individual session for [packageName] within
     * [startMillis, endMillis), or null without access or if there were no
     * sessions. A "session" runs from when this app genuinely becomes the
     * foreground app until a *different* app takes over — used to estimate
     * time saved by a dissuasion ("what a session usually costs").
     *
     * ACTIVITY_RESUMED/PAUSED fire per-Activity, not per-app: a multi-
     * Activity app like Instagram fires its own resume/pause pair when
     * navigating internally (e.g. opening comments), which would fragment
     * one real session into several tiny ones if paired naively. Instead,
     * every app's RESUMED events are walked in order and a session is only
     * closed when a *different* package's RESUMED event appears — mirroring
     * how [ForegroundAppWatcherService] distinguishes internal navigation
     * from a genuine app switch.
     */
    fun averageSessionMinutes(context: Context, packageName: String, startMillis: Long, endMillis: Long): Double? {
        if (!hasAccess(context)) return null
        if (endMillis <= startMillis) return null

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usageStatsManager.queryEvents(startMillis, endMillis)
        val event = UsageEvents.Event()
        var currentPackage: String? = null
        var sessionStart: Long? = null
        var totalMs = 0L
        var sessionCount = 0

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType != UsageEvents.Event.ACTIVITY_RESUMED) continue
            // System chrome and the keyboard briefly "resume" without the
            // user actually switching apps — same issue this would have if
            // left unfiltered as it caused for foreground-app tracking.
            if (TransientForegroundPackages.isTransient(context, event.packageName)) continue
            if (event.packageName == currentPackage) continue // internal navigation, same session

            val start = sessionStart
            if (currentPackage == packageName && start != null) {
                totalMs += (event.timeStamp - start)
                sessionCount++
            }
            sessionStart = if (event.packageName == packageName) event.timeStamp else null
            currentPackage = event.packageName
        }
        // Still in the target app when the window closed (e.g. querying up
        // to "now" mid-session) — count that ongoing session too, up to
        // endMillis, instead of silently dropping it.
        val start = sessionStart
        if (currentPackage == packageName && start != null) {
            totalMs += (endMillis - start)
            sessionCount++
        }

        if (sessionCount == 0) return null
        return (totalMs.toDouble() / sessionCount) / 60_000.0
    }
}
