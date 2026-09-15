import 'package:flutter/services.dart';

/// Bridge to the native side from the main app: syncs which apps are
/// targeted and their grace period, and manages the accessibility permission.
class InterceptionChannel {
  InterceptionChannel._();

  static const _channel = MethodChannel('com.focusgate.focus_gate/interception');

  static Future<void> setTargetPackages(Iterable<String> packages) {
    return _channel.invokeMethod('setTargetPackages', packages.toList());
  }

  static Future<void> setGraceMinutes(String packageName, int minutes) {
    return _channel.invokeMethod('setGraceMinutes', {
      'package': packageName,
      'minutes': minutes,
    });
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    final result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
    return result ?? false;
  }

  static Future<void> openAccessibilitySettings() {
    return _channel.invokeMethod('openAccessibilitySettings');
  }

  static Future<bool> hasUsageAccess() async {
    final result = await _channel.invokeMethod<bool>('hasUsageAccess');
    return result ?? false;
  }

  static Future<void> openUsageAccessSettings() {
    return _channel.invokeMethod('openUsageAccessSettings');
  }

  /// Minutes of foreground usage for [packageName] within [start, end), or
  /// null if usage access hasn't been granted.
  static Future<int?> getUsageMinutesInRange(String packageName, DateTime start, DateTime end) {
    return _channel.invokeMethod<int>('getUsageMinutesInRange', {
      'package': packageName,
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
    });
  }
}
