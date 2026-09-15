import 'dart:math';

import 'package:flutter/material.dart';

class SchulteGridScreen extends StatefulWidget {
  final VoidCallback onSolved;

  const SchulteGridScreen({super.key, required this.onSolved});

  @override
  State<SchulteGridScreen> createState() => _SchulteGridScreenState();
}

class _SchulteGridScreenState extends State<SchulteGridScreen> {
  static const _gridSize = 9;

  late List<int> _numbers;
  int _next = 1;

  @override
  void initState() {
    super.initState();
    _numbers = List.generate(_gridSize, (i) => i + 1)..shuffle(Random());
  }

  void _tap(int value) {
    if (value != _next) return;
    setState(() => _next++);
    if (_next > _gridSize) widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Touche les nombres dans l\'ordre, de 1 à $_gridSize', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: _numbers.map((n) {
            final done = n < _next;
            return GestureDetector(
              onTap: () => _tap(n),
              child: Container(
                decoration: BoxDecoration(
                  color: done ? Colors.green.shade300 : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text('$n', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
