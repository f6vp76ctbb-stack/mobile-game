/// Grid of puzzle levels with star ratings; unlocks progress as levels are won.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../theme.dart';
import 'puzzle_screen.dart';

class PuzzleLevelsScreen extends ConsumerStatefulWidget {
  const PuzzleLevelsScreen({super.key});

  @override
  ConsumerState<PuzzleLevelsScreen> createState() => _PuzzleLevelsScreenState();
}

class _PuzzleLevelsScreenState extends ConsumerState<PuzzleLevelsScreen> {
  @override
  Widget build(BuildContext context) {
    final stars = ref.read(storageProvider).puzzleStars;
    final solvedMax = stars.keys.isEmpty ? -1 : stars.keys.reduce(max);
    final unlockedCount = solvedMax + 2; // 0..solvedMax+1 are playable

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rätsel-Modus'),
        backgroundColor: GridColors.background,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: unlockedCount,
        itemBuilder: (context, level) => _LevelTile(
          level: level,
          stars: stars[level] ?? 0,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PuzzleScreen(level: level),
              ),
            );
            if (mounted) setState(() {}); // refresh stars/unlocks on return
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.stars,
    required this.onTap,
  });

  final int level;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final solved = stars > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: GridColors.boardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: solved ? GridColors.placed : GridColors.gridLine,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${level + 1}',
              style: const TextStyle(
                color: GridColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              solved ? '⭐' * stars : '···',
              style: TextStyle(
                fontSize: 12,
                color: solved ? null : GridColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
