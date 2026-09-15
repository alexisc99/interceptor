import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeScreen extends StatefulWidget {
  final VoidCallback onSolved;

  const ShakeScreen({super.key, required this.onSolved});

  @override
  State<ShakeScreen> createState() => _ShakeScreenState();
}

class _ShakeScreenState extends State<ShakeScreen> {
  static const _target = 8;
  static const _shakeThreshold = 18.0;
  static const _cooldown = Duration(milliseconds: 350);

  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen(_onEvent);
  }

  void _onEvent(AccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final delta = (magnitude - 9.8).abs();
    if (delta < _shakeThreshold) return;

    final now = DateTime.now();
    if (now.difference(_lastShake) < _cooldown) return;
    _lastShake = now;

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
        const Text('Secoue le téléphone', textAlign: TextAlign.center),
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
