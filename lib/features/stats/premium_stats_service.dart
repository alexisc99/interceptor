import '../../core/platform/interception_channel.dart';
import '../../core/storage/app_config_repository.dart';
import '../../core/storage/stats_repository.dart';

enum StatsPeriod { day, week, month, year }

/// Beyond this many days back, Android's own UsageStatsManager history has
/// degraded past its reliable granularity, and querying it live is no
/// longer trustworthy — our own [StatsRepository.usageHistoryInRange] is
/// used instead past this point. Android keeps precise daily buckets for
/// about a week, but *weekly* buckets for about four weeks, so a full
/// "last week" query (7-13 days back) is still safely answered live — it's
/// specifically older, *partial* ranges (e.g. 18 days into a month from
/// over a month ago, which only has a coarse monthly bucket to answer from)
/// that produced bogus, inflated numbers (see the "vs last month"
/// investigation). 14 days safely covers the whole of "last week" while
/// still forcing month/year comparisons onto our own recorded history.
const _liveQueryReliableDays = 14;

/// [start, end) covers the currently selected period; [previousStart,
/// previousEnd) covers the immediately preceding period of the same length,
/// used for the "vs last period" comparison.
class StatsPeriodRange {
  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime previousEnd;

  const StatsPeriodRange({
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
  });

  int get days => end.difference(start).inDays;

  /// [end] is always the theoretical end of the *current* period, which is
  /// always in the future relative to now (e.g. "end of this month"). This
  /// caps it at [now] so usage queries only ever cover time that's actually
  /// happened — otherwise averages get diluted by days that haven't
  /// occurred yet, making early-period numbers look artificially huge.
  DateTime elapsedEnd(DateTime now) => now.isBefore(end) ? now : end;

  /// Days actually elapsed so far in the period (at least 1, so division
  /// never blows up right at the start of a period).
  int elapsedDays(DateTime now) => elapsedEnd(now).difference(start).inDays.clamp(1, days);

  /// The same point within the *previous* period as [now] is within this
  /// one, so "vs previous period" compares the same number of days on both
  /// sides instead of a partial current period against a full previous one.
  DateTime previousElapsedEnd(DateTime now) => previousStart.add(elapsedEnd(now).difference(start));
}

