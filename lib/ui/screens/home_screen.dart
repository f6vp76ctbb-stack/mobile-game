/// Home screen: title, best score and the entry point into a run.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../theme.dart';
import 'game_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highscore = ref.watch(gameControllerProvider).highscore;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GridPop',
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Block Puzzle',
                style: TextStyle(color: GridColors.textMuted, fontSize: 18),
              ),
              const SizedBox(height: 48),
              Text(
                'Bestwert: $highscore',
                style: const TextStyle(
                  color: GridColors.placed,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56,
                    vertical: 18,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  ref.read(gameControllerProvider.notifier).newGame();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GameScreen(),
                    ),
                  );
                },
                child: const Text('Spielen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
