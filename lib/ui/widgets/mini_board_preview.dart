/// Miniature board rendering used as the store preview for themes and block
/// skins: empty cells plus a few placed pieces, so buyers see the palette and
/// skin style in actual game context instead of bare colour swatches.
library;

import 'package:flutter/material.dart';

import '../../game/block_skin.dart';
import '../theme.dart';
import 'cell_style.dart';

/// Filled cells on the 6x6 preview grid as (col, row, colorIndex), where
/// 0-2 index [GameTheme.traySlots] and 3 means [GameTheme.placed].
const List<(int, int, int)> _previewCells = [
  // 2x2 square (tray slot 1)
  (4, 0, 1), (5, 0, 1), (4, 1, 1), (5, 1, 1),
  // small L (tray slot 0)
  (1, 1, 0), (1, 2, 0), (2, 2, 0),
  // vertical 3-line (tray slot 2)
  (0, 3, 2), (0, 4, 2), (0, 5, 2),
  // locked block near the bottom (placed colour)
  (2, 4, 3), (3, 4, 3), (4, 4, 3), (2, 5, 3), (3, 5, 3), (4, 5, 3),
];

class MiniBoardPreview extends StatelessWidget {
  const MiniBoardPreview({
    super.key,
    required this.theme,
    required this.style,
    this.size = 64,
  });

  final GameTheme theme;
  final BlockSkinStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniBoardPainter(theme: theme, style: style),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  _MiniBoardPainter({required this.theme, required this.style});

  final GameTheme theme;
  final BlockSkinStyle style;

  static const _grid = 6;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = theme.boardBackground,
    );

    final pad = size.width * 0.07;
    final gap = size.width * 0.025;
    final cell = (size.width - 2 * pad - (_grid - 1) * gap) / _grid;
    final radius = cell * 0.24;

    Rect rectAt(int col, int row) => Rect.fromLTWH(
          pad + col * (cell + gap),
          pad + row * (cell + gap),
          cell,
          cell,
        );

    final empty = Paint()..color = theme.emptyCell;
    for (var row = 0; row < _grid; row++) {
      for (var col = 0; col < _grid; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rectAt(col, row), Radius.circular(radius)),
          empty,
        );
      }
    }

    for (final (col, row, colorIndex) in _previewCells) {
      final color = colorIndex == 3
          ? theme.placed
          : theme.traySlots[colorIndex % theme.traySlots.length];
      paintCell(canvas, rectAt(col, row), radius, color, style);
    }
  }

  @override
  bool shouldRepaint(_MiniBoardPainter old) =>
      old.theme != theme || old.style != style;
}
