import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/platform/challenge_channel.dart';
import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import '../challenge_scaffold.dart';

class DelayChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;
  final int? usageMinutesToday;

  const DelayChallengeScreen({super.key, required this.appConfig, required this.usageMinutesToday});

  @override
  State<DelayChallengeScreen> createState() => _DelayChallengeScreenState();
}

class _DelayChallengeScreenState extends State<DelayChallengeScreen> {
  static const _duration = 8;
  static const _questions = [
    'Pourquoi veux-tu ouvrir cette app maintenant ?',
    'Qu\'est-ce que tu espères y trouver ?',
    'Est-ce que ça peut attendre quelques minutes ?',
    'Qu\'étais-tu en train de faire avant ?',
  ];

  late final String _question = _questions[Random().nextInt(_questions.length)];
  int _remaining = _duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining--);
      if (_remaining <= 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _continue() async {
    await StatsRepository().incrementSolved(widget.appConfig.packageName);
    await ChallengeChannel.onChallengeSolved();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _remaining <= 0;
    return ChallengeScaffold(
      icon: Icons.self_improvement,
      packageName: widget.appConfig.packageName,
      appName: widget.appConfig.appName,
      usageMinutesToday: widget.usageMinutesToday,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_question, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: canContinue ? _continue : null,
            child: Text(canContinue ? 'Continuer' : 'Continuer ($_remaining)'),
          ),
        ],
      ),
    );
  }
}
