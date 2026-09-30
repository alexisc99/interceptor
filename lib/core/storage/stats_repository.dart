import 'package:hive_flutter/hive_flutter.dart';

import 'app_config_repository.dart';

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

/// Result of summing our own recorded daily usage snapshots over a range.
/// [complete] is false when at least one day in the range has no snapshot —
/// [minutes] is then a floor, not the real total, and shouldn't be shown.
class UsageHistoryResult {
  final int minutes;
  final bool complete;

  const UsageHistoryResult({required this.minutes, required this.complete});
}

class StatsRepository {
  static const boxName = 'app_stats';
  static const typeBoxName = 'challenge_type_stats';
  static const dailyBoxName = 'daily_stats';
  static const baselineBoxName = 'before_install_baseline';

  static Future<void> init() => Future.wait([
        Hive.openBox(boxName),
        Hive.openBox(typeBoxName),
        Hive.openBox(dailyBoxName),
        Hive.openBox(baselineBoxName),
      ]);

  /// Wipes every stat (all-time, daily, per-type, and the "before install"
  /// baselines) so the advanced stats screen starts from zero. Leaves the
  /// target apps and their challenge-type selections untouched — this is
  /// just the numbers, not the setup.
  Future<void> resetAll() => _serialized(() async {
        await Future.wait([
          _box?.clear() ?? Future.value(),
          _typeBox?.clear() ?? Future.value(),
          _dailyBox?.clear() ?? Future.value(),
          _baselineBox?.clear() ?? Future.value(),
        ]);
      });

  // Every write and every reload runs through this single chain, one at a
  // time, in the order called. The challenge overlay (ChallengeActivity)
  // and the main screen (MainActivity) are separate Flutter engines/
  // isolates, each with their own in-memory Box objects for the same files
  // on disk — reload() below is how one engine picks up writes made by the
  // other. Reads (getAll, typeStatsAll, etc.) are synchronous and already
  // handle a box being momentarily closed by returning an empty/default
  // result, so they don't need to wait here. Writes do: re-fetching the box
  // reference right before each put() (see _putDaily) only protects against
  // a *stale* reference — it doesn't stop reload() from closing a box while
  // a put() on it is already mid-flight, which is what actually threw "Box
  // has already been closed". Serializing every write and every reload
  // through one queue removes that overlap entirely, regardless of which
  // two operations happen to land at the same time.
  static Future<void> _gate = Future.value();

  static Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _gate.then((_) => action());
    _gate = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Re-reads all boxes from disk. Needed because the challenge overlay
  /// runs in its own Flutter engine/isolate (a separate ChallengeActivity),
  /// so writes it makes aren't visible to this engine's already-open Boxes
  /// until they're reopened.
  static Future<void> reload() => _serialized(_doReload);

  static Future<void> _doReload() async {
    for (final name in [boxName, typeBoxName, dailyBoxName, baselineBoxName]) {
      if (Hive.isBoxOpen(name)) await Hive.box(name).close();
      await Hive.openBox(name);
    }
  }

  // Momentarily null while [reload] is closing/reopening the box (another
  // engine/isolate — e.g. the challenge overlay's resume listener — could
  // try to read in that exact window). Callers get an empty/default result
  // instead of a crash; the next rebuild picks up the fresh data.
  Box? get _box => Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;
  Box? get _typeBox => Hive.isBoxOpen(typeBoxName) ? Hive.box(typeBoxName) : null;
  Box? get _dailyBox => Hive.isBoxOpen(dailyBoxName) ? Hive.box(dailyBoxName) : null;
  Box? get _baselineBox => Hive.isBoxOpen(baselineBoxName) ? Hive.box(baselineBoxName) : null;

  /// The "week before this app was added" usage baseline, in minutes,
  /// captured once (see [setBeforeInstallBaselineMinutes]) while it was
  /// still fresh enough for Android's usage history to answer reliably.
  /// Null if it was never captured in time — that window is now in the
  /// past and can never be captured retroactively.
  int? beforeInstallBaselineMinutes(String packageName) => _baselineBox?.get(packageName) as int?;

  Future<void> setBeforeInstallBaselineMinutes(String packageName, int minutes) {
    return _serialized(() async {
      await _baselineBox?.put(packageName, minutes);
    });
  }

