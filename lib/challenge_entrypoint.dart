import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/platform/challenge_channel.dart';
import 'core/storage/app_config_repository.dart';
import 'core/storage/stats_repository.dart';
import 'features/challenge/action/action_challenge_screen.dart';
import 'features/challenge/delay/delay_challenge_screen.dart';
import 'features/challenge/math/math_challenge_screen.dart';
import 'features/challenge/puzzle/puzzle_challenge_screen.dart';

/// UI for the challenge overlay. The Dart entrypoint that runs this (used by
/// ChallengeActivity's own Flutter engine/isolate) lives in main.dart.
class ChallengeApp extends StatelessWidget {
  const ChallengeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const _ChallengeLoader(),
    );
  }
}

class _ChallengeLoader extends StatefulWidget {
  const _ChallengeLoader();

  @override
  State<_ChallengeLoader> createState() => _ChallengeLoaderState();
}

class _ChallengeLoaderState extends State<_ChallengeLoader> {
  TargetAppConfig? _config;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Hive.initFlutter();
    await AppConfigRepository.init();
    await StatsRepository.init();

    final targetPackage = await ChallengeChannel.getTargetPackage();
    await StatsRepository().incrementTriggered();

    final matches = AppConfigRepository().getAll().where((c) => c.packageName == targetPackage);
    final config = matches.isEmpty ? null : matches.first;

    if (mounted) {
      setState(() {
        _config = config ?? TargetAppConfig(packageName: targetPackage, appName: targetPackage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    switch (config.challengeType) {
      case ChallengeType.math:
        return MathChallengeScreen(appConfig: config);
      case ChallengeType.puzzle:
        return PuzzleChallengeScreen(appConfig: config);
      case ChallengeType.action:
        return ActionChallengeScreen(appConfig: config);
      case ChallengeType.delay:
        return DelayChallengeScreen(appConfig: config);
    }
  }
}
