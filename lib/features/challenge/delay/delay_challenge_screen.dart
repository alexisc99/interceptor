import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../challenge_scaffold.dart';

class DelayChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;
  final ChallengeType resolvedType;
  final int? usageMinutesToday;

  const DelayChallengeScreen({
    super.key,
    required this.appConfig,
    required this.resolvedType,
    required this.usageMinutesToday,
  });

  @override
  State<DelayChallengeScreen> createState() => _DelayChallengeScreenState();
}

class _DelayChallengeScreenState extends State<DelayChallengeScreen> with WidgetsBindingObserver {
  static const _duration = 8;
  static const _questionCount = 4;

  late final int _questionIndex = Random().nextInt(_questionCount);
  int _remaining = _duration;
  Timer? _timer;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining--);
      if (_remaining <= 0) _timer?.cancel();
    });
  }

  // The point of the wait is that it costs real, present attention — a
  // Dart Timer keeps firing even while this engine is backgrounded, so
  // without this the countdown would quietly finish itself while the user
  // did something else and came back to find it already done.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_timer == null && _remaining > 0) _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _continue() async {
    await StatsRepository().recordSolved(widget.appConfig.packageName, widget.resolvedType);
    setState(() => _solved = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questions = [l10n.delayQuestion1, l10n.delayQuestion2, l10n.delayQuestion3, l10n.delayQuestion4];
    final canContinue = _remaining <= 0;
    return ChallengeScaffold(
      icon: Icons.self_improvement,
      packageName: widget.appConfig.packageName,
      appName: widget.appConfig.appName,
      resolvedType: widget.resolvedType,
      usageMinutesToday: widget.usageMinutesToday,
      solved: _solved,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            questions[_questionIndex],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: canContinue ? _continue : null,
            child: Text(canContinue ? l10n.continueLabel : l10n.continueWithCountdown(_remaining)),
          ),
        ],
      ),
    );
  }
}
