import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshUsageAccess();
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

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final targets = _repository.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Gate')),
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
          _StatsBar(triggered: _stats.triggeredCount, solved: _stats.solvedCount),
          const Divider(height: 1),
          if (!_hasUsageAccess) _UsageAccessBanner(onGranted: _refreshUsageAccess),
          Expanded(
            child: targets.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    itemCount: targets.length,
                    itemBuilder: (context, index) {
                      final config = targets[index];
                      return ListTile(
                        leading: const Icon(Icons.apps),
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
  final int triggered;
  final int solved;

  const _StatsBar({required this.triggered, required this.solved});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(label: 'Défis affichés', value: triggered),
          _StatChip(label: 'Défis résolus', value: solved),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
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
