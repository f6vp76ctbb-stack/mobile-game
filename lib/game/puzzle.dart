/// Pure-Dart Puzzle Mode (MASTERPLAN.md C.4). No Flutter imports.
///
/// A [Puzzle] is a pre-filled board plus a fixed piece sequence; the goal is to
/// empty the board by placing the pieces (in order), completing and clearing
/// lines. Levels are built *constructively* so a solution is guaranteed, and
/// the [PuzzleSolver] additionally validates each level and reports the minimum
/// number of moves (for star rating).
library;

import 'dart:math';

import 'board.dart';
import 'piece.dart';

class Puzzle {
  const Puzzle({
    required this.level,
    required this.start,
    required this.pieces,
    required this.minMoves,
  });

  final int level;
  final Board start;
  final List<Piece> pieces;

  /// Fewest moves to empty the board (3-star target).
  final int minMoves;
}

/// 64-bit bitboard helpers: cell (r,c) -> bit r*8 + c.
class BitBoard {
  const BitBoard._();

  static const int fullRow0 = 0xFF; // row 0
  static const int col0 = 0x0101010101010101; // column 0

  static int fromBoard(Board b) {
    var mask = 0;
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        if (b.filledAt(r, c)) mask |= 1 << (r * Board.size + c);
      }
    }
    return mask;
  }

  /// The bit mask of [piece] placed with its top-left at (row, col).
  static int pieceMaskAt(Piece piece, int row, int col) {
    var mask = 0;
    for (final cell in piece.cells) {
      mask |= 1 << ((row + cell.row) * Board.size + (col + cell.col));
    }
    return mask;
  }

  /// Adds [pieceMask] and removes any completed rows/columns.
  static int applyPlacement(int board, int pieceMask) {
    final next = board | pieceMask;
    var cleared = 0;
    for (var r = 0; r < Board.size; r++) {
      final rowMask = fullRow0 << (r * Board.size);
      if (next & rowMask == rowMask) cleared |= rowMask;
    }
    for (var c = 0; c < Board.size; c++) {
      final colMask = col0 << c;
      if (next & colMask == colMask) cleared |= colMask;
    }
    return next & ~cleared;
  }
}

class PuzzleSolver {
  const PuzzleSolver._();

  /// All legal top-left placement masks for [piece] on an 8x8 board (ignoring
  /// occupancy — filtered at solve time).
  static List<int> _placements(Piece piece) {
    final out = <int>[];
    for (var r = 0; r <= Board.size - piece.height; r++) {
      for (var c = 0; c <= Board.size - piece.width; c++) {
        out.add(BitBoard.pieceMaskAt(piece, r, c));
      }
    }
    return out;
  }

  /// Minimum moves to empty [start] by placing [pieces] in order, or null if
  /// impossible. Pieces must be placed in sequence; reaching an empty board
  /// ends the puzzle (remaining pieces are unused).
  static int? minMovesToEmpty(Board start, List<Piece> pieces) {
    final placements = [for (final p in pieces) _placements(p)];
    final memo = <String, int?>{};

    int? solve(int board, int idx) {
      if (board == 0) return 0;
      if (idx >= pieces.length) return null;
      final key = '${board}_$idx';
      final cached = memo[key];
      if (cached != null || memo.containsKey(key)) return cached;

      int? best;
      for (final mask in placements[idx]) {
        if (board & mask != 0) continue; // overlap
        final next = BitBoard.applyPlacement(board, mask);
        final sub = solve(next, idx + 1);
        if (sub != null && (best == null || sub + 1 < best)) {
          best = sub + 1;
        }
      }
      memo[key] = best;
      return best;
    }

    return solve(BitBoard.fromBoard(start), 0);
  }
}

/// Star rating and coin rewards for puzzle levels (MASTERPLAN.md C.4).
class PuzzleRules {
  const PuzzleRules._();

  /// 3 stars = optimal, 2 = within +2 moves, 1 = solved at all.
  static int stars({required int moves, required int minMoves}) {
    if (moves <= minMoves) return 3;
    if (moves <= minMoves + 2) return 2;
    return 1;
  }

  /// 10 coins per level, +25 bonus on every 10th level.
  static int coinReward(int level) => 10 + ((level + 1) % 10 == 0 ? 25 : 0);
}

class PuzzleGenerator {
  const PuzzleGenerator._();

  static const int seedBase = 0x2A75E1; // "RÄTSEL"

  /// Builds puzzle [level] deterministically. Guaranteed solvable by
  /// construction; the solver both verifies it and measures the minimum moves.
  static Puzzle generate(int level) {
    final rng = Random(seedBase + level);
    final catalog = buildCatalog()
        .where((p) => p.height <= 3 && p.size >= 2)
        .toList();

    final targetLayers = (2 + level ~/ 8).clamp(2, 4);
    final cells = List<bool>.filled(Board.size * Board.size, false);
    final pieces = <Piece>[];

    var top = 0;
    for (var layer = 0; layer < targetLayers; layer++) {
      // Leave at least the last row empty, so no column is ever fully filled
      // in the start board (a pre-full column would clear on the first move
      // and tear holes in the other bands, making the level unsolvable).
      final maxH = min(3, (Board.size - 1) - top);
      if (maxH < 1) break;
      final candidates = catalog.where((p) => p.height <= maxH).toList();
      if (candidates.isEmpty) break;
      final piece = candidates[rng.nextInt(candidates.length)];
      final h = piece.height;
      final w = piece.width;
      final colOffset = rng.nextInt(Board.size - w + 1);

      // Fill this band's rows completely, then carve out the piece shape.
      for (var r = top; r < top + h; r++) {
        for (var c = 0; c < Board.size; c++) {
          cells[r * Board.size + c] = true;
        }
      }
      for (final cell in piece.cells) {
        cells[(top + cell.row) * Board.size + (colOffset + cell.col)] = false;
      }
      pieces.add(piece);
      top += h;
      if (top >= Board.size) break;
    }

    final start = Board.fromAscii([
      for (var r = 0; r < Board.size; r++)
        String.fromCharCodes([
          for (var c = 0; c < Board.size; c++)
            cells[r * Board.size + c] ? 0x23 : 0x2e,
        ]),
    ]);

    final minMoves = PuzzleSolver.minMovesToEmpty(start, pieces);
    assert(minMoves != null, 'constructed puzzle $level must be solvable');

    return Puzzle(
      level: level,
      start: start,
      pieces: pieces,
      minMoves: minMoves ?? pieces.length,
    );
  }
}
