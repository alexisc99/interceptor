import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects footsteps from the accelerometer directly, rather than Android's
/// native step counter sensor: that one batches updates (sometimes for a
/// minute or more before delivering anything), which makes it unusable for
/// a short-lived challenge.
class StepsScreen extends StatefulWidget {
  final VoidCallback onSolved;

  const StepsScreen({super.key, required this.onSolved});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  static const _target = 15;
  static const _stepThreshold = 3.5;
  static const _cooldown = Duration(milliseconds: 280);

  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastStep = DateTime.fromMillisecondsSinceEpoch(0);
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen(_onEvent);
  }

  void _onEvent(AccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final delta = (magnitude - 9.8).abs();
    if (delta < _stepThreshold) return;

    final now = DateTime.now();
    if (now.difference(_lastStep) < _cooldown) return;
    _lastStep = now;

    setState(() => _count++);
    if (_count >= _target) {
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
    final progress = (_count / _target).clamp(0.0, 1.0);
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
              Text('$_count/$_target', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
