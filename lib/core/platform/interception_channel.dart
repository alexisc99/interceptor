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
}
