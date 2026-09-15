import 'package:flutter/services.dart';

/// Bridge used inside the challenge overlay (ChallengeActivity's own Flutter
/// engine) to know which app triggered it and to report the outcome.
class ChallengeChannel {
  ChallengeChannel._();

  static const _channel = MethodChannel('com.focusgate.focus_gate/challenge');

  static Future<String> getTargetPackage() async {
    final result = await _channel.invokeMethod<String>('getTargetPackage');
    return result ?? '';
  }

  /// Minutes of foreground usage for the target app today, or null if the
  /// "Usage access" permission hasn't been granted.
  static Future<int?> getTodayUsageMinutes() {
    return _channel.invokeMethod<int>('getTodayUsageMinutes');
  }

  static Future<void> onChallengeSolved() {
    return _channel.invokeMethod('onChallengeSolved');
  }

  static Future<void> onChallengeCancelled() {
    return _channel.invokeMethod('onChallengeCancelled');
  }
}
