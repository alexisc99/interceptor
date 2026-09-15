import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'challenge_entrypoint.dart';
import 'core/storage/app_config_repository.dart';
import 'core/storage/stats_repository.dart';
import 'features/onboarding/onboarding_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AppConfigRepository.init();
  await StatsRepository.init();
  runApp(const FocusGateApp());
}

// Alternate Dart entrypoint used by ChallengeActivity (its own Flutter
// engine/isolate). Must live in this file, alongside main(), for the
// Android embedding to resolve it by name at engine-creation time.
@pragma('vm:entry-point')
void challengeMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChallengeApp());
}

class FocusGateApp extends StatelessWidget {
  const FocusGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interceptor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const OnboardingGate(),
    );
  }
}
