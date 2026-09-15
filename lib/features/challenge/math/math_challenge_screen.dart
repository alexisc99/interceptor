import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/platform/challenge_channel.dart';
import '../../../core/storage/app_config_repository.dart';
import '../../../core/storage/stats_repository.dart';
import '../challenge_scaffold.dart';

class MathChallengeScreen extends StatefulWidget {
  final TargetAppConfig appConfig;
  final int? usageMinutesToday;

  const MathChallengeScreen({super.key, required this.appConfig, required this.usageMinutesToday});

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
      await _stats.incrementSolved();
      await ChallengeChannel.onChallengeSolved();
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
    return ChallengeScaffold(
      icon: Icons.lock_clock,
      appName: widget.appConfig.appName,
      usageMinutesToday: widget.usageMinutesToday,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Résous ce petit calcul pour continuer, histoire de faire ce choix en conscience.',
            textAlign: TextAlign.center,
          ),
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
              errorText: _wasWrong ? 'Pas tout à fait, réessaie.' : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Valider')),
        ],
      ),
    );
  }
}
