import 'package:flutter/material.dart';

import '../../core/platform/interception_channel.dart';

class OnboardingScreen extends StatelessWidget {
  final bool hasUsageAccess;
  final Future<void> Function() onRefresh;

  const OnboardingScreen({super.key, required this.hasUsageAccess, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.shield_outlined, size: 64),
              const SizedBox(height: 20),
              Text(
                'Reprends la main sur tes apps',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Focus Gate insère un petit défi avant l'ouverture des apps que tu choisis, "
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
                onPressed: () => InterceptionChannel.openAccessibilitySettings(),
              ),
              const SizedBox(height: 12),
              _PermissionCard(
                icon: Icons.bar_chart,
                title: "Accès à l'utilisation",
                description: 'Optionnel : affiche ton temps passé sur chaque app pendant les défis.',
                required: false,
                granted: hasUsageAccess,
                buttonLabel: hasUsageAccess ? 'Activé' : 'Activer',
                onPressed: hasUsageAccess ? null : () => InterceptionChannel.openUsageAccessSettings(),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onRefresh,
                child: const Text("J'ai activé, continuer"),
              ),
            ],
          ),
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

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.required,
    required this.granted,
    required this.buttonLabel,
    required this.onPressed,
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
            Icon(granted ? Icons.check_circle : icon, color: granted ? Colors.green : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      if (required) ...[
                        const SizedBox(width: 6),
                        Text(
                          'requis',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