StatsPeriodRange periodRange(StatsPeriod period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case StatsPeriod.day:
      final start = today;
      final end = start.add(const Duration(days: 1));
      return StatsPeriodRange(
        start: start,
        end: end,
        previousStart: start.subtract(const Duration(days: 1)),
        previousEnd: start,
      );
    case StatsPeriod.week:
      final start = today.subtract(Duration(days: today.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return StatsPeriodRange(
        start: start,
        end: end,
        previousStart: start.subtract(const Duration(days: 7)),
        previousEnd: start,
      );
    case StatsPeriod.month:
      final start = DateTime(today.year, today.month, 1);
      final end = DateTime(today.year, today.month + 1, 1);
      return StatsPeriodRange(
        start: start,
        end: end,
        previousStart: DateTime(today.year, today.month - 1, 1),
        previousEnd: start,
      );
    case StatsPeriod.year:
      final start = DateTime(today.year, 1, 1);
      final end = DateTime(today.year + 1, 1, 1);
      return StatsPeriodRange(
        start: start,
        end: end,
        previousStart: DateTime(today.year - 1, 1, 1),
        previousEnd: start,
      );
  }
}

/// Per-app breakdown for one [StatsPeriod]: how much time this specific app
/// saved, and which of its challenge types deterred best.
class AppStatsDetail {
  final String packageName;
  final String appName;
  final int vsBeforeInstall;
  final bool vsBeforeInstallReliable;
  final int vsPreviousPeriod;
  final bool vsPreviousPeriodReliable;
  final int estimate;
  final Map<ChallengeType, AppStats> dissuasionByType;

  const AppStatsDetail({
    required this.packageName,
    required this.appName,
    required this.vsBeforeInstall,
    required this.vsBeforeInstallReliable,
    required this.vsPreviousPeriod,
    required this.vsPreviousPeriodReliable,
    required this.estimate,
    required this.dissuasionByType,
  });
}

/// The advanced-stats snapshot for one [StatsPeriod]. Totals are summed
/// across every currently targeted app; [perApp] breaks the same numbers
/// down per app.
class PremiumStatsSnapshot {
  /// Time saved vs. each app's own pre-Interceptor baseline (the week
  /// before it was added), projected over the selected period. Only counts
  /// apps whose baseline was captured in time — see [vsBeforeInstallComplete].
  final int minutesSavedVsBeforeInstall;

  /// False if at least one app's pre-install baseline was never captured
  /// (it was added more than a week ago, before this feature existed, and
  /// that historical window can no longer be recovered reliably).
  final bool vsBeforeInstallComplete;

  /// Time saved vs. the immediately preceding period of the same length.
  /// Only counts apps with reliable data for that comparison — see
  /// [vsPreviousPeriodComplete].
  final int minutesSavedVsPreviousPeriod;

  /// False if the previous-period comparison reaches further back than our
  /// own recorded history covers for at least one app, meaning
  /// [minutesSavedVsPreviousPeriod] is an undercount, not the real total.
  final bool vsPreviousPeriodComplete;

  /// Estimate: average session length × number of dissuasions, summed
  /// across apps — "what those dissuaded sessions would likely have cost".
  final int minutesSavedEstimate;

  final Map<String, AppStats> dissuasionByApp;
  final Map<ChallengeType, AppStats> dissuasionByType;
  final List<AppStatsDetail> perApp;

  const PremiumStatsSnapshot({
    required this.minutesSavedVsBeforeInstall,
    required this.vsBeforeInstallComplete,
    required this.minutesSavedVsPreviousPeriod,
    required this.vsPreviousPeriodComplete,
    required this.minutesSavedEstimate,
    required this.dissuasionByApp,
    required this.dissuasionByType,
    required this.perApp,
  });
}

Future<PremiumStatsSnapshot> computePremiumStats(StatsPeriod period) async {
  final now = DateTime.now();
  final range = periodRange(period, now);
  final apps = AppConfigRepository().getAll();
  final stats = StatsRepository();

  final rangeEndInclusive = range.end.subtract(const Duration(milliseconds: 1));
  final dissuasionByApp = stats.packageStatsInRange(range.start, rangeEndInclusive);
  final dissuasionByType = stats.typeStatsInRange(range.start, rangeEndInclusive);

  final perAppGains = await Future.wait(apps.map((app) {
    return _computeAppGains(
      app,
      range,
      now,
      stats,
      dissuasionByApp[app.packageName]?.cancelled ?? 0,
    );
  }));

  var vsBeforeInstall = 0;
  var vsPreviousPeriod = 0;
  var estimate = 0;
  var vsBeforeInstallComplete = true;
  var vsPreviousPeriodComplete = true;
  final perApp = <AppStatsDetail>[];

  for (var i = 0; i < apps.length; i++) {
    final app = apps[i];
    final gains = perAppGains[i];
    estimate += gains.estimate;
    if (gains.vsBeforeInstallReliable) {
      vsBeforeInstall += gains.vsBeforeInstall;
    } else {
      vsBeforeInstallComplete = false;
    }
    if (gains.vsPreviousPeriodReliable) {
      vsPreviousPeriod += gains.vsPreviousPeriod;
    } else {
      vsPreviousPeriodComplete = false;
    }
    perApp.add(AppStatsDetail(
      packageName: app.packageName,
      appName: app.appName,
      vsBeforeInstall: gains.vsBeforeInstall,
      vsBeforeInstallReliable: gains.vsBeforeInstallReliable,
      vsPreviousPeriod: gains.vsPreviousPeriod,
      vsPreviousPeriodReliable: gains.vsPreviousPeriodReliable,
      estimate: gains.estimate,
      dissuasionByType: stats.typeStatsForAppInRange(app.packageName, range.start, rangeEndInclusive),
    ));
  }

  return PremiumStatsSnapshot(
    minutesSavedVsBeforeInstall: vsBeforeInstall,
    vsBeforeInstallComplete: vsBeforeInstallComplete,
    minutesSavedVsPreviousPeriod: vsPreviousPeriod,
    vsPreviousPeriodComplete: vsPreviousPeriodComplete,
    minutesSavedEstimate: estimate,
    dissuasionByApp: dissuasionByApp,
    dissuasionByType: dissuasionByType,
    perApp: perApp,
  );
}

class _AppGains {
  final int vsBeforeInstall;
  final bool vsBeforeInstallReliable;
  final int vsPreviousPeriod;
  final bool vsPreviousPeriodReliable;
  final int estimate;

  const _AppGains(
    this.vsBeforeInstall,
    this.vsBeforeInstallReliable,
    this.vsPreviousPeriod,
    this.vsPreviousPeriodReliable,
    this.estimate,
  );
}

/// The pre-install baseline is a fixed historical window (the week before
/// [app.addedAt]) — once that's more than [_liveQueryReliableDays] in the
/// past, Android can no longer answer it reliably, and there is no way to
/// recover it later. So it's captured once, the first time it's still
/// fresh, and cached forever; after that window has passed uncaptured, it's
/// permanently unavailable.
Future<int?> _beforeInstallBaseline(TargetAppConfig app, DateTime now, StatsRepository stats) async {
  final cached = stats.beforeInstallBaselineMinutes(app.packageName);
  if (cached != null) return cached;

  if (now.difference(app.addedAt).inDays > _liveQueryReliableDays) return null;
  // Removed too recently before this addition: the 7-day window would
  // still overlap days this app was actively challenged, not free use.
  if (!stats.canCaptureBaseline(app.packageName, app.addedAt)) return null;

  final live = await InterceptionChannel.getUsageMinutesInRange(
    app.packageName,
    app.addedAt.subtract(const Duration(days: 7)),
    app.addedAt,
  );
  if (live != null) await stats.setBeforeInstallBaselineMinutes(app.packageName, live);
  return live;
}

Future<_AppGains> _computeAppGains(
  TargetAppConfig app,
  StatsPeriodRange range,
  DateTime now,
  StatsRepository stats,
  int dissuasionsInRange,
) async {
  final elapsedEnd = range.elapsedEnd(now);
  final elapsedDays = range.elapsedDays(now);
  final previousElapsedEnd = range.previousElapsedEnd(now);

  // The previous-period window is old enough that Android's own history for
  // it may already be coarse/unreliable — prefer our own recorded history.
  final previousWindowIsOld = now.difference(range.previousStart).inDays > _liveQueryReliableDays;
  final previousHistory = stats.usageHistoryInRange(app.packageName, range.previousStart, previousElapsedEnd);

  // "vs before Interceptor" must only count days since the app was actually
  // added — if it was added mid-period, the period's nominal start is
  // earlier than that and would otherwise mix in unmonitored days on the
  // "during" side, diluting a real gain down to nothing.
  final baselineDuringStart = app.addedAt.isAfter(range.start) ? app.addedAt : range.start;
  final baselineDuringDays = elapsedEnd.difference(baselineDuringStart).inDays.clamp(1, elapsedDays);
  // When the app was added before this period (the common case),
  // baselineDuringStart == range.start, so this window and "the period so
  // far" below are the exact same [start, end) query — asking the native
  // side twice for identical data.
  final baselineWindowCoversFullPeriod = baselineDuringStart == range.start;

  final results = await Future.wait([
    _beforeInstallBaseline(app, now, stats),
    InterceptionChannel.getUsageMinutesInRange(app.packageName, baselineDuringStart, elapsedEnd),
    // Only the days actually elapsed so far — the period's nominal end is
    // always in the future (e.g. "end of this month"), and including it
    // would divide real usage by days that haven't happened yet.
    if (!baselineWindowCoversFullPeriod)
      InterceptionChannel.getUsageMinutesInRange(app.packageName, range.start, elapsedEnd),
    // Same elapsed-day window, but in the previous period — only queried
    // live when recent enough to trust; otherwise we rely solely on our
    // own recorded history (below).
    previousWindowIsOld
        ? Future.value(null)
        : InterceptionChannel.getUsageMinutesInRange(app.packageName, range.previousStart, previousElapsedEnd),
    dissuasionsInRange > 0
        ? InterceptionChannel.getAverageSessionMinutes(app.packageName, range.start, elapsedEnd)
        : Future.value(null),
  ]);

  final beforeInstallMinutes = results[0] as int?;
  final baselineDuringMinutes = results[1] as int?;
  var i = 2;
  final periodMinutes = baselineWindowCoversFullPeriod ? baselineDuringMinutes : results[i++] as int?;
  final livePreviousPeriodMinutes = results[i++] as int?;
  final avgSessionMinutes = results[i++] as double?;

  var vsBeforeInstall = 0;
  if (beforeInstallMinutes != null && baselineDuringMinutes != null) {
    final avgBeforePerDay = beforeInstallMinutes / 7;
    final avgDuringPerDay = baselineDuringMinutes / baselineDuringDays;
    final gainPerDay = avgBeforePerDay - avgDuringPerDay;
    if (gainPerDay > 0) vsBeforeInstall = (gainPerDay * baselineDuringDays).round();
  }
  final vsBeforeInstallReliable = beforeInstallMinutes != null;

  // Prefer our own history once the window is old enough to need it; only
  // trust it if it actually covers every day in that window.
  final previousPeriodMinutes = previousWindowIsOld ? previousHistory.minutes : livePreviousPeriodMinutes;
  final vsPreviousPeriodReliable = previousWindowIsOld ? previousHistory.complete : livePreviousPeriodMinutes != null;

  var vsPreviousPeriod = 0;
  if (periodMinutes != null && previousPeriodMinutes != null) {
    final gain = previousPeriodMinutes - periodMinutes;
    if (gain > 0) vsPreviousPeriod = gain;
  }

  var estimate = 0;
  if (avgSessionMinutes != null) {
    estimate = (avgSessionMinutes * dissuasionsInRange).round();
  }

  return _AppGains(vsBeforeInstall, vsBeforeInstallReliable, vsPreviousPeriod, vsPreviousPeriodReliable, estimate);
}
