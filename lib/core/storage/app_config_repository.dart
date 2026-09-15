import 'package:hive_flutter/hive_flutter.dart';

class TargetAppConfig {
  final String packageName;
  final String appName;
  final int graceMinutes;

  const TargetAppConfig({
    required this.packageName,
    required this.appName,
    this.graceMinutes = 5,
  });

  TargetAppConfig copyWith({int? graceMinutes}) {
    return TargetAppConfig(
      packageName: packageName,
      appName: appName,
      graceMinutes: graceMinutes ?? this.graceMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'graceMinutes': graceMinutes,
      };

  factory TargetAppConfig.fromMap(String packageName, Map map) {
    return TargetAppConfig(
      packageName: packageName,
      appName: map['appName'] as String? ?? packageName,
      graceMinutes: map['graceMinutes'] as int? ?? 5,
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
