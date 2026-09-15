import 'package:flutter/material.dart';

import '../../core/platform/interception_channel.dart';

class OnboardingScreen extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const OnboardingScreen({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_outlined, size: 72),
              const SizedBox(height: 24),
              Text(
                'Reprends la main sur tes apps',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Focus Gate insère un petit défi avant l'ouverture des apps que tu choisis, "
                "pour casser le réflexe d'ouverture automatique. Pour fonctionner, l'app a besoin "
                "du service d'accessibilité Android, qui lui permet de détecter quelle app tu lances.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => InterceptionChannel.openAccessibilitySettings(),
                child: const Text("Activer le service d'accessibilité"),
              ),
              const SizedBox(height: 12),
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
