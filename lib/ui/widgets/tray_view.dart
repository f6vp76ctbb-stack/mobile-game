/// The three-slot piece tray. Each piece is draggable onto the board.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/block_skin.dart';
import '../../game/piece.dart';
import '../state/game_controller.dart';
import '../state/skin_controller.dart';
import '../state/theme_controller.dart';
import 'board_view.dart';
import 'piece_view.dart';

class TrayView extends ConsumerWidget {
  const TrayView({
    super.key,
    required this.boardCell,
    required this.height,
  });

  /// Board cell size — the feedback piece uses it so it matches the board 1:1.
  final double boardCell;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tray = ref.watch(gameControllerProvider).tray;
    final slotColors = ref.watch(activeThemeProvider).traySlots;
    final skin = ref.watch(activeSkinProvider);
    // Tray pieces render a little smaller than board cells to leave padding.
    final trayCell = (height / 5).clamp(16.0, boardCell);

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var slot = 0; slot < tray.length; slot++)
            Expanded(
              child: Center(
                child: _slot(tray[slot], slot, trayCell, slotColors, skin),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slot(
    Piece? piece,
    int slot,
    double trayCell,
    List<Color> colors,
    BlockSkinStyle skin,
  ) {
    if (piece == null) return const SizedBox.shrink();
    final color = colors[slot % colors.length];

    final feedbackW = piece.width * boardCell;
    final feedbackH = piece.height * boardCell;

    return Draggable<int>(
      data: slot,
      dragAnchorStrategy: (draggable, context, position) => Offset(
        feedbackW / 2,
        feedbackH / 2 + kFingerLiftCells * boardCell,
      ),
      feedback:
          PieceView(piece: piece, cellSize: boardCell, color: color, skin: skin),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: PieceView(
          piece: piece,
          cellSize: trayCell,
          color: color,
          skin: skin,
        ),
      ),
      child: PieceView(
        piece: piece,
        cellSize: trayCell,
        color: color,
        skin: skin,
      ),
    );
  }
}
