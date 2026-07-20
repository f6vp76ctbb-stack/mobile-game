/// Pure-Dart piece definitions for GridPop. No Flutter imports.
///
/// A [Piece] is a set of cell offsets relative to its top-left origin.
/// Pieces are never rotated by the player — each rotation is its own catalog
/// entry (genre convention). See MASTERPLAN.md Anhang A.1 for the weights.
library;

import 'dart:math' as math;

/// An immutable (row, column) offset within a piece or on the board.
class Cell {
  const Cell(this.row, this.col);

  final int row;
  final int col;

  Cell operator +(Cell other) => Cell(row + other.row, col + other.col);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

/// A placeable block shape.
class Piece {
  Piece(this.id, List<Cell> cells, this.weight)
      : assert(cells.isNotEmpty, 'piece must have at least one cell'),
        assert(weight > 0, 'weight must be positive'),
        cells = _normalize(cells) {
    var maxR = 0;
    var maxC = 0;
    for (final c in this.cells) {
      maxR = math.max(maxR, c.row);
      maxC = math.max(maxC, c.col);
    }
    height = maxR + 1;
    width = maxC + 1;
  }

  /// Stable identifier, unique within the catalog.
  final String id;

  /// Cell offsets, normalized so the minimum row and column are both 0.
  final List<Cell> cells;

  /// Relative spawn weight for the generator.
  final int weight;

  /// Bounding-box dimensions.
  late final int width;
  late final int height;

  int get size => cells.length;

  /// This piece rotated 90° clockwise (normalized back to origin). The id is
  /// kept — a rotated piece is the same catalog entry in a different
  /// orientation (only tray pieces are ever rotated, via the rotate feature).
  Piece rotatedCw() => Piece(
        id,
        [for (final c in cells) Cell(c.col, height - 1 - c.row)],
        weight,
      );

  /// Shifts each cell so the top-left of the bounding box sits at (0, 0),
  /// then sorts for a deterministic ordering.
  static List<Cell> _normalize(List<Cell> cells) {
    var minR = cells.first.row;
    var minC = cells.first.col;
    for (final c in cells) {
      minR = math.min(minR, c.row);
      minC = math.min(minC, c.col);
    }
    final shifted = [
      for (final c in cells) Cell(c.row - minR, c.col - minC),
    ]..sort((a, b) => a.row != b.row ? a.row - b.row : a.col - b.col);
    return List.unmodifiable(shifted);
  }

  @override
  String toString() => 'Piece($id, size=$size, weight=$weight)';
}

/// The full, weighted piece catalog (MASTERPLAN.md Anhang A.1).
///
/// Kept as a top-level function returning a fresh list so tests can inspect it
/// without shared mutable state.
List<Piece> buildCatalog() {
  final pieces = <Piece>[
    // Single block.
    Piece('dot', const [Cell(0, 0)], 4),

    // Lines — horizontal + vertical.
    Piece('line2_h', const [Cell(0, 0), Cell(0, 1)], 6),
    Piece('line2_v', const [Cell(0, 0), Cell(1, 0)], 6),
    Piece('line3_h', const [Cell(0, 0), Cell(0, 1), Cell(0, 2)], 6),
    Piece('line3_v', const [Cell(0, 0), Cell(1, 0), Cell(2, 0)], 6),
    Piece('line4_h', const [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(0, 3)], 5),
    Piece('line4_v', const [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(3, 0)], 5),
    Piece(
      'line5_h',
      const [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(0, 3), Cell(0, 4)],
      3,
    ),
    Piece(
      'line5_v',
      const [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(3, 0), Cell(4, 0)],
      3,
    ),

    // Squares.
    Piece(
      'square2',
      const [Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1)],
      6,
    ),
    Piece(
      'square3',
      const [
        Cell(0, 0), Cell(0, 1), Cell(0, 2),
        Cell(1, 0), Cell(1, 1), Cell(1, 2),
        Cell(2, 0), Cell(2, 1), Cell(2, 2),
      ],
      3,
    ),

    // Rectangles.
    Piece(
      'rect2x3',
      const [
        Cell(0, 0), Cell(0, 1), Cell(0, 2),
        Cell(1, 0), Cell(1, 1), Cell(1, 2),
      ],
      4,
    ),
    Piece(
      'rect3x2',
      const [
        Cell(0, 0), Cell(0, 1),
        Cell(1, 0), Cell(1, 1),
        Cell(2, 0), Cell(2, 1),
      ],
      4,
    ),

    // Small L (tromino) — 4 rotations.
    Piece('lsmall_0', const [Cell(0, 0), Cell(1, 0), Cell(1, 1)], 5),
    Piece('lsmall_1', const [Cell(0, 0), Cell(0, 1), Cell(1, 0)], 5),
    Piece('lsmall_2', const [Cell(0, 0), Cell(0, 1), Cell(1, 1)], 5),
    Piece('lsmall_3', const [Cell(0, 1), Cell(1, 0), Cell(1, 1)], 5),

    // Big L (5 cells) — 4 rotations.
    Piece(
      'lbig_0',
      const [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(2, 1), Cell(2, 2)],
      3,
    ),
    Piece(
      'lbig_1',
      const [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(1, 0), Cell(2, 0)],
      3,
    ),
    Piece(
      'lbig_2',
      const [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(1, 2), Cell(2, 2)],
      3,
    ),
    Piece(
      'lbig_3',
      const [Cell(0, 2), Cell(1, 2), Cell(2, 0), Cell(2, 1), Cell(2, 2)],
      3,
    ),

    // S / Z tetrominoes — 2 rotations each.
    Piece('s_h', const [Cell(0, 1), Cell(0, 2), Cell(1, 0), Cell(1, 1)], 3),
    Piece('s_v', const [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(2, 1)], 3),
    Piece('z_h', const [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 2)], 3),
    Piece('z_v', const [Cell(0, 1), Cell(1, 0), Cell(1, 1), Cell(2, 0)], 3),

    // T tetromino — 4 rotations.
    Piece('t_0', const [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(1, 1)], 4),
    Piece('t_1', const [Cell(0, 1), Cell(1, 0), Cell(1, 1), Cell(2, 1)], 4),
    Piece('t_2', const [Cell(0, 1), Cell(1, 0), Cell(1, 1), Cell(1, 2)], 4),
    Piece('t_3', const [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(2, 0)], 4),
  ];
  return List.unmodifiable(pieces);
}
