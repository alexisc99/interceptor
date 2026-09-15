import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/platform/interception_channel.dart';
import '../../core/storage/app_config_repository.dart';

class AppConfigScreen extends StatefulWidget {
  final TargetAppConfig config;

  const AppConfigScreen({super.key, required this.config});

  @override
  State<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends State<AppConfigScreen> {
  final _repository = AppConfigRepository();
  late int _graceMinutes = widget.config.graceMinutes;
  late ChallengeType _challengeType = widget.config.challengeType;

  Future<void> _save() async {
    if (_challengeType == ChallengeType.action) {
      // Best-effort: only needed for the "steps" variant of this challenge.
      // If denied, the challenge falls back to the shake variant.
      await Permission.activityRecognition.request();
    }

    final updated = widget.config.copyWith(
      graceMinutes: _graceMinutes,
      challengeType: _challengeType,
    );
    await _repository.upsert(updated);
    await InterceptionChannel.setGraceMinutes(updated.packageName, _graceMinutes);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await _repository.remove(widget.config.packageName);
    final remaining = _repository.getAll().map((c) => c.packageName);
    await InterceptionChannel.setTargetPackages(remaining);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.config.appName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Défi', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioGroup<ChallengeType>(
            groupValue: _challengeType,
            onChanged: (value) => setState(() => _challengeType = value!),
            child: Column(
              children: ChallengeType.values
                  .map(
                    (type) => RadioListTile<ChallengeType>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(type.label),
                      subtitle: Text(_descriptionFor(type)),
                      value: type,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Durée de grâce après un défi résolu', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('$_graceMinutes minutes'),
          Slider(
            value: _graceMinutes.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '$_graceMinutes min',
            onChanged: (value) => setState(() => _graceMinutes = value.round()),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Retirer cette app'),
          ),
        ],
      ),
    );
  }

  String _descriptionFor(ChallengeType type) {
    switch (type) {
      case ChallengeType.math:
        return 'Résoudre une opération simple';
      case ChallengeType.puzzle:
        return 'Grille de Schulte ou Simon, au hasard';
      case ChallengeType.action:
        return 'Compter des pas ou secouer le téléphone, au hasard';
      case ChallengeType.delay:
        return 'Un temps de réflexion avant de continuer';
    }
  }
}
