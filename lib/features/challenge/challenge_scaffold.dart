import 'package:flutter/material.dart';

import '../../core/platform/challenge_channel.dart';

/// Shared layout for every challenge screen: icon, "trying to open X"
/// header, optional today's-usage line, the challenge-specific content,
/// and the cancel button.
class ChallengeScaffold extends StatelessWidget {
  final IconData icon;
  final String appName;
  final int? usageMinutesToday;
  final Widget child;

  const ChallengeScaffold({
    super.key,
    required this.icon,
    required this.appName,
    required this.usageMinutesToday,
    required this.child,
  });

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
                Icon(icon, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Tu essaies d\'ouvrir $appName',
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
                child,
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

  static String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins min';
    return '${hours}h${mins.toString().padLeft(2, '0')}';
  }
}
