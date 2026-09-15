import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SimonScreen extends StatefulWidget {
  final VoidCallback onSolved;

  const SimonScreen({super.key, required this.onSolved});

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

class _SimonScreenState extends State<SimonScreen> {
  static const _sequenceLength = 5;
  static const _colors = [Colors.red, Colors.green, Colors.blue, Colors.amber];

  late List<int> _sequence;
  int _playbackIndex = -1;
  int _inputIndex = 0;
  bool _canInput = false;
  int? _highlighted;
  int? _wrongIndex;

  @override
  void initState() {
    super.initState();
    _newSequence();
  }

  void _newSequence() {
    _sequence = List.generate(_sequenceLength, (_) => Random().nextInt(_colors.length));
    _inputIndex = 0;
    _canInput = false;
    _wrongIndex = null;
    _playSequence();
  }

  Future<void> _playSequence() async {
    for (var i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() {
        _playbackIndex = i;
        _highlighted = _sequence[i];
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _highlighted = null);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    setState(() {
      _playbackIndex = -1;
      _canInput = true;
    });
  }

  void _tap(int colorIndex) {
    if (!_canInput) return;
    if (colorIndex == _sequence[_inputIndex]) {
      _inputIndex++;
      if (_inputIndex == _sequence.length) {
        widget.onSolved();
        return;
      }
      setState(() {});
    } else {
      setState(() {
        _canInput = false;
        _wrongIndex = colorIndex;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _newSequence();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _playbackIndex >= 0
              ? 'Regarde la séquence...'
              : _wrongIndex != null
                  ? 'Raté, nouvelle séquence...'
                  : 'Reproduis la séquence ($_inputIndex/${_sequence.length})',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: List.generate(_colors.length, (i) {
            final isLit = _highlighted == i || _wrongIndex == i;
            return GestureDetector(
              onTap: () => _tap(i),
              child: Container(
                decoration: BoxDecoration(
                  color: isLit ? _colors[i] : _colors[i].withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
