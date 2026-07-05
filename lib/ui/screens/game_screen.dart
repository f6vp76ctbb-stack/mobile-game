/// The main play screen: score header, board, tray and game-over overlay.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../theme.dart';
import '../widgets/board_view.dart';
import '../widgets/tray_view.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(gameControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  score: snap.score,
                  highscore: snap.highscore,
                  combo: snap.combo,
                  fever: snap.feverLevel,
                  isDaily: snap.isDaily,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const trayHeight = 96.0;
                      const gap = 16.0;
                      final maxBoard = constraints.maxWidth - 24;
                      final boardSize = maxBoard
                          .clamp(0.0, constraints.maxHeight - trayHeight - gap);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FeverGlow(
                            fever: snap.feverLevel,
                            child: BoardView(size: boardSize),
                          ),
                          const SizedBox(height: gap),
                          TrayView(
                            boardCell: boardSize / 8,
                            height: trayHeight,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            if (snap.gameOver) _GameOverOverlay(snap: snap),
          ],
        ),
      ),
    );
  }
}

/// A soft glow around the board that intensifies with the fever meter.
class _FeverGlow extends StatelessWidget {
  const _FeverGlow({required this.fever, required this.child});

  final double fever;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final f = fever.clamp(0.0, 1.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (f > 0)
            BoxShadow(
              color: GridColors.fever.withValues(alpha: f * 0.6),
              blurRadius: f * 34,
              spreadRadius: f * 4,
            ),
        ],
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.highscore,
    required this.combo,
    required this.fever,
    required this.isDaily,
  });

  final int score;
  final int highscore;
  final int combo;
  final double fever;
  final bool isDaily;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          if (isDaily)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'TÄGLICHE CHALLENGE',
                style: TextStyle(
                  color: GridColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('PUNKTE', '$score'),
              if (combo > 1) _ComboBadge(combo: combo),
              _stat('BEST', '$highscore', alignEnd: true),
            ],
          ),
          const SizedBox(height: 10),
          _FeverBar(level: fever),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: GridColors.textMuted, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: GridColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Combo indicator that pulses each time the combo count changes.
class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.combo});

  final int combo;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(combo),
      tween: Tween(begin: 1.35, end: 1.0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Text(
        'COMBO x$combo',
        style: const TextStyle(
          color: GridColors.fever,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _FeverBar extends StatelessWidget {
  const _FeverBar({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: level.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: GridColors.emptyCell,
        valueColor: const AlwaysStoppedAnimation(GridColors.fever),
      ),
    );
  }
}

class _GameOverOverlay extends ConsumerWidget {
  const _GameOverOverlay({required this.snap});

  final GameSnapshot snap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${snap.score} Punkte',
              style:
                  const TextStyle(color: GridColors.textPrimary, fontSize: 22),
            ),
            if (snap.isNewHighscore)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Neuer Rekord! 🎉',
                  style: TextStyle(color: GridColors.fever, fontSize: 16),
                ),
              ),
            if (snap.isDaily && snap.streak > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '🔥 ${snap.streak} Tage Streak',
                  style: const TextStyle(
                    color: GridColors.fever,
                    fontSize: 16,
                  ),
                ),
              ),
            if (snap.coinsEarnedThisRun > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '🪙 +${snap.coinsEarnedThisRun} Münzen',
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            for (final mission in snap.completedMissions)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '✓ $mission',
                  style: const TextStyle(
                    color: GridColors.placed,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 28),
            // Revive is a placeholder until Rewarded Ads land in Phase 3.
            FilledButton.tonal(
              onPressed: controller.revive,
              child: const Text('Weiterspielen (Board-Mitte leeren)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => controller.newGame(),
              child: const Text('Nochmal'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Hauptmenü'),
            ),
          ],
        ),
      ),
    );
  }
}
