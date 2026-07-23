/// Pure-Dart, seedable piece generator for GridPop. No Flutter imports.
///
/// Fairness rules (MASTERPLAN.md Anhang A.2):
///  1. A tray always holds 3 pieces; a new tray is drawn only once all 3 are
///     placed (the caller owns that lifecycle).
///  2. Rescue: if none of the 3 drawn pieces fit the board, the last slot is
///     replaced by the largest currently-placeable piece. If nothing fits at
///     all, game over is legitimate.
///  3. Early phase (first 10 placements of a run): placeable pieces get a
///     x1.5 weight bonus. Afterwards, base weights only.
///  4. Fully determined by the seed — basis for the Daily Challenge and tests.
library;

import 'dart:math';

import 'board.dart';
import 'piece.dart';

class PieceGenerator {
  PieceGenerator({
    required int seed,
    List<Piece>? catalog,
    this.earlyPhaseMoves = defaultEarlyPhaseMoves,
  }) : assert(earlyPhaseMoves >= 0),
       _rng = Random(seed),
       catalog = catalog ?? buildCatalog();

  static const int defaultEarlyPhaseMoves = 10;
  static const double earlyPlaceableBonus = 1.5;

  final Random _rng;
  final List<Piece> catalog;
  final int earlyPhaseMoves;

  /// Draws a tray of 3 pieces for the given [board] state and the number of
  /// [placementsSoFar] in the current run.
  List<Piece> nextTray(Board board, int placementsSoFar) {
    final early = placementsSoFar < earlyPhaseMoves;
    final tray = <Piece>[
      for (var i = 0; i < 3; i++) _weightedPick(board, early),
    ];

    // Rescue rule: guarantee at least one placeable piece when possible.
    final anyPlaceable = tray.any(board.hasAnyPlacement);
    if (!anyPlaceable) {
      final rescue = _largestPlaceable(board);
      if (rescue != null) tray[2] = rescue;
    }
    return tray;
  }

  double _effectiveWeight(Piece p, Board board, bool early) {
    final base = p.weight.toDouble();
    if (early && board.hasAnyPlacement(p)) return base * earlyPlaceableBonus;
    return base;
  }

  Piece _weightedPick(Board board, bool early) {
    var totalWeight = 0.0;
    for (final p in catalog) {
      totalWeight += _effectiveWeight(p, board, early);
    }
    var roll = _rng.nextDouble() * totalWeight;
    for (final p in catalog) {
      roll -= _effectiveWeight(p, board, early);
      if (roll <= 0) return p;
    }
    return catalog.last; // floating-point guard
  }

  /// The placeable piece with the most cells (ties broken by weight, then id),
  /// or null if nothing fits.
  Piece? _largestPlaceable(Board board) {
    Piece? best;
    for (final p in catalog) {
      if (!board.hasAnyPlacement(p)) continue;
      if (best == null ||
          p.size > best.size ||
          (p.size == best.size && p.weight > best.weight) ||
          (p.size == best.size &&
              p.weight == best.weight &&
              p.id.compareTo(best.id) < 0)) {
        best = p;
      }
    }
    return best;
  }
}
