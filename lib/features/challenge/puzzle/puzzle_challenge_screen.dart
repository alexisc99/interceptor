import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import '../challenge_scaffold.dart';
import 'schulte_grid_screen.dart';
import 'simon_screen.dart';

class PuzzleChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;
  final ChallengeType resolvedType;
  final int? usageMinutesToday;

  const PuzzleChallengeScreen({
    super.key,
    required this.appConfig,
    required this.resolvedType,
    required this.usageMinutesToday,
  });

  @override
  State<PuzzleChallengeScreen> createState() => _PuzzleChallengeScreenState();
}

class _PuzzleChallengeScreenState extends State<PuzzleChallengeScreen> {
  late final bool _useSchulte = Random().nextBool();
  bool _solved = false;

  Future<void> _onSolved() async {
    await StatsRepository().recordSolved(widget.appConfig.packageName, widget.resolvedType);
    setState(() => _solved = true);
  }

  @override
  Widget build(BuildContext context) {
    return ChallengeScaffold(
      icon: Icons.extension,
      packageName: widget.appConfig.packageName,
      appName: widget.appConfig.appName,
      resolvedType: widget.resolvedType,
      usageMinutesToday: widget.usageMinutesToday,
      solved: _solved,
      child: _useSchulte ? SchulteGridScreen(onSolved: _onSolved) : SimonScreen(onSolved: _onSolved),
    );
  }
}
