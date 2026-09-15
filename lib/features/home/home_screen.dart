import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../core/platform/interception_channel.dart';
import '../../core/storage/app_config_repository.dart';
import '../../core/storage/stats_repository.dart';
import '../app_config/app_config_screen.dart';
import '../app_picker/app_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _repository = AppConfigRepository();
  final _stats = StatsRepository();
  bool _hasUsageAccess = true;
  final Map<String, Uint8List?> _icons = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshUsageAccess();
    _loadIcons();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshUsageAccess();
  }

  Future<void> _refreshUsageAccess() async {
    final granted = await InterceptionChannel.hasUsageAccess();
    if (mounted) setState(() => _hasUsageAccess = granted);
  }

  Future<void> _loadIcons() async {
    final missing = _repository.getAll().where((t) => !_icons.containsKey(t.packageName)).toList();
    if (missing.isEmpty) return;

    final results = await Future.wait(missing.map((t) => InstalledApps.getAppInfo(t.packageName)));
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < missing.length; i++) {
        _icons[missing[i].packageName] = results[i]?.icon;
      }
    });
  }

  void _refresh() {
    setState(() {});
    _loadIcons();
  }

  @override
  Widget build(BuildContext context) {
    final targets = _repository.getAll();
    final statsByPackage = _stats.getAll();
    final total = statsByPackage.values.fold(const AppStats(), (sum, s) => sum + s);

    return Scaffold(
      appBar: AppBar(title: const Text('Interceptor')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une app'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AppPickerScreen()),
          );
          _refresh();
        },
      ),
      body: Column(
        children: [
          _StatsBar(total: total),
          if (targets.isNotEmpty) _ChallengeTypeBreakdown(targets: targets, statsByPackage: statsByPackage),
          const Divider(height: 1),
          if (!_hasUsageAccess) _UsageAccessBanner(onGranted: _refreshUsageAccess),
          Expanded(
            child: targets.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    itemCount: targets.length,
                    itemBuilder: (context, index) {
                      final config = targets[index];
                      final icon = _icons[config.packageName];
                      return ListTile(
                        leading: icon != null ? CircleAvatar(backgroundImage: MemoryImage(icon)) : const Icon(Icons.apps),
                        title: Text(config.appName),
                        subtitle: Text('Défi : ${config.challengeType.label} · grâce ${config.graceMinutes} min'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AppConfigScreen(config: config)),
                          );
                          _refresh();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UsageAccessBanner extends StatelessWidget {
  final VoidCallback onGranted;

  const _UsageAccessBanner({required this.onGranted});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      leading: const Icon(Icons.bar_chart),
      content: const Text(
        "Active l'accès à l'utilisation pour afficher ton temps passé sur chaque app pendant les défis.",
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await InterceptionChannel.openUsageAccessSettings();
            onGranted();
          },
          child: const Text('Activer'),
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  final AppStats total;

  const _StatsBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(label: 'Défis affichés', value: total.triggered),
          _StatChip(label: 'Défis résolus', value: total.solved),
          _StatChip(label: 'Dissuasions', value: total.cancelled, color: Colors.green),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;

  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Which challenge type dissuades the most, aggregated across every app
/// currently configured with that type (a config change re-buckets its past
/// counts under the new type — this is a live snapshot, not a historical log).
class _ChallengeTypeBreakdown extends StatelessWidget {
  final List<TargetAppConfig> targets;
  final Map<String, AppStats> statsByPackage;

  const _ChallengeTypeBreakdown({required this.targets, required this.statsByPackage});

  @override
  Widget build(BuildContext context) {
    final byType = <ChallengeType, AppStats>{};
    for (final config in targets) {
      final stats = statsByPackage[config.packageName] ?? const AppStats();
      byType[config.challengeType] = (byType[config.challengeType] ?? const AppStats()) + stats;
    }

    final entries = byType.entries.where((e) => e.value.triggered > 0).toList()
      ..sort((a, b) => (b.value.dissuasionRate ?? 0).compareTo(a.value.dissuasionRate ?? 0));

    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dissuasion par type de défi', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          ...entries.map((e) {
            final rate = ((e.value.dissuasionRate ?? 0) * 100).round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${e.key.label} : $rate% (${e.value.triggered} déclenchements)'),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          "Aucune app surveillée pour l'instant.\nAjoute une app pour lui associer un défi.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
