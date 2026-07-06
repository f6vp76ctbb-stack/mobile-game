/// Lifetime statistics overview.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageProvider);
    final stats = storage.lifetimeStats;
    final puzzleStars = storage.puzzleStars;
    final puzzlesSolved = puzzleStars.length;
    final totalStars = puzzleStars.values.fold(0, (a, b) => a + b);

    final tiles = <(String, String)>[
      ('Bestwert', '${storage.highscore}'),
      ('Level', '${storage.playerLevel}'),
      ('Runden gespielt', '${stats.games}'),
      ('Ø Punkte', '${stats.averageScore}'),
      ('Größte Combo', '${max(stats.bestCombo, 0)}'),
      ('Reihen geräumt', '${stats.totalLines}'),
      ('Teile platziert', '${stats.totalPieces}'),
      ('Rätsel gelöst', '$puzzlesSolved'),
      ('Rätsel-Sterne', '$totalStars'),
      ('Münzen', '${storage.coins}'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        backgroundColor: GridColors.background,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.6,
        children: [
          for (final (label, value) in tiles) _StatTile(label: label, value: value),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GridColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: GridColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: GridColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
