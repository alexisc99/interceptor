import 'package:flutter/material.dart';

import '../../core/platform/interception_channel.dart';

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
                      'Reprends la main sur tes apps',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Interceptor insère un petit défi avant l'ouverture des apps que tu choisis, "
                      "pour casser le réflexe d'ouverture automatique. Deux réglages Android sont "
                      "nécessaires — ils s'activent en un tap, tu reviens automatiquement ici après.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _PermissionCard(
                      icon: Icons.accessibility_new,
                      title: "Service d'accessibilité",
                      description: 'Indispensable : permet de détecter quelle app tu lances.',
                      required: true,
                      granted: false,
                      buttonLabel: 'Activer',
                      onPressed: () =>
                          InterceptionChannel.openAccessibilitySettings(),
                      steps: const [
                        'Cherche "Interceptor" dans la liste (parfois sous "Applications installées" ou "Services téléchargés")',
                        'Ouvre-le et active l\'interrupteur en haut',
                        'Confirme en appuyant sur "Autoriser" dans la fenêtre qui apparaît',
                        'Reviens ici avec la flèche retour — c\'est automatique, pas besoin de rien taper',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PermissionCard(
                      icon: Icons.bar_chart,
                      title: "Accès à l'utilisation",
                      description: 'Optionnel : affiche ton temps passé sur chaque app pendant les défis.',
                      required: false,
                      granted: hasUsageAccess,
                      buttonLabel: hasUsageAccess ? 'Activé' : 'Activer',
                      onPressed: hasUsageAccess
                          ? null
                          : () => InterceptionChannel.openUsageAccessSettings(),
                      steps: hasUsageAccess
                          ? null
                          : const [
                              'Cherche "Interceptor" dans la liste des apps',
                              'Active l\'interrupteur à côté de son nom',
                            ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: onRefresh,
                child: const Text("J'ai activé, continuer"),
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
                          'requis',
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
