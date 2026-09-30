import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../core/platform/interception_channel.dart';
import '../../core/storage/app_config_repository.dart';
import '../../core/storage/premium_repository.dart';
import '../../core/storage/stats_repository.dart';
import '../../l10n/app_localizations.dart';
import '../app_config/app_config_screen.dart';
import '../app_picker/app_picker_screen.dart';
import '../challenge/challenge_type_l10n.dart';
import '../stats/premium_stats_screen.dart';
import '../stats/premium_stats_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _repository = AppConfigRepository();
  final _stats = StatsRepository();
  final _premium = PremiumRepository();
  bool _hasUsageAccess = true;
  bool _showRecapBanner = false;
  final Map<String, Uint8List?> _icons = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshUsageAccess();
    _loadIcons();
    _checkWeeklyRecap();
    _recordUsageSnapshots();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUsageAccess();
      _recordUsageSnapshots();
    }
  }

  Future<void> _refreshUsageAccess() async {
    // OnboardingGate also reloads stats on resume, but it renders this
    // screen as `const HomeScreen()` — an unchanged const widget, so Flutter
    // skips rebuilding it once that reload finishes, and nothing here would
    // otherwise redraw with the fresh data. This setState is what actually
    // makes the stats visibly refresh on resume, so it has to wait for the
    // reload itself (harmless to call again — concurrent reloads are
    // serialized) rather than only checking usage access.
    await StatsRepository.reload();
    final granted = await InterceptionChannel.hasUsageAccess();
    if (mounted) setState(() => _hasUsageAccess = granted);
  }

  /// Captures "today so far" usage for every targeted app into our own
  /// history, opportunistically (whenever this screen is opened/resumed).
  /// Android's own usage history degrades to coarse monthly buckets after
  /// a few weeks, which made "vs last month/year" unreliable — recording
  /// today's number while it's still precise fixes that going forward.
  Future<void> _recordUsageSnapshots() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    await Future.wait(_repository.getAll().map((app) async {
      final minutes = await InterceptionChannel.getUsageMinutesInRange(app.packageName, startOfDay, now);
      if (minutes != null) await _stats.recordUsageSnapshot(app.packageName, minutes);
    }));
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

  String get _currentWeekKey {
    final monday = periodRange(StatsPeriod.week, DateTime.now()).start;
    final y = monday.year.toString().padLeft(4, '0');
    final m = monday.month.toString().padLeft(2, '0');
    final d = monday.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _checkWeeklyRecap() {
    if (_premium.weeklyRecapOptedOut) return;
    if (_premium.lastRecapWeekShown == _currentWeekKey) return;
    setState(() => _showRecapBanner = true);
  }

  Future<void> _dismissRecapBanner() async {
    await _premium.setLastRecapWeekShown(_currentWeekKey);
    if (mounted) setState(() => _showRecapBanner = false);
  }

  Future<void> _optOutRecap() async {
    await _premium.setWeeklyRecapOptedOut(true);
    await _premium.setLastRecapWeekShown(_currentWeekKey);
    if (mounted) setState(() => _showRecapBanner = false);
  }

  Future<void> _openStats() async {
    await _dismissRecapBanner();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumStatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final targets = _repository.getAll();
    final statsByPackage = _stats.getAll();
    final total = statsByPackage.values.fold(const AppStats(), (sum, s) => sum + s);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            tooltip: l10n.statsEntryLabel,
            onPressed: _openStats,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.addAppButton),
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
          _ChallengeTypeBreakdown(typeStats: _stats.typeStatsAll()),
          const Divider(height: 1),
          if (_showRecapBanner)
            _WeeklyRecapBanner(
              onView: _openStats,
              onDismiss: _dismissRecapBanner,
              onOptOut: _optOutRecap,
            ),
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
                        subtitle: Text(
                          l10n.homeAppSubtitle(
                            config.challengeTypes.length,
                            config.challengeTypes.map((t) => t.label(context)).join(', '),
                            config.graceMinutes,
                          ),
                        ),
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

class _WeeklyRecapBanner extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onDismiss;
  final VoidCallback onOptOut;

  const _WeeklyRecapBanner({required this.onView, required this.onDismiss, required this.onOptOut});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      leading: const Icon(Icons.workspace_premium),
      content: Text(l10n.weeklyRecapBannerText),
      actions: [
        TextButton(onPressed: onOptOut, child: Text(l10n.weeklyRecapOptOut)),
        TextButton(onPressed: onDismiss, child: Text(l10n.dismissLabel)),
        TextButton(onPressed: onView, child: Text(l10n.viewLabel)),
      ],
    );
  }
}

class _UsageAccessBanner extends StatelessWidget {
  final VoidCallback onGranted;

  const _UsageAccessBanner({required this.onGranted});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      leading: const Icon(Icons.bar_chart),
      content: Text(l10n.usageAccessBanner),
      actions: [
        TextButton(
          onPressed: () async {
            await InterceptionChannel.openUsageAccessSettings();
            onGranted();
          },
          child: Text(l10n.activateLabel),
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(label: l10n.statTriggered, value: total.triggered),
          _StatChip(label: l10n.statSolved, value: total.solved),
          _StatChip(label: l10n.statCancelled, value: total.cancelled, color: Colors.green),
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

/// Which challenge type dissuades the most, across every trigger where that
/// type was actually drawn (an app can have several types selected, so this
/// is tracked per-trigger rather than derived from app config).
class _ChallengeTypeBreakdown extends StatelessWidget {
  final Map<ChallengeType, AppStats> typeStats;

  const _ChallengeTypeBreakdown({required this.typeStats});

  @override
  Widget build(BuildContext context) {
    final entries = typeStats.entries.where((e) => e.value.triggered > 0).toList()
      ..sort((a, b) => (b.value.dissuasionRate ?? 0).compareTo(a.value.dissuasionRate ?? 0));

    if (entries.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.typeBreakdownTitle, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          ...entries.map((e) {
            final rate = ((e.value.dissuasionRate ?? 0) * 100).round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(l10n.typeBreakdownLine(e.key.label(context), rate, e.value.triggered)),
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
          AppLocalizations.of(context)!.emptyStateMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
