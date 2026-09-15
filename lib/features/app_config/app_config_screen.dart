import 'package:flutter/material.dart';

import '../../core/platform/interception_channel.dart';
import '../../core/storage/app_config_repository.dart';
import '../../core/storage/stats_repository.dart';

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
    final updated = widget.config.copyWith(
      graceMinutes: _graceMinutes,
      challengeType: _challengeType,
    );
    await _repository.upsert(updated);
    await InterceptionChannel.setGraceMinutes(
      updated.packageName,
      _graceMinutes,
    );
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _StatsSummary(packageName: widget.config.packageName),
            const SizedBox(height: 12),
            _UsageComparisonCard(config: widget.config),
            const SizedBox(height: 24),
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
            const Text(
              'Durée de grâce après un défi résolu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('$_graceMinutes minutes'),
            Slider(
              value: _graceMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '$_graceMinutes min',
              onChanged: (value) =>
                  setState(() => _graceMinutes = value.round()),
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

class _StatsSummary extends StatelessWidget {
  final String packageName;

  const _StatsSummary({required this.packageName});

  @override
  Widget build(BuildContext context) {
    final stats = StatsRepository().forPackage(packageName);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(label: 'Affichés', value: stats.triggered),
        _Stat(label: 'Résolus', value: stats.solved),
        _Stat(
          label: 'Dissuasions',
          value: stats.cancelled,
          color: Colors.green,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;

  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Compares average daily usage the week before this app was targeted to
/// average daily usage since, to give a concrete "time saved" figure.
/// Requires the usage-access permission; silently omitted without it.
class _UsageComparisonCard extends StatefulWidget {
  final TargetAppConfig config;

  const _UsageComparisonCard({required this.config});

  @override
  State<_UsageComparisonCard> createState() => _UsageComparisonCardState();
}

class _UsageComparisonCardState extends State<_UsageComparisonCard> {
  bool _loading = true;
  bool _hasAccess = false;
  int? _beforePerDayMinutes;
  int? _afterPerDayMinutes;
  int _daysSinceAdded = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasAccess = await InterceptionChannel.hasUsageAccess();
    if (!hasAccess) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final addedAt = widget.config.addedAt;
    final now = DateTime.now();
    final daysSinceAdded = now.difference(addedAt).inHours / 24;

    final beforeMinutes = await InterceptionChannel.getUsageMinutesInRange(
      widget.config.packageName,
      addedAt.subtract(const Duration(days: 7)),
      addedAt,
    );
    final afterMinutes = daysSinceAdded >= 1
        ? await InterceptionChannel.getUsageMinutesInRange(
            widget.config.packageName,
            addedAt,
            now,
          )
        : null;

    if (!mounted) return;
    setState(() {
      _hasAccess = true;
      _beforePerDayMinutes = beforeMinutes == null
          ? null
          : (beforeMinutes / 7).round();
      _afterPerDayMinutes = (afterMinutes != null && daysSinceAdded >= 1)
          ? (afterMinutes / daysSinceAdded).round()
          : null;
      _daysSinceAdded = daysSinceAdded.floor();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_hasAccess) return const SizedBox.shrink();

    final before = _beforePerDayMinutes;
    final after = _afterPerDayMinutes;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temps passé par jour',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (before == null)
              const Text(
                "Pas de données pour la semaine avant l'ajout de cette app.",
              )
            else if (after == null)
              Text(
                'Avant Focus Gate : ${_format(before)}/jour\n'
                "Pas encore assez de recul depuis l'ajout (${_daysSinceAdded}j) pour comparer.",
              )
            else ...[
              Text('Avant Focus Gate : ${_format(before)}/jour'),
              Text('Depuis ($_daysSinceAdded j) : ${_format(after)}/jour'),
              const SizedBox(height: 4),
              Text(
                before > after
                    ? 'Temps gagné : ${_format(before - after)}/jour'
                    : 'Pas de gain mesurable pour l\'instant',
                style: TextStyle(
                  color: before > after ? Colors.green : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _format(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins min';
    return '${hours}h${mins.toString().padLeft(2, '0')}';
  }
}
