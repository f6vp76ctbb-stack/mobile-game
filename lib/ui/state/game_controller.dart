/// Riverpod bridge between the pure-Dart [GameSession] and the widgets.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/board.dart';
import '../../game/daily.dart';
import '../../game/game_session.dart';
import '../../game/missions.dart';
import '../../game/piece.dart';
import '../../game/streak.dart';
import '../../services/audio.dart';
import '../../services/haptics.dart';
import '../../services/storage.dart';

/// Provided once at startup (overridden in main after async init).
final storageProvider = Provider<Storage>(
  (ref) => throw UnimplementedError('storageProvider must be overridden'),
);

final hapticsProvider = Provider<Haptics>((ref) => Haptics());
final audioProvider = Provider<AudioService>((ref) => SilentAudio());

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
    required this.coins,
    required this.coinsEarnedThisRun,
    required this.completedMissions,
    required this.isDaily,
    required this.streak,
    required this.onboardingHint,
    required this.clearEventId,
    required this.clearedCells,
  });

  final Board board;
  final List<Piece?> tray;
  final int score;
  final int combo;
  final double feverLevel;
  final bool gameOver;
  final int highscore;
  final bool isNewHighscore;
  final int coins;
  final int coinsEarnedThisRun;
  final List<String> completedMissions;
  final bool isDaily;
  final int streak;

  /// Short coach hint for the first-run guided moves, or null when inactive.
  final String? onboardingHint;

  /// Increments on every move that clears lines — the UI keys clear-burst
  /// particle animations off this so each clear fires exactly once.
  final int clearEventId;

  /// Cells removed by the most recent clear (empty if the last move cleared
  /// nothing).
  final List<Cell> clearedCells;
}

final gameControllerProvider =
    StateNotifierProvider<GameController, GameSnapshot>((ref) {
  return GameController(
    ref.read(storageProvider),
    ref.read(hapticsProvider),
    ref.read(audioProvider),
  );
});

class GameController extends StateNotifier<GameSnapshot> {
  GameController(this._storage, this._haptics, this._audio, {int? seed})
      : _missions = MissionEngine(progress: _storage.missionProgress),
        _session = GameSession.newGame(seed: seed ?? _randomSeed()),
        super(_initialSnapshot(_storage)) {
    _emit();
  }

  final Storage _storage;
  final Haptics _haptics;
  final AudioService _audio;
  final MissionEngine _missions;

  GameSession _session;
  bool _isNewHighscore = false;
  bool _isDaily = false;
  bool _finalized = false;
  int _coinsEarnedThisRun = 0;
  int _streak = 0;
  List<String> _completedMissions = const [];
  late bool _onboarding = !_storage.onboardingDone;
  int _onboardingStep = 0;
  int _clearEventId = 0;
  List<Cell> _clearedCells = const [];

  static const _onboardingHints = <String>[
    'Zieh einen Stein ins Gitter 👆',
    'Fülle eine ganze Reihe oder Spalte',
    'Volle Linien lösen sich auf — Punkte! ✨',
  ];

  String? get _onboardingHint {
    if (!_onboarding || _isDaily) return null;
    if (_onboardingStep >= _onboardingHints.length) return null;
    return _onboardingHints[_onboardingStep];
  }

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
      coins: storage.coins,
      coinsEarnedThisRun: 0,
      completedMissions: const [],
      isDaily: false,
      streak: storage.streak,
      onboardingHint:
          storage.onboardingDone ? null : 'Zieh einen Stein ins Gitter 👆',
      clearEventId: 0,
      clearedCells: const [],
    );
  }

  /// Starts a fresh endless run.
  void newGame({int? seed}) {
    _session = GameSession.newGame(seed: seed ?? _randomSeed());
    _resetRunState(daily: false);
    _emit();
  }

  /// Starts today's Daily Challenge (same seed for everyone).
  void startDaily({DateTime? now}) {
    _session = GameSession.newGame(seed: DailyChallenge.seedForToday(now: now));
    _resetRunState(daily: true);
    _emit();
  }

  void _resetRunState({required bool daily}) {
    _isNewHighscore = false;
    _isDaily = daily;
    _finalized = false;
    _coinsEarnedThisRun = 0;
    _completedMissions = const [];
    _streak = _storage.streak;
  }

  /// Current mission progress for the missions screen.
  List<MissionView> get missionViews => _missions.views;

  bool canPlace(int slot, Cell origin) => _session.canPlace(slot, origin);

  /// Attempts to place tray[slot] at [origin]. No-op if illegal.
  void place(int slot, Cell origin) {
    final event = _session.place(slot, origin);
    if (event == null) return;

    _haptics.place();
    _audio.play(Sfx.place);
    if (_session.lastClearedCells.isNotEmpty) {
      _clearEventId += 1;
      _clearedCells = _session.lastClearedCells;
    }
    // combo > 0 means this move cleared at least one line (a no-clear move
    // resets combo to 0 in the scorer).
    if (event.combo > 0) {
      if (event.feverBurst) {
        _haptics.feverBurst();
        _audio.play(Sfx.feverBurst);
      } else {
        _haptics.clear();
        _audio.play(event.combo > 1 ? Sfx.combo : Sfx.clear);
      }
    }

    _advanceOnboarding();

    if (_session.isGameOver) {
      _finalizeRun();
    }
    _emit();
  }

  void _advanceOnboarding() {
    if (!_onboarding || _isDaily) return;
    _onboardingStep += 1;
    if (_onboardingStep >= _onboardingHints.length) {
      _onboarding = false;
      _storage.setOnboardingDone(true);
    }
  }

  /// Applies the "Revive" reward: clears the central 4x4 block.
  void revive() {
    _session.reviveClearCenter();
    _emit();
  }

  /// Spends [cost] coins if affordable (e.g. unlocking a theme). Returns
  /// whether the purchase went through, and refreshes the coin display.
  Future<bool> trySpendCoins(int cost) async {
    if (_storage.coins < cost) return false;
    await _storage.addCoins(-cost);
    _emit();
    return true;
  }

  /// Grants earned coins/missions/streak once, at the end of a run.
  void _finalizeRun() {
    _haptics.gameOver();
    _audio.play(Sfx.gameOver);
    if (_finalized) return;
    _finalized = true;
    _finalizeAsync();
  }

  Future<void> _finalizeAsync() async {
    var earned = 0;

    final completed = _missions.recordGame(_session.stats);
    for (final m in completed) {
      earned += m.reward;
    }
    _completedMissions = completed.map((m) => m.description).toList();
    await _storage.setMissionProgress(_missions.progress);

    if (_isDaily) {
      final result = DailyStreak.onDailyCompleted(
        lastDateKey: _storage.lastDailyDate,
        currentStreak: _storage.streak,
        today: DateTime.now(),
      );
      if (!result.alreadyPlayedToday) {
        earned += result.coinsAwarded;
        await _storage.setStreak(result.streak);
        await _storage.setLastDailyDate(
          DailyChallenge.dateKey(DateTime.now()),
        );
      }
      _streak = result.streak;
    }

    if (earned > 0) await _storage.addCoins(earned);
    _coinsEarnedThisRun = earned;
    _isNewHighscore = await _storage.submitScore(_session.score);

    if (mounted) _emit();
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
      coins: _storage.coins,
      coinsEarnedThisRun: _coinsEarnedThisRun,
      completedMissions: _completedMissions,
      isDaily: _isDaily,
      streak: _streak,
      onboardingHint: _onboardingHint,
      clearEventId: _clearEventId,
      clearedCells: _clearedCells,
    );
  }
}
