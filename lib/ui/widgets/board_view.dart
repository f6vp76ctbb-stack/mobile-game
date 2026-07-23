/// The 8x8 board: renders cells, placed blocks and the live drag preview.
///
/// The [DragTarget] that accepts tray pieces lives in the game screen and
/// covers board *and* tray area — with the finger-lift, the finger is below
/// the hovering piece, so drops for the bottom rows land outside the board.
/// The preview state is shared via [dragPreviewProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/block_skin.dart';
import '../../game/board.dart';
import '../../game/piece.dart';
import '../state/skin_controller.dart';
import '../state/theme_controller.dart';
import 'cell_style.dart';

/// How far above the finger the piece is anchored while dragging (in cells),
/// so the finger never covers the piece.
const double kFingerLiftCells = 1.2;

/// How far (in cells) outside the board a drag may sit and still snap to the
/// nearest edge cell. Beyond this, the drag counts as "not over the board".
const double _kSnapSlackCells = 0.75;

/// Live drag state shared between the game screen's [DragTarget] and the
/// board painter.
@immutable
class DragPreview {
  const DragPreview({
    required this.piece,
    required this.origin,
    required this.valid,
  });

  final Piece piece;
  final Cell origin;
  final bool valid;
}

final dragPreviewProvider = StateProvider<DragPreview?>((ref) => null);

/// Maps the drag feedback's top-left (global) to a board origin cell.
///
/// [feedbackTopLeft] is `DragTargetDetails.offset`: the top-left of the
/// feedback widget, which renders the piece at board scale — so the visible
/// piece position IS the placement position (no finger math needed here; the
/// finger-lift is applied by the drag anchor in the tray).
/// Returns null when the piece is too far from the board to snap.
Cell? boardOriginForDrag({
  required GlobalKey boardKey,
  required Piece piece,
  required Offset feedbackTopLeft,
}) {
  final box = boardKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final cell = box.size.width / Board.size;
  if (cell <= 0) return null;

  final local = box.globalToLocal(feedbackTopLeft);
  final rawCol = local.dx / cell;
  final rawRow = local.dy / cell;

  // Snap only when the piece is on the board or within the slack margin.
  if (rawCol < -_kSnapSlackCells ||
      rawCol > Board.size - piece.width + _kSnapSlackCells ||
      rawRow < -_kSnapSlackCells ||
      rawRow > Board.size - piece.height + _kSnapSlackCells) {
    return null;
  }

  final col = rawCol.round().clamp(0, Board.size - piece.width);
  final row = rawRow.round().clamp(0, Board.size - piece.height);
  return Cell(row, col);
}

class BoardView extends ConsumerWidget {
  const BoardView({
    super.key,
    required this.size,
    required this.board,
    required this.boardKey,
    this.onCellTap,
  });

  /// Side length of the (square) board in logical pixels.
  final double size;

  final Board board;

  /// Attached to the board container so the game screen can map global drag
  /// positions into board coordinates.
  final GlobalKey boardKey;

  /// When set (e.g. bomb-targeting mode), a tap on the board reports the tapped
  /// cell instead of dragging. Null = normal play.
  final void Function(Cell cell)? onCellTap;

  double get _cell => size / Board.size;

  void _handleTap(Offset localPos) {
    final onCellTap = this.onCellTap;
    if (onCellTap == null) return;
    final row = (localPos.dy / _cell).floor().clamp(0, Board.size - 1);
    final col = (localPos.dx / _cell).floor().clamp(0, Board.size - 1);
    onCellTap(Cell(row, col));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(activeThemeProvider);
    final skin = ref.watch(activeSkinProvider);
    final preview = ref.watch(dragPreviewProvider);
    final bombMode = onCellTap != null;

    final boardBox = Container(
      key: boardKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.boardBackground,
        borderRadius: BorderRadius.circular(_cell * 0.25),
        border: bombMode ? Border.all(color: theme.fever, width: 2) : null,
      ),
      child: CustomPaint(
        painter: _BoardPainter(
          board: board,
          cell: _cell,
          previewPiece: preview?.piece,
          previewOrigin: preview?.origin,
          previewValid: preview?.valid ?? false,
          emptyColor: theme.emptyCell,
          placedColor: theme.placed,
          placedColors: theme.traySlots,
          validColor: theme.validPreview,
          invalidColor: theme.invalidPreview,
          skin: skin,
        ),
      ),
    );

    // In bomb-targeting mode a tap picks the cell; dragging is disabled.
    if (bombMode) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _handleTap(d.localPosition),
        child: boardBox,
      );
    }
    return boardBox;
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.cell,
    required this.previewPiece,
    required this.previewOrigin,
    required this.previewValid,
    required this.emptyColor,
    required this.placedColor,
    required this.placedColors,
    required this.validColor,
    required this.invalidColor,
    required this.skin,
  });

  final Board board;
  final double cell;
  final Piece? previewPiece;
  final Cell? previewOrigin;
  final bool previewValid;
  final Color emptyColor;
  final Color placedColor;
  final List<Color> placedColors;
  final Color validColor;
  final Color invalidColor;
  final BlockSkinStyle skin;

  @override
  void paint(Canvas canvas, Size size) {
    final radiusValue = cell * 0.22;
    final radius = Radius.circular(radiusValue);
    const inset = 1.5;

    Rect cellRect(int row, int col) => Rect.fromLTWH(
      col * cell + inset,
      row * cell + inset,
      cell - inset * 2,
      cell - inset * 2,
    );

    void drawCell(int row, int col, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect(row, col), radius),
        Paint()..color = color,
      );
    }

    // Empty grid + locked cells (locked cells use the active block skin).
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        if (board.filledAt(r, c)) {
          paintCell(
            canvas,
            cellRect(r, c),
            radiusValue,
            placedColors[(board.colorAt(r, c) ?? 0) % placedColors.length],
            skin,
          );
        } else {
          drawCell(r, c, emptyColor);
        }
      }
    }

    // Drag preview.
    final piece = previewPiece;
    final origin = previewOrigin;
    if (piece != null && origin != null) {
      final color = previewValid ? validColor : invalidColor;
      for (final offset in piece.cells) {
        final r = origin.row + offset.row;
        final c = origin.col + offset.col;
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          drawCell(r, c, color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.board != board ||
      old.previewPiece != previewPiece ||
      old.previewOrigin != previewOrigin ||
      old.previewValid != previewValid ||
      old.placedColor != placedColor ||
      old.placedColors != placedColors ||
      old.emptyColor != emptyColor ||
      old.skin != skin;
}
