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
                          BoardView(size: boardSize),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.highscore,
    required this.combo,
    required this.fever,
  });

  final int score;
  final int highscore;
  final int combo;
  final double fever;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('PUNKTE', '$score'),
              if (combo > 1)
                Text(
                  'COMBO x$combo',
                  style: const TextStyle(
                    color: GridColors.fever,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
            style: const TextStyle(color: GridColors.textPrimary, fontSize: 22),
          ),
          if (snap.isNewHighscore)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Neuer Rekord! 🎉',
                style: TextStyle(color: GridColors.fever, fontSize: 16),
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
    );
  }
}
