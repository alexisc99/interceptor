import 'package:flutter/material.dart';

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

  Future<void> _save() async {
    final updated = widget.config.copyWith(graceMinutes: _graceMinutes);
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Défi', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Calcul mental (seul type disponible pour le moment)'),
            const SizedBox(height: 24),
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
      ),
    );
  }
}
