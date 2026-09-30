import 'package:flutter/material.dart';

import '../../core/platform/interception_channel.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatelessWidget {
  final bool hasUsageAccess;
  final Future<void> Function() onRefresh;

  const OnboardingScreen({
    super.key,
    required this.hasUsageAccess,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.shield_outlined, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      l10n.onboardingTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.onboardingIntro, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    _PermissionCard(
                      icon: Icons.accessibility_new,
                      title: l10n.a11yCardTitle,
                      description: l10n.a11yCardDescription,
                      required: true,
                      granted: false,
                      buttonLabel: l10n.activateLabel,
                      onPressed: () =>
                          InterceptionChannel.openAccessibilitySettings(),
                      steps: [
                        l10n.a11yStep1,
                        l10n.a11yStep2,
                        l10n.a11yStep3,
                        l10n.a11yStep4,
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PermissionCard(
                      icon: Icons.bar_chart,
                      title: l10n.usageAccessCardTitle,
                      description: l10n.usageAccessCardDescription,
                      required: false,
                      granted: hasUsageAccess,
                      buttonLabel: hasUsageAccess ? l10n.activatedLabel : l10n.activateLabel,
                      onPressed: hasUsageAccess
                          ? null
                          : () => InterceptionChannel.openUsageAccessSettings(),
                      steps: hasUsageAccess
                          ? null
                          : [l10n.usageAccessStep1, l10n.usageAccessStep2],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: onRefresh,
                child: Text(l10n.onboardingContinueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool required;
  final bool granted;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final List<String>? steps;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.required,
    required this.granted,
    required this.buttonLabel,
    required this.onPressed,
    this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              granted ? Icons.check_circle : icon,
              color: granted ? Colors.green : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (required) ...[
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.requiredLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (steps != null) ...[
                    const SizedBox(height: 10),
                    ...steps!.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onPressed,
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
