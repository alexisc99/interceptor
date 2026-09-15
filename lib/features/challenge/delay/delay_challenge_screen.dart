import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/platform/challenge_channel.dart';
import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';

class DelayChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;

  const DelayChallengeScreen({super.key, required this.appConfig});

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
    await StatsRepository().incrementSolved();
    await ChallengeChannel.onChallengeSolved();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _remaining <= 0;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.self_improvement, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Tu essaies d\'ouvrir ${widget.appConfig.appName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(_question, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: canContinue ? _continue : null,
                  child: Text(canContinue ? 'Continuer' : 'Continuer ($_remaining)'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ChallengeChannel.onChallengeCancelled(),
                  child: const Text('Annuler et rester ici'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