  /// Clears a captured baseline and remembers *when* [packageName] was
  /// removed. Called when an app is removed from Interceptor, so that
  /// re-adding it later captures a fresh baseline for *that* addition
  /// instead of silently reusing a stale one — and, via
  /// [wasRecentlyRemoved], so a baseline isn't captured at all if the
  /// re-add happens too soon after removal (see [canCaptureBaseline]).
  Future<void> clearBeforeInstallBaseline(String packageName) {
    return _serialized(() async {
      await _baselineBox?.delete(packageName);
      await _baselineBox?.put('removed_at|$packageName', DateTime.now().millisecondsSinceEpoch);
    });
  }

  /// Whether a fresh "before install" baseline can be captured for
  /// [packageName] being added at [addedAt]. False if it was removed less
  /// than 7 days before [addedAt] — the would-be baseline window would
  /// overlap days it was still actively challenged, understating (not
  /// reflecting free, unregulated use) rather than a genuine "before"
  /// picture. Better to leave the metric unavailable than misleading.
  bool canCaptureBaseline(String packageName, DateTime addedAt) {
    final removedAtMs = _baselineBox?.get('removed_at|$packageName') as int?;
    if (removedAtMs == null) return true;
    final removedAt = DateTime.fromMillisecondsSinceEpoch(removedAtMs);
    return addedAt.difference(removedAt) >= const Duration(days: 7);
  }

  AppStats forPackage(String packageName) => AppStats.fromMap(_box?.get(packageName) as Map?);

  /// All per-app stats, keyed by package name.
  Map<String, AppStats> getAll() {
    final box = _box;
    if (box == null) return {};
    return {for (final key in box.keys) key as String: AppStats.fromMap(box.get(key) as Map?)};
  }

  AppStats forType(ChallengeType type) => AppStats.fromMap(_typeBox?.get(type.name) as Map?);

  /// All per-challenge-type stats. Reflects the type actually drawn for each
  /// trigger (an app can have several types selected), not app config.
  Map<ChallengeType, AppStats> typeStatsAll() {
    final box = _typeBox;
    if (box == null) return {};
    return {
      for (final type in ChallengeType.values)
        if (box.containsKey(type.name)) type: AppStats.fromMap(box.get(type.name) as Map?),
    };
  }

  Future<void> recordTriggered(String packageName, ChallengeType type) => _serialized(() => Future.wait([
        _update(packageName, (s) => s.copyWith(triggered: s.triggered + 1)),
        _updateType(type, (s) => s.copyWith(triggered: s.triggered + 1)),
        _updateDaily(packageName, type, (s) => s.copyWith(triggered: s.triggered + 1)),
      ]));

  Future<void> recordSolved(String packageName, ChallengeType type) => _serialized(() => Future.wait([
        _update(packageName, (s) => s.copyWith(solved: s.solved + 1)),
        _updateType(type, (s) => s.copyWith(solved: s.solved + 1)),
        _updateDaily(packageName, type, (s) => s.copyWith(solved: s.solved + 1)),
      ]));

  Future<void> recordCancelled(String packageName, ChallengeType type) => _serialized(() => Future.wait([
        _update(packageName, (s) => s.copyWith(cancelled: s.cancelled + 1)),
        _updateType(type, (s) => s.copyWith(cancelled: s.cancelled + 1)),
        _updateDaily(packageName, type, (s) => s.copyWith(cancelled: s.cancelled + 1)),
      ]));

  /// Records how many minutes [packageName] has been used *today so far*.
  /// Meant to be called opportunistically (app resume, challenge trigger) —
  /// each call overwrites today's entry with the latest live total, so by
  /// the time the day is over it holds an accurate, permanent record. This
  /// is what lets "vs last month/year" stay reliable long after Android's
  /// own UsageStatsManager history for that day has degraded to coarse
  /// monthly buckets (see [usageHistoryInRange]).
  Future<void> recordUsageSnapshot(String packageName, int minutesToday) {
    return _serialized(() async {
      final box = _dailyBox;
      if (box == null) return;
      await box.put('${_dateKey(DateTime.now())}|usage|$packageName', minutesToday);
    });
  }

