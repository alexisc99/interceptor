import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../challenge_scaffold.dart';

class MathChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;
  final ChallengeType resolvedType;
  final int? usageMinutesToday;

  const MathChallengeScreen({
    super.key,
    required this.appConfig,
    required this.resolvedType,
    required this.usageMinutesToday,
  });

  @override
  State<MathChallengeScreen> createState() => _MathChallengeScreenState();
}

class _MathChallengeScreenState extends State<MathChallengeScreen> {
  final _stats = StatsRepository();
  final _controller = TextEditingController();
  final _random = Random();

  late int _a;
  late int _b;
  late String _operator;
  bool _wasWrong = false;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    _a = _random.nextInt(89) + 10;
    _b = _random.nextInt(89) + 10;
    _operator = _random.nextBool() ? '+' : '-';
    if (_operator == '-' && _b > _a) {
      final tmp = _a;
      _a = _b;
      _b = tmp;
    }
    _controller.clear();
  }

  int get _expected => _operator == '+' ? _a + _b : _a - _b;

  Future<void> _submit() async {
    final answer = int.tryParse(_controller.text.trim());
    if (answer == _expected) {
      await _stats.recordSolved(widget.appConfig.packageName, widget.resolvedType);
      setState(() => _solved = true);
    } else {
      setState(() {
        _wasWrong = true;
        _generateProblem();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChallengeScaffold(
      icon: Icons.lock_clock,
      packageName: widget.appConfig.packageName,
      appName: widget.appConfig.appName,
      resolvedType: widget.resolvedType,
      usageMinutesToday: widget.usageMinutesToday,
      solved: _solved,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.mathPrompt, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Text(
            '$_a $_operator $_b = ?',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: _wasWrong ? l10n.mathWrongAnswer : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: Text(l10n.validateLabel)),
        ],
      ),
    );
  }
}
