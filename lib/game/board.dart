/// Pure-Dart 8x8 board for GridPop. No Flutter imports.
library;

import 'piece.dart';

/// Result of placing a piece: the resulting board plus what got cleared.
class PlacementResult {
  const PlacementResult({
    required this.board,
    required this.clearedRows,
    required this.clearedCols,
    required this.clearedCells,
    required this.placedCells,
  });

  final Board board;
  final int clearedRows;
  final int clearedCols;

  /// Every cell that was removed by line clears this placement.
  final Set<Cell> clearedCells;

  /// The cells the piece itself occupied (before any clear).
  final int placedCells;

  /// Total cleared lines (rows + columns).
  int get clearedLines => clearedRows + clearedCols;

  /// True when the board is completely empty after this placement.
  bool get isAllClear => board.isEmpty;
}

/// An immutable 8x8 grid. Filled cells are `true`.
class Board {
  Board._(this._cells);

  /// Standard board edge length.
  static const int size = 8;

  final List<bool> _cells; // row-major, length == size * size

  factory Board.empty() => Board._(List<bool>.filled(size * size, false));

  /// Builds a board from ASCII rows. `#`/`X`/`■` = filled, anything else empty.
  /// Must be exactly [size] rows of [size] characters.
  factory Board.fromAscii(List<String> rows) {
    assert(rows.length == size, 'expected $size rows, got ${rows.length}');
    final cells = List<bool>.filled(size * size, false);
    for (var r = 0; r < size; r++) {
      final row = rows[r];
      assert(row.length == size, 'row $r must have $size chars: "$row"');
      for (var c = 0; c < size; c++) {
        final ch = row[c];
        cells[r * size + c] = ch == '#' || ch == 'X' || ch == '■';
      }
    }
    return Board._(cells);
  }

  static int _idx(int r, int c) => r * size + c;

  bool filledAt(int r, int c) => _cells[_idx(r, c)];

  bool get isEmpty => !_cells.contains(true);

  int get filledCount => _cells.where((f) => f).length;

  bool _inBounds(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  /// Whether [piece] fits at [origin] (top-left of its bounding box) with no
  /// out-of-bounds cell and no overlap.
  bool canPlace(Piece piece, Cell origin) {
    for (final offset in piece.cells) {
      final r = origin.row + offset.row;
      final c = origin.col + offset.col;
      if (!_inBounds(r, c) || _cells[_idx(r, c)]) return false;
    }
    return true;
  }

  /// Whether [piece] can be placed at any position on this board.
  bool hasAnyPlacement(Piece piece) {
    for (var r = 0; r <= size - piece.height; r++) {
      for (var c = 0; c <= size - piece.width; c++) {
        if (canPlace(piece, Cell(r, c))) return true;
      }
    }
    return false;
  }

  /// Places [piece] at [origin] and clears any full rows/columns.
  /// Caller must ensure [canPlace] is true.
  PlacementResult place(Piece piece, Cell origin) {
    assert(canPlace(piece, origin), 'illegal placement of ${piece.id}');
    final next = List<bool>.of(_cells);
    for (final offset in piece.cells) {
      next[_idx(origin.row + offset.row, origin.col + offset.col)] = true;
    }

    final fullRows = <int>[];
    for (var r = 0; r < size; r++) {
      var full = true;
      for (var c = 0; c < size; c++) {
        if (!next[_idx(r, c)]) {
          full = false;
          break;
        }
      }
      if (full) fullRows.add(r);
    }

    final fullCols = <int>[];
    for (var c = 0; c < size; c++) {
      var full = true;
      for (var r = 0; r < size; r++) {
        if (!next[_idx(r, c)]) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }

    final cleared = <Cell>{};
    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        cleared.add(Cell(r, c));
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        cleared.add(Cell(r, c));
      }
    }
    for (final cell in cleared) {
      next[_idx(cell.row, cell.col)] = false;
    }

    return PlacementResult(
      board: Board._(next),
      clearedRows: fullRows.length,
      clearedCols: fullCols.length,
      clearedCells: cleared,
      placedCells: piece.size,
    );
  }

  /// Renders the board as ASCII rows (`#` filled, `.` empty) for tests/debug.
  List<String> toAscii() => [
        for (var r = 0; r < size; r++)
          String.fromCharCodes([
            for (var c = 0; c < size; c++) filledAt(r, c) ? 0x23 : 0x2e,
          ]),
      ];

  @override
  String toString() => toAscii().join('\n');
}
