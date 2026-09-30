import 'package:hive_flutter/hive_flutter.dart';

/// Placeholder for the eventual payment integration: [isPremium] is just a
/// manually-set flag for now (toggled from the premium screen itself while
/// there's no real billing yet), gating the advanced-stats screen. Swap the
/// storage for real entitlement state once billing is wired up.
class PremiumRepository {
  static const boxName = 'premium_status';
  static const _isPremiumKey = 'isPremium';
  static const _weeklyRecapOptOutKey = 'weeklyRecapOptOut';
  static const _lastRecapWeekShownKey = 'lastRecapWeekShown';

  static Future<void> init() => Hive.openBox(boxName);

  Box get _box => Hive.box(boxName);

  bool get isPremium => _box.get(_isPremiumKey, defaultValue: false) as bool;

  Future<void> setPremium(bool value) => _box.put(_isPremiumKey, value);

  /// Whether the user has turned off the weekly "your recap is ready" nudge.
  bool get weeklyRecapOptedOut => _box.get(_weeklyRecapOptOutKey, defaultValue: false) as bool;

  Future<void> setWeeklyRecapOptedOut(bool value) => _box.put(_weeklyRecapOptOutKey, value);

  /// Key (Monday of the week, yyyy-MM-dd) of the last week the recap banner
  /// was shown/dismissed for, so it only shows once per week.
  String? get lastRecapWeekShown => _box.get(_lastRecapWeekShownKey) as String?;

  Future<void> setLastRecapWeekShown(String weekKey) => _box.put(_lastRecapWeekShownKey, weekKey);
}