  /// Sums our own recorded daily usage snapshots for [packageName] over
  /// whole days touching [start, end]. [complete] is false if any day in
  /// that range has no recorded snapshot — callers should treat the sum as
  /// unreliable (an undercount) in that case rather than display it as-is.
  UsageHistoryResult usageHistoryInRange(String packageName, DateTime start, DateTime end) {
    final box = _dailyBox;
    final startDay = _dateOnly(start);
    final endDay = _dateOnly(end);
    final totalDays = endDay.difference(startDay).inDays + 1;
    if (box == null) return UsageHistoryResult(minutes: 0, complete: totalDays == 0);

    var minutes = 0;
    var daysFound = 0;
    for (var day = startDay; !day.isAfter(endDay); day = day.add(const Duration(days: 1))) {
      final value = box.get('${_dateKey(day)}|usage|$packageName') as int?;
      if (value != null) {
        minutes += value;
        daysFound++;
      }
    }
    return UsageHistoryResult(minutes: minutes, complete: daysFound >= totalDays);
  }

  /// Per-(app, challenge-type) dissuasion stats for [packageName] over
  /// whole days touching [start, end] — e.g. "for Instagram, mental math
  /// deterred at 40%, the mirror challenge at 60%".
  Map<ChallengeType, AppStats> typeStatsForAppInRange(String packageName, DateTime start, DateTime end) {
    final box = _dailyBox;
    if (box == null) return {};
    final startDay = _dateOnly(start);
    final endDay = _dateOnly(end);
    final result = <ChallengeType, AppStats>{};
    for (final rawKey in box.keys) {
      if (rawKey is! String) continue;
      final parts = rawKey.split('|');
      if (parts.length != 4 || parts[1] != 'apptype' || parts[2] != packageName) continue;
      final date = DateTime.tryParse(parts[0]);
      if (date == null || date.isBefore(startDay) || date.isAfter(endDay)) continue;
      final type = ChallengeType.fromStorage(parts[3]);
      result[type] = (result[type] ?? const AppStats()) + AppStats.fromMap(box.get(rawKey) as Map?);
    }
    return result;
  }

  Future<void> _update(String packageName, AppStats Function(AppStats current) update) async {
    final updated = update(forPackage(packageName));
    await _box?.put(packageName, updated.toMap());
  }

  Future<void> _updateType(ChallengeType type, AppStats Function(AppStats current) update) async {
    final updated = update(forType(type));
    await _typeBox?.put(type.name, updated.toMap());
  }

  Future<void> _updateDaily(
    String packageName,
    ChallengeType type,
    AppStats Function(AppStats current) update,
  ) async {
    final today = _dateKey(DateTime.now());
    await _putDaily('$today|pkg|$packageName', update);
    await _putDaily('$today|type|${type.name}', update);
    await _putDaily('$today|apptype|$packageName|${type.name}', update);
  }

  // Re-fetches the box for each individual write (rather than reusing one
  // reference across the three awaits above) so a concurrent [reload] that
  // closes/reopens the box between writes can't leave us holding a stale,
  // already-closed Box and crash with "Box has already been closed."
  Future<void> _putDaily(String key, AppStats Function(AppStats current) update) async {
    final box = _dailyBox;
    if (box == null) return;
    await box.put(key, update(AppStats.fromMap(box.get(key) as Map?)).toMap());
  }

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Per-app dissuasion stats summed over whole days touching [start, end]
  /// (inclusive on both ends). Reflects the day the challenge triggered,
  /// independent of the all-time totals in [getAll].
  Map<String, AppStats> packageStatsInRange(DateTime start, DateTime end) {
    return _dailyStatsInRange(start, end, 'pkg', (key) => key);
  }

  /// Per-challenge-type dissuasion stats summed over whole days touching
  /// [start, end] (inclusive on both ends).
  Map<ChallengeType, AppStats> typeStatsInRange(DateTime start, DateTime end) {
    return _dailyStatsInRange(start, end, 'type', ChallengeType.fromStorage);
  }

  Map<K, AppStats> _dailyStatsInRange<K>(
    DateTime start,
    DateTime end,
    String kind,
    K Function(String) parseKey,
  ) {
    final box = _dailyBox;
    if (box == null) return {};
    final startDay = _dateOnly(start);
    final endDay = _dateOnly(end);
    final result = <K, AppStats>{};
    for (final rawKey in box.keys) {
      if (rawKey is! String) continue;
      final parts = rawKey.split('|');
      if (parts.length != 3 || parts[1] != kind) continue;
      final date = DateTime.tryParse(parts[0]);
      if (date == null || date.isBefore(startDay) || date.isAfter(endDay)) continue;
      final k = parseKey(parts[2]);
      result[k] = (result[k] ?? const AppStats()) + AppStats.fromMap(box.get(rawKey) as Map?);
    }
    return result;
  }
}
