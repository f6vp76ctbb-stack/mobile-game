/// The three-slot piece tray. Each piece is draggable onto the board and can
/// be tapped to rotate it 90° (free in beginner mode, else one charge).
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
  const TrayView({super.key, required this.boardCell, required this.height});

  /// Board cell size — the feedback piece uses it so it matches the board 1:1.
  final double boardCell;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tray = ref.watch(gameControllerProvider).tray;
    final slotColors = ref.watch(activeThemeProvider).traySlots;
    final skin = ref.watch(activeSkinProvider);
    // Tray pieces render a little smaller than board cells to leave padding.
    final trayCell = boardCell < 12
        ? boardCell
        : ((height - 24) / 5).clamp(12.0, boardCell);

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var slot = 0; slot < tray.length; slot++)
            Expanded(
              child: Center(
                child: _slot(
                  context,
                  ref,
                  tray[slot],
                  slot,
                  trayCell,
                  slotColors,
                  skin,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    WidgetRef ref,
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

    void rotate() {
      final ok = ref.read(gameControllerProvider.notifier).rotateTray(slot);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text('Keine Drehungen übrig — räume Reihen zum Aufladen!'),
          ),
        );
      }
    }

    return Draggable<int>(
      data: slot,
      dragAnchorStrategy: (draggable, context, position) =>
          Offset(feedbackW / 2, feedbackH / 2 + kFingerLiftCells * boardCell),
      // Safety net: whatever way the drag ends, never leave a stale preview.
      onDragEnd: (_) => ref.read(dragPreviewProvider.notifier).state = null,
      feedback: PieceView(
        piece: piece,
        cellSize: boardCell,
        color: color,
        skin: skin,
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: PieceView(
          piece: piece,
          cellSize: trayCell,
          color: color,
          skin: skin,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PieceView(piece: piece, cellSize: trayCell, color: color, skin: skin),
          Tooltip(
            message: 'Teil drehen',
            child: IconButton(
              onPressed: rotate,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 28, height: 22),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.rotate_right_rounded, size: 21),
            ),
          ),
        ],
      ),
    );
  }
}
