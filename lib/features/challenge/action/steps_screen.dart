import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class StepsScreen extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onUnavailable;

  const StepsScreen({super.key, required this.onSolved, required this.onUnavailable});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  static const _target = 15;

  StreamSubscription<StepCount>? _sub;
  int? _baseline;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _sub = Pedometer.stepCountStream.listen(_onStepCount, onError: (_) => widget.onUnavailable());
  }

  void _onStepCount(StepCount event) {
    _baseline ??= event.steps;
    final done = event.steps - _baseline!;
    setState(() => _steps = done.clamp(0, _target));
    if (done >= _target) {
      _sub?.cancel();
      widget.onSolved();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_steps / _target).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Fais quelques pas, téléphone en main', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: progress, strokeWidth: 10),
              Text('$_steps/$_target', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
