import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/platform/interception_channel.dart';
import '../../core/storage/app_config_repository.dart';
import '../../core/storage/stats_repository.dart';
import '../../l10n/app_localizations.dart';
import '../challenge/challenge_type_l10n.dart';

class AppConfigScreen extends StatefulWidget {
  final TargetAppConfig config;

  const AppConfigScreen({super.key, required this.config});

  @override
  State<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends State<AppConfigScreen> {
  final _repository = AppConfigRepository();
  late int _graceMinutes = widget.config.graceMinutes;
  final Set<ChallengeType> _selectedTypes = {};

  @override
  void initState() {
    super.initState();
    _selectedTypes.addAll(widget.config.challengeTypes);
  }

  Future<void> _onChallengeTypeToggled(ChallengeType type, bool? checked) async {
    if (checked == true) {
      if (type.requiresCameraPermission) {
        final granted = await _ensureCameraPermission();
        if (!granted) return;
      }
      if (mounted) setState(() => _selectedTypes.add(type));
      return;
    }

    if (_selectedTypes.length <= 1) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.minOneChallengeRequired)),
      );
      return;
    }

    setState(() => _selectedTypes.remove(type));

    // A gentle nudge rather than a hard restriction (e.g. a 24h cooldown):
    // the point is to catch someone about to narrow down to the easiest
    // challenge in the heat of the moment, without adding real friction to
    // a legitimate change (not everyone can shake their phone in public,
    // etc). Only unchecking (narrowing the pool) triggers it — adding more
    // eligible challenges doesn't weaken the setup.
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.narrowingReminder),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Requests camera access if not already granted. Returns whether the
  /// type can be selected — false leaves the checkbox unchecked.
  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (!mounted) return false;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.mirrorNeedsCameraPermission)),
    );
    return false;
  }

  Future<void> _save() async {
    final updated = widget.config.copyWith(
      graceMinutes: _graceMinutes,
      challengeTypes: _selectedTypes,
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
    await StatsRepository().clearBeforeInstallBaseline(widget.config.packageName);
    final remaining = _repository.getAll().map((c) => c.packageName);
    await InterceptionChannel.setTargetPackages(remaining);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.config.appName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _StatsSummary(packageName: widget.config.packageName),
            const SizedBox(height: 24),
            Text(l10n.possibleChallengesTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.possibleChallengesSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Column(
              children: ChallengeType.values
                  .map(
                    (type) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(type.label(context)),
                      subtitle: Text(type.description(context)),
                      value: _selectedTypes.contains(type),
                      onChanged: (checked) => _onChallengeTypeToggled(type, checked),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(l10n.graceDurationTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(l10n.graceMinutesValue(_graceMinutes)),
            Slider(
              value: _graceMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: l10n.graceMinutesShort(_graceMinutes),
              onChanged: (value) =>
                  setState(() => _graceMinutes = value.round()),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.removeAppButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  final String packageName;

  const _StatsSummary({required this.packageName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = StatsRepository().forPackage(packageName);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(label: l10n.statShownLabel, value: stats.triggered),
        _Stat(label: l10n.statSolvedLabel, value: stats.solved),
        _Stat(
          label: l10n.statCancelled,
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
