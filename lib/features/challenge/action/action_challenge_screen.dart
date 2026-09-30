import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import '../challenge_scaffold.dart';
import 'shake_screen.dart';
import 'steps_screen.dart';

class ActionChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;
  final ChallengeType resolvedType;
  final int? usageMinutesToday;

  const ActionChallengeScreen({
    super.key,
    required this.appConfig,
    required this.resolvedType,
    required this.usageMinutesToday,
  });

  @override
  State<ActionChallengeScreen> createState() => _ActionChallengeScreenState();
}

class _ActionChallengeScreenState extends State<ActionChallengeScreen> {
  late final bool _useSteps = Random().nextBool();
  bool _solved = false;

  Future<void> _onSolved() async {
    await StatsRepository().recordSolved(widget.appConfig.packageName, widget.resolvedType);
    setState(() => _solved = true);
  }

  @override
  Widget build(BuildContext context) {
    return ChallengeScaffold(
      icon: Icons.directions_walk,
      packageName: widget.appConfig.packageName,
      appName: widget.appConfig.appName,
      resolvedType: widget.resolvedType,
      usageMinutesToday: widget.usageMinutesToday,
      solved: _solved,
      child: _useSteps ? StepsScreen(onSolved: _onSolved) : ShakeScreen(onSolved: _onSolved),
    );
  }
}
