import 'package:hive_flutter/hive_flutter.dart';

/// Minimal local counters: how many times a challenge was shown vs solved.
class StatsRepository {
  static const boxName = 'stats';

  static Future<void> init() => Hive.openBox(boxName);

  Box get _box => Hive.box(boxName);

  int get triggeredCount => _box.get('triggered_count', defaultValue: 0) as int;
  int get solvedCount => _box.get('solved_count', defaultValue: 0) as int;

  Future<void> incrementTriggered() => _box.put('triggered_count', triggeredCount + 1);
  Future<void> incrementSolved() => _box.put('solved_count', solvedCount + 1);
}
