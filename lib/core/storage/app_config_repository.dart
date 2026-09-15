import 'package:hive_flutter/hive_flutter.dart';

enum ChallengeType {
  math,
  puzzle,
  action,
  delay;

  String get storageValue => name;

  static ChallengeType fromStorage(String? value) {
    return ChallengeType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ChallengeType.math,
    );
  }

  String get label {
    switch (this) {
      case ChallengeType.math:
        return 'Calcul mental';
      case ChallengeType.puzzle:
        return 'Casse-tête';
      case ChallengeType.action:
        return 'Action réelle';
      case ChallengeType.delay:
        return 'Délai de réflexion';
    }
  }
}

class TargetAppConfig {
  final String packageName;
  final String appName;
  final int graceMinutes;
  final ChallengeType challengeType;

  const TargetAppConfig({
    required this.packageName,
    required this.appName,
    this.graceMinutes = 5,
    this.challengeType = ChallengeType.math,
  });

  TargetAppConfig copyWith({int? graceMinutes, ChallengeType? challengeType}) {
    return TargetAppConfig(
      packageName: packageName,
      appName: appName,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      challengeType: challengeType ?? this.challengeType,
    );
  }

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'graceMinutes': graceMinutes,
        'challengeType': challengeType.storageValue,
      };

  factory TargetAppConfig.fromMap(String packageName, Map map) {
    return TargetAppConfig(
      packageName: packageName,
      appName: map['appName'] as String? ?? packageName,
      graceMinutes: map['graceMinutes'] as int? ?? 5,
      challengeType: ChallengeType.fromStorage(map['challengeType'] as String?),
    );
  }
}

/// Local (Hive-backed) store of which apps are targeted and their config.
/// This is the source of truth on the Dart side; changes must be pushed to
/// the native side via [InterceptionChannel] so the accessibility service
/// (which runs independently of any Flutter engine) can see them.
class AppConfigRepository {
  static const boxName = 'target_apps';

  static Future<void> init() => Hive.openBox(boxName);

  Box get _box => Hive.box(boxName);

  List<TargetAppConfig> getAll() {
    return _box.keys
        .map((key) => TargetAppConfig.fromMap(
              key as String,
              Map<String, dynamic>.from(_box.get(key) as Map),
            ))
        .toList()
      ..sort((a, b) => a.appName.compareTo(b.appName));
  }

  bool isTargeted(String packageName) => _box.containsKey(packageName);

  Future<void> upsert(TargetAppConfig config) => _box.put(config.packageName, config.toMap());

  Future<void> remove(String packageName) => _box.delete(packageName);
}
