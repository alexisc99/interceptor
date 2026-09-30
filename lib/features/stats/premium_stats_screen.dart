import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../core/storage/app_config_repository.dart';
import '../../core/storage/premium_repository.dart';
import '../../core/storage/stats_repository.dart';
import '../../l10n/app_localizations.dart';
import '../challenge/challenge_type_l10n.dart';
import 'premium_gate_screen.dart';
import 'premium_stats_service.dart';

class PremiumStatsScreen extends StatefulWidget {
  const PremiumStatsScreen({super.key});

  @override
  State<PremiumStatsScreen> createState() => _PremiumStatsScreenState();
}

class _PremiumStatsScreenState extends State<PremiumStatsScreen> with WidgetsBindingObserver {
  final _premium = PremiumRepository();
  StatsPeriod _period = StatsPeriod.week;
  late Future<PremiumStatsSnapshot> _snapshotFuture = _loadFreshSnapshot(_period);
  final Map<String, Uint8List?> _icons = {};

  // Navigating here from Home is plain in-app navigation, not an app
  // lifecycle event — didChangeAppLifecycleState(resumed) never fires for
  // it, so without this the very first render used whatever was already
  // cached in this isolate's Hive box, which can be stale relative to
  // writes made by ChallengeActivity's separate Flutter engine/isolate.
  Future<PremiumStatsSnapshot> _loadFreshSnapshot(StatsPeriod period) async {
    await StatsRepository.reload();
    return computePremiumStats(period);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadIcons();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    // OnboardingGate also reloads on resume, but it's a separate observer
    // doing its own unawaited async work — relying on it finishing first
    // would be a race. Reload here too so this screen's freshness doesn't
    // depend on notification order between the two.
    await StatsRepository.reload();
    if (!mounted) return;
    setState(() => _snapshotFuture = computePremiumStats(_period));
    _loadIcons();
  }

  Future<void> _openUnlock() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumGateScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadIcons() async {
    final targets = AppConfigRepository().getAll();
    final results = await Future.wait(targets.map((t) => InstalledApps.getAppInfo(t.packageName)));
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < targets.length; i++) {
        _icons[targets[i].packageName] = results[i]?.icon;
      }
    });
  }

  void _onPeriodChanged(StatsPeriod period) {
    setState(() {
      _period = period;
      _snapshotFuture = computePremiumStats(period);
    });
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetStatsConfirmTitle),
        content: Text(l10n.resetStatsConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.resetStatsConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await StatsRepository().resetAll();
    if (mounted) {
      setState(() => _snapshotFuture = computePremiumStats(_period));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = _premium.isPremium;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsEntryLabel),
        actions: [
          if (isPremium)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.resetStatsButton,
              onPressed: _confirmReset,
            ),
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            tooltip: l10n.premiumLockedTitle,
            onPressed: _openUnlock,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<StatsPeriod>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: StatsPeriod.day, label: Text(l10n.periodDay)),
                ButtonSegment(value: StatsPeriod.week, label: Text(l10n.periodWeek)),
                ButtonSegment(value: StatsPeriod.month, label: Text(l10n.periodMonth)),
                ButtonSegment(value: StatsPeriod.year, label: Text(l10n.periodYear)),
              ],
              selected: {_period},
              onSelectionChanged: (selection) => _onPeriodChanged(selection.first),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<PremiumStatsSnapshot>(
                  future: _snapshotFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      // Hive boxes are shared with the challenge overlay's own
                      // separate Flutter engine — a reload racing a read is
                      // rare but possible. Never surface that as a crash
                      // screen: just retry, which re-reads the (by then
                      // settled) boxes a moment later.
                      return _RetryPrompt(onRetry: _refresh);
                    }
                    final data = snapshot.data;
                    if (data == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final body = _StatsBody(snapshot: data, period: _period, icons: _icons);
                    if (isPremium) return body;
                    return _BlurredTeaser(onUnlock: _openUnlock, child: body);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown over the real (already-computed) stats for non-premium users: the
/// numbers are blurred rather than hidden, so there's something concrete —
/// "there's a real figure here" — behind the unlock prompt instead of a
/// blank locked screen.
class _BlurredTeaser extends StatelessWidget {
  final Widget child;
  final VoidCallback onUnlock;

  const _BlurredTeaser({required this.child, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: child,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    l10n.unlockTeaserTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onUnlock, child: Text(l10n.unlockButton)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _vsPreviousLabel(AppLocalizations l10n, StatsPeriod period) {
  switch (period) {
    case StatsPeriod.day:
      return l10n.statVsPreviousDay;
    case StatsPeriod.week:
      return l10n.statVsPreviousWeek;
    case StatsPeriod.month:
      return l10n.statVsPreviousMonth;
    case StatsPeriod.year:
      return l10n.statVsPreviousYear;
  }
}

class _StatsBody extends StatelessWidget {
  final PremiumStatsSnapshot snapshot;
  final StatsPeriod period;
  final Map<String, Uint8List?> icons;

  const _StatsBody({required this.snapshot, required this.period, required this.icons});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appNames = {for (final app in AppConfigRepository().getAll()) app.packageName: app.appName};

    final appEntries = snapshot.dissuasionByApp.entries.where((e) => e.value.triggered > 0).toList()
      ..sort((a, b) => (b.value.dissuasionRate ?? 0).compareTo(a.value.dissuasionRate ?? 0));
    final typeEntries = snapshot.dissuasionByType.entries.where((e) => e.value.triggered > 0).toList()
      ..sort((a, b) => (b.value.dissuasionRate ?? 0).compareTo(a.value.dissuasionRate ?? 0));

    return ListView(
      children: [
        _MetricCard(label: l10n.statVsBeforeInstall, minutes: snapshot.minutesSavedVsBeforeInstall),
        if (!snapshot.vsBeforeInstallComplete)
          _IncompleteNote(text: l10n.vsBeforeInstallIncompleteNote),
        const SizedBox(height: 8),
        _MetricCard(label: _vsPreviousLabel(l10n, period), minutes: snapshot.minutesSavedVsPreviousPeriod),
        if (!snapshot.vsPreviousPeriodComplete)
          _IncompleteNote(text: l10n.vsPreviousPeriodIncompleteNote),
        const SizedBox(height: 8),
        _MetricCard(label: l10n.statEstimate, minutes: snapshot.minutesSavedEstimate),
        const SizedBox(height: 24),
        Text(l10n.dissuasionByAppTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (appEntries.isEmpty)
          Text(l10n.noDataForPeriod)
        else
          ...appEntries.map((e) {
            final rate = ((e.value.dissuasionRate ?? 0) * 100).round();
            final name = appNames[e.key] ?? e.key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(l10n.typeBreakdownLine(name, rate, e.value.triggered)),
            );
          }),
        const SizedBox(height: 24),
        Text(l10n.typeBreakdownTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (typeEntries.isEmpty)
          Text(l10n.noDataForPeriod)
        else
          ...typeEntries.map((e) {
            final rate = ((e.value.dissuasionRate ?? 0) * 100).round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(l10n.typeBreakdownLine(e.key.label(context), rate, e.value.triggered)),
            );
          }),
        const SizedBox(height: 24),
        Text(l10n.perAppDetailTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...snapshot.perApp.map((detail) => _AppRow(detail: detail, period: period, icon: icons[detail.packageName])),
      ],
    );
  }
}

class _RetryPrompt extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _RetryPrompt({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.statsLoadErrorText),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(l10n.retryLabel)),
        ],
      ),
    );
  }
}

