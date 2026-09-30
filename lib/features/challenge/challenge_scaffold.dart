import 'package:flutter/material.dart';

import '../../core/platform/challenge_channel.dart';
import '../../core/storage/app_config_repository.dart';
import '../../core/storage/stats_repository.dart';
import '../../l10n/app_localizations.dart';

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
  final ChallengeType resolvedType;
  final int? usageMinutesToday;
  final Widget child;
  final bool solved;
  final VoidCallback? onCancel;

  const ChallengeScaffold({
    super.key,
    required this.icon,
    required this.packageName,
    required this.appName,
    required this.resolvedType,
    required this.usageMinutesToday,
    required this.child,
    this.solved = false,
    this.onCancel,
  });

  Future<void> _cancel() async {
    // Called synchronously, before the async work below, so a challenge
    // mid-way through something that shouldn't keep running once the user
    // has bailed (e.g. the mirror challenge's camera capture) can stop
    // immediately instead of racing the teardown below.
    onCancel?.call();
    // The user gave up trying to open the app: the friction worked.
    await StatsRepository().recordCancelled(packageName, resolvedType);
    await ChallengeChannel.onChallengeCancelled();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          // Some challenges (the math keypad pushing content up, the mirror
          // camera preview) can be taller than the available height once the
          // keyboard is up — a plain Column there overflowed and showed
          // Flutter's yellow/black warning bar right above the buttons.
          // Scrolling instead of hard-overflowing fixes that while still
          // centering short content via the minHeight constraint below.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
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
                        solved ? l10n.challengeSolvedTitle : l10n.tryingToOpen(appName),
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (usageMinutesToday != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.usageTodayLine(_formatDuration(usageMinutesToday!)),
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
                          child: Text(l10n.openAppButton(appName)),
                        )
                      else
                        child,
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _cancel,
                        child: Text(l10n.cancelChallengeButton),
                      ),
                    ],
                  ),
                ),
              );
            },
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
