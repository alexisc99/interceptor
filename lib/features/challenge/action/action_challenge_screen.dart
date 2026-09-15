import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/platform/challenge_channel.dart';
import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import '../challenge_scaffold.dart';
import 'shake_screen.dart';
import 'steps_screen.dart';

class ActionChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;
  final int? usageMinutesToday;

  const ActionChallengeScreen({super.key, required this.appConfig, required this.usageMinutesToday});

  @override
  State<ActionChallengeScreen> createState() => _ActionChallengeScreenState();
}

class _ActionChallengeScreenState extends State<ActionChallengeScreen> {
  late final bool _useSteps = Random().nextBool();

  Future<void> _onSolved() async {
    await StatsRepository().incrementSolved();
    await ChallengeChannel.onChallengeSolved();
  }

  @override
  Widget build(BuildContext context) {
    return ChallengeScaffold(
      icon: Icons.directions_walk,
      appName: widget.appConfig.appName,
      usageMinutesToday: widget.usageMinutesToday,
      child: _useSteps ? StepsScreen(onSolved: _onSolved) : ShakeScreen(onSolved: _onSolved),
    );
  }
}
