import 'package:hive_flutter/hive_flutter.dart';

/// Per-app counters: how many times a challenge was shown, solved, or
/// cancelled ("dissuaded" — the friction worked and the user gave up).
class AppStats {
  final int triggered;
  final int solved;
  final int cancelled;

  const AppStats({this.triggered = 0, this.solved = 0, this.cancelled = 0});

  /// Share of triggers that ended in the user giving up, 0–1.
  double? get dissuasionRate => triggered == 0 ? null : cancelled / triggered;

  AppStats copyWith({int? triggered, int? solved, int? cancelled}) {
    return AppStats(
      triggered: triggered ?? this.triggered,
      solved: solved ?? this.solved,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  AppStats operator +(AppStats other) => AppStats(
        triggered: triggered + other.triggered,
        solved: solved + other.solved,
        cancelled: cancelled + other.cancelled,
      );

  Map<String, dynamic> toMap() => {
        'triggered': triggered,
        'solved': solved,
        'cancelled': cancelled,
      };

  factory AppStats.fromMap(Map? map) => AppStats(
        triggered: map?['triggered'] as int? ?? 0,
        solved: map?['solved'] as int? ?? 0,
        cancelled: map?['cancelled'] as int? ?? 0,
      );
}

class StatsRepository {
  static const boxName = 'app_stats';

  static Future<void> init() => Hive.openBox(boxName);

  /// Re-reads the box from disk. Needed because the challenge overlay runs
  /// in its own Flutter engine/isolate (a separate ChallengeActivity), so
  /// writes it makes aren't visible to this engine's already-open Box until
  /// it's reopened.
  static Future<void> reload() async {
    if (Hive.isBoxOpen(boxName)) await Hive.box(boxName).close();
    await Hive.openBox(boxName);
  }

  // Momentarily null while [reload] is closing/reopening the box (another
  // engine/isolate — e.g. the challenge overlay's resume listener — could
  // try to read in that exact window). Callers get an empty/default result
  // instead of a crash; the next rebuild picks up the fresh data.
  Box? get _box => Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;

  AppStats forPackage(String packageName) => AppStats.fromMap(_box?.get(packageName) as Map?);

  /// All per-app stats, keyed by package name.
  Map<String, AppStats> getAll() {
    final box = _box;
    if (box == null) return {};
    return {for (final key in box.keys) key as String: AppStats.fromMap(box.get(key) as Map?)};
  }

  Future<void> incrementTriggered(String packageName) =>
      _update(packageName, (s) => s.copyWith(triggered: s.triggered + 1));

  Future<void> incrementSolved(String packageName) =>
      _update(packageName, (s) => s.copyWith(solved: s.solved + 1));

  Future<void> incrementCancelled(String packageName) =>
      _update(packageName, (s) => s.copyWith(cancelled: s.cancelled + 1));

  Future<void> _update(String packageName, AppStats Function(AppStats current) update) async {
    final updated = update(forPackage(packageName));
    await _box?.put(packageName, updated.toMap());
  }
}
