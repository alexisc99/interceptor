import 'package:flutter/material.dart';

import '../../core/platform/challenge_channel.dart';
import '../../core/storage/stats_repository.dart';

/// Shared layout for every challenge screen: icon, "trying to open X"
/// header, optional today's-usage line, the challenge-specific content,
/// and the cancel button.
///
/// Solving the challenge doesn't launch the app by itself — [solved] swaps
/// the content for an explicit "Ouvrir" button. That extra deliberate tap is
/// one more moment for the user to reconsider before the app actually opens.
class ChallengeScaffold extends StatelessWidget {
  final IconData icon;
  final String packageName;
  final String appName;
  final int? usageMinutesToday;
  final Widget child;
  final bool solved;

  const ChallengeScaffold({
    super.key,
    required this.icon,
    required this.packageName,
    required this.appName,
    required this.usageMinutesToday,
    required this.child,
    this.solved = false,
  });

  Future<void> _cancel() async {
    // The user gave up trying to open the app: the friction worked.
    await StatsRepository().incrementCancelled(packageName);
    await ChallengeChannel.onChallengeCancelled();
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
                Icon(
                  solved ? Icons.check_circle : icon,
                  size: 56,
                  color: solved ? Colors.green : null,
                ),
                const SizedBox(height: 16),
                Text(
                  solved ? 'Défi réussi !' : 'Tu essaies d\'ouvrir $appName',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (usageMinutesToday != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Utilisation aujourd\'hui : ${_formatDuration(usageMinutesToday!)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                ],
                const SizedBox(height: 24),
                if (solved)
                  FilledButton(
                    onPressed: () => ChallengeChannel.onChallengeSolved(),
                    child: Text('Ouvrir $appName'),
                  )
                else
                  child,
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _cancel,
                  child: const Text('Annuler et rester ici'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins min';
    return '${hours}h${mins.toString().padLeft(2, '0')}';
  }
}