class _IncompleteNote extends StatelessWidget {
  final String text;

  const _IncompleteNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// Icon + app name, expanding in place (state survives switching the period
/// at the top, via [PageStorageKey]) to show that app's own breakdown —
/// no navigation needed to compare periods for one app.
class _AppRow extends StatelessWidget {
  final AppStatsDetail detail;
  final StatsPeriod period;
  final Uint8List? icon;

  const _AppRow({required this.detail, required this.period, required this.icon});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeEntries = detail.dissuasionByType.entries.where((e) => e.value.triggered > 0).toList()
      ..sort((a, b) => (b.value.dissuasionRate ?? 0).compareTo(a.value.dissuasionRate ?? 0));

    return ExpansionTile(
      key: PageStorageKey<String>(detail.packageName),
      tilePadding: EdgeInsets.zero,
      leading: icon != null ? CircleAvatar(backgroundImage: MemoryImage(icon!)) : const Icon(Icons.apps),
      title: Text(detail.appName),
      childrenPadding: const EdgeInsets.only(bottom: 16),
      children: [
        _MetricCard(
          label: l10n.statVsBeforeInstall,
          minutes: detail.vsBeforeInstallReliable ? detail.vsBeforeInstall : null,
        ),
        if (!detail.vsBeforeInstallReliable) _IncompleteNote(text: l10n.vsBeforeInstallIncompleteNote),
        const SizedBox(height: 8),
        _MetricCard(
          label: _vsPreviousLabel(l10n, period),
          minutes: detail.vsPreviousPeriodReliable ? detail.vsPreviousPeriod : null,
        ),
        if (!detail.vsPreviousPeriodReliable) _IncompleteNote(text: l10n.vsPreviousPeriodIncompleteNote),
        const SizedBox(height: 8),
        _MetricCard(label: l10n.statEstimate, minutes: detail.estimate),
        if (typeEntries.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.typeBreakdownTitle, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          ...typeEntries.map((e) {
            final rate = ((e.value.dissuasionRate ?? 0) * 100).round();
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(l10n.typeBreakdownLine(e.key.label(context), rate, e.value.triggered)),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int? minutes;

  const _MetricCard({required this.label, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label)),
            Text(
              minutes != null ? formatMinutes(minutes!) : l10n.notAvailableLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: (minutes ?? 0) > 0 ? Colors.green : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return '$mins min';
  return '${hours}h${mins.toString().padLeft(2, '0')}';
}
