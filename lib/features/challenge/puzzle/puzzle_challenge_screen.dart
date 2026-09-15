import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/platform/challenge_channel.dart';
import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import 'schulte_grid_screen.dart';
import 'simon_screen.dart';

class PuzzleChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;

  const PuzzleChallengeScreen({super.key, required this.appConfig});

  @override
  State<PuzzleChallengeScreen> createState() => _PuzzleChallengeScreenState();
}

class _PuzzleChallengeScreenState extends State<PuzzleChallengeScreen> {
  late final bool _useSchulte = Random().nextBool();

  Future<void> _onSolved() async {
    await StatsRepository().incrementSolved();
    await ChallengeChannel.onChallengeSolved();
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.extension, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Tu essaies d\'ouvrir ${widget.appConfig.appName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _useSchulte
                    ? SchulteGridScreen(onSolved: _onSolved)
                    : SimonScreen(onSolved: _onSolved),
                const SizedBox(height: 24),
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
