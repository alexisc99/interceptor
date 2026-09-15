package com.focusgate.focus_gate

import android.app.AppOpsManager
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
        if (!hasAccess(context)) return null

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val startOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val now = System.currentTimeMillis()

        val stats = usageStatsManager.queryAndAggregateUsageStats(startOfDay, now)
        val totalMs = stats[packageName]?.totalTimeInForeground ?: 0L
        return totalMs / 60_000L
    }
}
