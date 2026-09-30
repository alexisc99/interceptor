import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

enum _SimonPhase { preparing, playback, input, wrong }

class SimonScreen extends StatefulWidget {
  final VoidCallback onSolved;

  const SimonScreen({super.key, required this.onSolved});

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

class _SimonScreenState extends State<SimonScreen> {
  static const _sequenceLength = 5;
  static const _colors = [Colors.red, Colors.green, Colors.blue, Colors.amber];
  static const _preparingDelay = Duration(milliseconds: 1500);
  static const _correctTapFlash = Duration(milliseconds: 200);
  static const _wrongPause = Duration(milliseconds: 700);

  late List<int> _sequence;
  int _inputIndex = 0;
  _SimonPhase _phase = _SimonPhase.preparing;
  int? _highlighted;

  @override
  void initState() {
    super.initState();
    _newSequence();
  }

  void _newSequence() {
    _sequence = List.generate(_sequenceLength, (_) => Random().nextInt(_colors.length));
    _inputIndex = 0;
    _highlighted = null;
    _playSequence();
  }

  Future<void> _playSequence() async {
    // Give the user a beat to read the prompt before the squares start
    // flashing, instead of the sequence starting the instant this loads.
    setState(() => _phase = _SimonPhase.preparing);
    await Future.delayed(_preparingDelay);
    if (!mounted) return;

    setState(() => _phase = _SimonPhase.playback);
    for (var i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() => _highlighted = _sequence[i]);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _highlighted = null);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    setState(() => _phase = _SimonPhase.input);
  }

  Future<void> _tap(int colorIndex) async {
    if (_phase != _SimonPhase.input) return;

    final isCorrect = colorIndex == _sequence[_inputIndex];
    setState(() => _highlighted = colorIndex);

    if (isCorrect) {
      await Future.delayed(_correctTapFlash);
      if (!mounted) return;
      setState(() => _highlighted = null);

      _inputIndex++;
      if (_inputIndex == _sequence.length) {
        widget.onSolved();
        return;
      }
      setState(() {});
    } else {
      // Keep the wrong square lit while the "Raté" message shows, for clear feedback.
      setState(() => _phase = _SimonPhase.wrong);
      await Future.delayed(_wrongPause);
      if (mounted) _newSequence();
    }
  }

  String _statusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_phase) {
      case _SimonPhase.preparing:
        return l10n.simonPreparing;
      case _SimonPhase.playback:
        return l10n.simonPlayback;
      case _SimonPhase.input:
        return l10n.simonInput(_inputIndex, _sequence.length);
      case _SimonPhase.wrong:
        return l10n.simonWrong;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_statusText(context), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: List.generate(_colors.length, (i) {
            final isLit = _highlighted == i;
            return GestureDetector(
              onTap: () => _tap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
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
