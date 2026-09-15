package com.focusgate.focus_gate

object Constants {
    const val PREFS_NAME = "focus_gate_prefs"
    const val KEY_TARGET_PACKAGES = "target_packages"
    const val GRACE_UNTIL_PREFIX = "grace_until_"
    const val GRACE_MINUTES_PREFIX = "grace_minutes_"
    const val EXTRA_TARGET_PACKAGE = "target_package"

    const val CHANNEL_INTERCEPTION = "com.focusgate.focus_gate/interception"
    const val CHANNEL_CHALLENGE = "com.focusgate.focus_gate/challenge"

    const val DEFAULT_GRACE_MINUTES = 5
    const val RETRIGGER_DEBOUNCE_MS = 1500L
}
