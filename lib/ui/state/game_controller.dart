/// Riverpod bridge between the pure-Dart [GameSession] and the widgets.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/board.dart';
import '../../game/game_session.dart';
import '../../game/piece.dart';
import '../../services/storage.dart';

/// Provided once at startup (overridden in main after async init).
final storageProvider = Provider<Storage>(
  (ref) => throw UnimplementedError('storageProvider must be overridden'),
);

/// Immutable view of the current run for the widget tree.
@immutable
class GameSnapshot {
  const GameSnapshot({
    required this.board,
    required this.tray,
    required this.score,
    required this.combo,
    required this.feverLevel,
    required this.gameOver,
    required this.highscore,
    required this.isNewHighscore,
  });

  final Board board;
  final List<Piece?> tray;
  final int score;
  final int combo;
  final double feverLevel;
  final bool gameOver;
  final int highscore;
  final bool isNewHighscore;
}

final gameControllerProvider =
    StateNotifierProvider<GameController, GameSnapshot>((ref) {
  return GameController(ref.read(storageProvider));
});

class GameController extends StateNotifier<GameSnapshot> {
  GameController(this._storage, {int? seed})
      : _session = GameSession.newGame(seed: seed ?? _randomSeed()),
        super(_initialSnapshot(_storage)) {
    _emit();
  }

  final Storage _storage;
  GameSession _session;
  bool _isNewHighscore = false;

  static int _randomSeed() => Random().nextInt(1 << 31);

  static GameSnapshot _initialSnapshot(Storage storage) {
    final s = GameSession.newGame(seed: 0);
    return GameSnapshot(
      board: s.board,
      tray: s.tray,
      score: 0,
      combo: 0,
      feverLevel: 0,
      gameOver: false,
      highscore: storage.highscore,
      isNewHighscore: false,
    );
  }

  /// Starts a fresh endless run (or a specific [seed], e.g. the Daily seed).
  void newGame({int? seed}) {
    _session = GameSession.newGame(seed: seed ?? _randomSeed());
    _isNewHighscore = false;
    _emit();
  }

  /// Attempts to place tray[slot] at [origin]. No-op if illegal.
  void place(int slot, Cell origin) {
    final event = _session.place(slot, origin);
    if (event == null) return;
    if (_session.isGameOver) {
      _finishRun();
    }
    _emit();
  }

  bool canPlace(int slot, Cell origin) => _session.canPlace(slot, origin);

  /// Applies the "Revive" reward: clears the central 4x4 block.
  void revive() {
    _session.reviveClearCenter();
    _emit();
  }

  void _finishRun() {
    // Fire-and-forget persistence; the UI reads the flag from the snapshot.
    _storage.submitScore(_session.score).then((isRecord) {
      if (isRecord && mounted) {
        _isNewHighscore = true;
        _emit();
      }
    });
  }

  void _emit() {
    state = GameSnapshot(
      board: _session.board,
      tray: _session.tray,
      score: _session.score,
      combo: _session.combo,
      feverLevel: _session.feverLevel,
      gameOver: _session.isGameOver,
      highscore: max(_storage.highscore, _session.score),
      isNewHighscore: _isNewHighscore,
    );
  }
}
