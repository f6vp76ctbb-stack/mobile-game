/// Riverpod bridge between the pure-Dart [GameSession] and the widgets.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/achievements.dart';
import '../../game/board.dart';
import '../../game/daily.dart';
import '../../game/game_session.dart';
import '../../game/leveling.dart';
import '../../game/missions.dart';
import '../../game/piece.dart';
import '../../game/starter_offer.dart';
import '../../game/streak.dart';
import '../../game/weekend_event.dart';
import '../../monetization/ads.dart';
import '../../monetization/iap.dart';
import '../../services/analytics.dart';
import '../../services/audio.dart';
import '../../services/haptics.dart';
import '../../services/leaderboard.dart';
import '../../services/storage.dart';
import 'skin_controller.dart';
import 'theme_controller.dart';

/// Provided once at startup (overridden in main after async init).
final storageProvider = Provider<Storage>(
  (ref) => throw UnimplementedError('storageProvider must be overridden'),
);

final hapticsProvider = Provider<Haptics>((ref) => Haptics());
final audioProvider = Provider<AudioService>((ref) => SilentAudio());

/// Background music — silent by default (tests/dev); main overrides it with
/// the audioplayers-backed loop.
final musicProvider = Provider<MusicService>((ref) => SilentMusic());
final analyticsProvider = Provider<Analytics>((ref) => NoopAnalytics());

/// Ad service — [FakeAdService] by default (tests/dev); main overrides it with
/// the real AdMob-backed one.
final adServiceProvider = Provider<AdService>((ref) => FakeAdService());

/// IAP service — [FakeIap] by default (tests/dev); main overrides with the real
/// store-backed one.
final iapServiceProvider = Provider<IapService>((ref) => FakeIap());

/// Shared leaderboard (Firestore REST; storage persists the silent anonymous
/// identity used for submitting).
final leaderboardServiceProvider = Provider<LeaderboardService>(
  (ref) => LeaderboardService(storage: ref.read(storageProvider)),
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
    required this.coins,
    required this.coinsEarnedThisRun,
    required this.completedMissions,
    required this.isDaily,
    required this.streak,
    required this.onboardingHint,
    required this.clearEventId,
    required this.clearedCells,
    required this.supporter,
    required this.reviveUsed,
    required this.canUndo,
    required this.coinsDoubled,
    required this.streakRepairAvailable,
    required this.lastGained,
    required this.lastClearedLineCount,
    required this.lastWasAllClear,
    required this.playerLevel,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.levelsGainedThisRun,
    required this.levelUpCoins,
    required this.weekendActive,
    required this.piggyCoins,
    required this.piggyCapacity,
    required this.starterOfferActive,
    required this.starterHoursLeft,
    required this.comboEndsAt,
    required this.rotationCharges,
    required this.rotationFree,
    required this.runActive,
    required this.playerName,
    required this.lastSubmittedScore,
    required this.rewardsUnlockedThisRun,
    required this.achievementsUnlockedThisRun,
    required this.lastCoinGain,
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

  /// True once the player owns the supporter pack (heart badge, exclusives).
  final bool supporter;

  /// Whether this run's one revive (coin-paid) was already used.
  final bool reviveUsed;

  /// Whether the last placement can still be undone (booster availability).
  final bool canUndo;

  /// Whether this run's earned coins were already doubled via rewarded ad.
  final bool coinsDoubled;

  /// Whether a streak repair is currently on offer (one day missed).
  final bool streakRepairAvailable;

  /// Points gained on the most recent clearing move (for the score popup).
  final int lastGained;

  /// Lines cleared on the most recent move (screen-shake at 3+).
  final int lastClearedLineCount;

  /// Whether the most recent move emptied the board (confetti + banner).
  final bool lastWasAllClear;

  /// Player level and progress toward the next level (for the home badge).
  final int playerLevel;
  final int xpIntoLevel;
  final int xpForNextLevel;

  /// Levels gained + coins from level-ups this run (game-over celebration).
  final int levelsGainedThisRun;
  final int levelUpCoins;

  /// Whether the weekend double-coins event is currently active.
  final bool weekendActive;

  /// Piggy bank state (fills while playing; free payout when full, optional
  /// early open via rewarded video).
  final int piggyCoins;
  final int piggyCapacity;

  /// One-time starter pack offer (active during its 48h window).
  final bool starterOfferActive;
  final int starterHoursLeft;

  /// When the running combo expires (drives the countdown UI); null while no
  /// combo is active.
  final DateTime? comboEndsAt;

  /// Remaining piece-rotation charges (refilled by clearing lines).
  final int rotationCharges;

  /// True while rotation is free (beginner mode, player level <= 2).
  final bool rotationFree;

  /// True while a run is in progress (pieces placed, not yet game over) — the
  /// home screen shows "Weiterspielen" instead of restarting.
  final bool runActive;

  /// The player's display name (leaderboard identity). Empty until entered.
  final String playerName;

  /// Highest score already submitted to the shared leaderboard (so the UI
  /// only offers to submit a genuine new best).
  final int lastSubmittedScore;

  /// Cosmetics (themes/skins) unlocked by level-ups during this run — shown in
  /// the game-over celebration.
  final List<LevelReward> rewardsUnlockedThisRun;

  /// Achievements newly unlocked by this run (game-over celebration).
  final List<Achievement> achievementsUnlockedThisRun;

  /// Coins earned by the most recent clearing move (drives the "+N 🪙" popup);
  /// 0 on moves that cleared nothing.
  final int lastCoinGain;
}

/// In-run booster prices (MASTERPLAN.md Anhang C.1 / A.3).
class BoosterCosts {
  const BoosterCosts._();
  static const int undo = 50;
  static const int swap = 75;
  static const int bomb = 150;

  /// Revive after game over (clears the board centre). Coins only — ads are
  /// never required to keep playing.
  static const int revive = 200;
}

/// Coins earned per cleared line during play (live reward, shown as a popup).
const int kCoinsPerLine = 3;

/// Bonus coins for emptying the whole board (All Clear).
const int kAllClearCoins = 25;

final gameControllerProvider =
    StateNotifierProvider<GameController, GameSnapshot>((ref) {
  return GameController(
    ref.read(storageProvider),
    ref.read(hapticsProvider),
    ref.read(audioProvider),
    ref.read(adServiceProvider),
    ref.read(analyticsProvider),
    onCosmeticsGranted: () {
      // Level-up unlocks changed the owned themes/skins — rebuild the caches.
      ref.invalidate(themeControllerProvider);
      ref.invalidate(skinControllerProvider);
    },
  );
});

class GameController extends StateNotifier<GameSnapshot> {
  GameController(
    this._storage,
    this._haptics,
    this._audio,
    this._ads,
    this._analytics, {
    int? seed,
    this.onCosmeticsGranted,
  })  : _missions = MissionEngine(progress: _storage.missionProgress),
        _session = GameSession.newGame(
          seed: seed ?? _randomSeed(),
          freeRotation: _storage.playerLevel <= 2,
        ),
        super(_initialSnapshot(_storage)) {
    _emit();
  }

  /// Invoked after a run unlocks themes/skins via level-up, so the UI caches
  /// (theme/skin controllers) can refresh. Null in tests.
  final void Function()? onCosmeticsGranted;

  /// Rotation is free while the player is still learning (level <= 2) — in
  /// endless mode only; the Daily Challenge is competitive, so everyone plays
  /// with the same charge rules there.
  bool get _freeRotationForEndless => _storage.playerLevel <= 2;

  final Storage _storage;
  final Haptics _haptics;
  final AudioService _audio;
  final AdService _ads;
  final Analytics _analytics;
  final MissionEngine _missions;

  GameSession _session;
  bool _isNewHighscore = false;
  bool _isDaily = false;
  bool _finalized = false;
  int _coinsEarnedThisRun = 0;
  bool _coinsDoubled = false;
  bool _reviveUsed = false;
  int _roundsThisLaunch = 0;
  int _streak = 0;
  int _levelsGainedThisRun = 0;
  int _levelUpCoins = 0;
  int _playCoinsThisRun = 0;
  int _lastCoinGain = 0;
  List<LevelReward> _rewardsThisRun = const [];
  List<Achievement> _achievementsThisRun = const [];
  List<String> _completedMissions = const [];
  late bool _onboarding = !_storage.onboardingDone;
  int _onboardingStep = 0;
  int _clearEventId = 0;
  List<Cell> _clearedCells = const [];
  int _lastGained = 0;

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
      supporter: storage.supporter,
      reviveUsed: false,
      canUndo: false,
      coinsDoubled: false,
      streakRepairAvailable: StreakRepair.isRepairable(
        lastDateKey: storage.lastDailyDate,
        currentStreak: storage.streak,
        today: DateTime.now(),
        lastRepairDateKey: storage.lastStreakRepairDate,
      ),
      lastGained: 0,
      lastClearedLineCount: 0,
      lastWasAllClear: false,
      playerLevel: storage.playerLevel,
      xpIntoLevel: storage.xp,
      xpForNextLevel: LevelSystem.xpForNext(storage.playerLevel),
      levelsGainedThisRun: 0,
      levelUpCoins: 0,
      weekendActive: WeekendEvent.isActive(DateTime.now()),
      piggyCoins: storage.piggyBank.coins,
      piggyCapacity: storage.piggyBank.capacity,
      starterOfferActive: StarterOffer.isActive(
        startMillis: storage.starterOfferStart,
        purchased: storage.starterPurchased,
        now: DateTime.now(),
      ),
      starterHoursLeft: 0,
      comboEndsAt: null,
      rotationCharges: GameSession.startRotationCharges,
      rotationFree: storage.playerLevel <= 2,
      runActive: false,
      playerName: storage.playerName,
      lastSubmittedScore: storage.lastSubmittedScore,
      rewardsUnlockedThisRun: const [],
      achievementsUnlockedThisRun: const [],
      lastCoinGain: 0,
    );
  }

  /// Starts a fresh endless run.
  void newGame({int? seed}) {
    _session = GameSession.newGame(
      seed: seed ?? _randomSeed(),
      freeRotation: _freeRotationForEndless,
    );
    _resetRunState(daily: false);
    _analytics.logEvent(AnalyticsEvent.gameStart, {'mode': 'endless'});
    _emit();
  }

  /// Starts today's Daily Challenge (same seed for everyone).
  void startDaily({DateTime? now}) {
    _session = GameSession.newGame(seed: DailyChallenge.seedForToday(now: now));
    _resetRunState(daily: true);
    _analytics.logEvent(AnalyticsEvent.gameStart, {'mode': 'daily'});
    _emit();
  }


  /// Revive after game over: pays [BoosterCosts.revive] coins to clear the
  /// board centre and keep the run going. Once per run; ads are never part of
  /// this — playing must never require watching a video.
  Future<bool> reviveWithCoins() async {
    if (_reviveUsed || _storage.coins < BoosterCosts.revive) return false;
    await _storage.addCoins(-BoosterCosts.revive);
    _reviveUsed = true;
    _session.reviveClearCenter();
    _emit();
    return true;
  }

  /// Doubles this run's earned coins by watching a rewarded ad. Once only.
  Future<bool> doubleCoinsWithAd() async {
    if (_coinsDoubled || _coinsEarnedThisRun <= 0) return false;
    final earned = await _ads.showRewarded();
    _analytics
        .logEvent(AnalyticsEvent.rewardedWatched, {'placement': 'double'});
    if (earned) {
      final bonus = _coinsEarnedThisRun;
      await _storage.addCoins(bonus);
      _coinsEarnedThisRun += bonus;
      _coinsDoubled = true;
      _emit();
    }
    return earned;
  }

  /// "Lucky Block" reward: watch a rewarded ad for a fresh set of pieces.
  Future<bool> luckyBlock() async {
    final earned = await _ads.showRewarded();
    _analytics.logEvent(AnalyticsEvent.rewardedWatched, {'placement': 'lucky'});
    if (earned) {
      _session.rerollTray();
      _emit();
    }
    return earned;
  }

  /// Sets the player's display name (leaderboard identity) and refreshes.
  Future<void> setPlayerName(String name) async {
    await _storage.setPlayerName(name);
    _emit();
  }

  /// Records that [score] was submitted to the shared leaderboard, so the UI
  /// stops offering to submit it again.
  Future<void> markScoreSubmitted(int score) async {
    if (score > _storage.lastSubmittedScore) {
      await _storage.setLastSubmittedScore(score);
      _emit();
    }
  }

  /// Adds coins (e.g. from a consumable IAP) and refreshes the display.
  Future<void> grantCoins(int amount) async {
    if (amount <= 0) return;
    await _storage.addCoins(amount);
    _emit();
  }

  /// Awards live coins during a run (fire-and-forget persist). The shared_prefs
  /// in-memory cache updates synchronously, so [_emit] shows the new balance
  /// right away; the disk write completes in the background.
  void _grantPlayCoins(int amount) {
    if (amount <= 0) return;
    _playCoinsThisRun += amount;
    _lastCoinGain = amount;
    unawaited(_storage.addCoins(amount));
  }

  /// Sets the coin balance directly — only reachable from the hidden admin
  /// (test) section in the settings. Hard no-op in release builds: players
  /// must never get coin cheats, even if a UI guard ever slips.
  Future<void> setCoinsForTest(int value) async {
    if (kReleaseMode) return;
    await _storage.setCoins(value.clamp(0, 1 << 31));
    _emit();
  }

  bool get _starterActive => StarterOffer.isActive(
        startMillis: _storage.starterOfferStart,
        purchased: _storage.starterPurchased,
        now: DateTime.now(),
      );

  int get _starterHoursLeft {
    final start = _storage.starterOfferStart;
    if (start == null || !_starterActive) return 0;
    return StarterOffer.remaining(startMillis: start, now: DateTime.now())
        .inHours;
  }

  /// Marks the starter pack as purchased (coins + theme are delivered
  /// separately by the purchase handler) and refreshes.
  Future<void> markStarterPurchased() async {
    await _storage.setStarterPurchased(true);
    _emit();
  }

  /// Empties the piggy bank into the coin balance and raises its capacity.
  /// Free when the bank is full (tap to collect). Returns the payout.
  Future<int> openPiggy() async {
    final piggy = _storage.piggyBank;
    final payout = piggy.coins;
    if (payout > 0) await _storage.addCoins(payout);
    await _storage.setPiggyBank(piggy.opened());
    _emit();
    return payout;
  }

  /// Opens a not-yet-full piggy bank early by watching a rewarded video.
  /// Returns the payout, or null if the reward was not earned.
  Future<int?> openPiggyWithAd() async {
    final earned = await _ads.showRewarded();
    _analytics.logEvent(AnalyticsEvent.rewardedWatched, {'placement': 'piggy'});
    if (!earned) return null;
    return openPiggy();
  }

  /// Marks the supporter pack owned (heart badge; the coins/theme/skin are
  /// delivered separately by the purchase handler) and refreshes.
  Future<void> applySupporter() async {
    await _storage.setSupporter(true);
    _emit();
  }

  void _resetRunState({required bool daily}) {
    _isNewHighscore = false;
    _isDaily = daily;
    _finalized = false;
    _coinsEarnedThisRun = 0;
    _coinsDoubled = false;
    _reviveUsed = false;
    _levelsGainedThisRun = 0;
    _levelUpCoins = 0;
    _playCoinsThisRun = 0;
    _lastCoinGain = 0;
    _rewardsThisRun = const [];
    _achievementsThisRun = const [];
    _completedMissions = const [];
    _streak = _storage.streak;
  }

  /// Current mission progress for the missions screen.
  List<MissionView> get missionViews => _missions.views;

  bool canPlace(int slot, Cell origin) => _session.canPlace(slot, origin);

  /// Rotates the tray piece in [slot] 90° clockwise (tap-to-rotate). Free in
  /// beginner mode, otherwise consumes a rotation charge. Returns whether it
  /// ran (false = no charges left).
  bool rotateTray(int slot) {
    final ok = _session.rotate(slot);
    if (ok) {
      _haptics.place();
      _audio.play(Sfx.place, pitch: 1.3);
      _emit();
    }
    return ok;
  }

  /// Attempts to place tray[slot] at [origin]. No-op if illegal.
  void place(int slot, Cell origin) {
    final event = _session.place(slot, origin);
    if (event == null) return;

    _haptics.place();
    _audio.play(Sfx.place);
    _lastGained = event.gained;
    _lastCoinGain = 0;
    if (_session.lastClearedCells.isNotEmpty) {
      _clearEventId += 1;
      _clearedCells = _session.lastClearedCells;
      // Live coin reward for clears — instant, visible feedback while playing.
      final lines = _session.lastClearedLineCount;
      var coinGain = lines * kCoinsPerLine;
      if (event.combo > 1) coinGain += event.combo; // combo bonus
      if (_session.lastWasAllClear) coinGain += kAllClearCoins;
      _grantPlayCoins(coinGain);
    }
    // The combo now survives non-clearing moves (time-based), so gate the
    // clear feedback on this move actually having cleared lines.
    if (_session.lastClearedLineCount > 0) {
      if (event.feverBurst) {
        _haptics.feverBurst();
        _audio.play(Sfx.feverBurst);
      } else {
        _haptics.clear();
        // Combo sound escalates in pitch with the combo count (C.8).
        final pitch = (1.0 + (event.combo - 1) * 0.06).clamp(1.0, 1.6);
        _audio.play(event.combo > 1 ? Sfx.combo : Sfx.clear, pitch: pitch);
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

  /// Spends [cost] coins if affordable (e.g. unlocking a theme). Returns
  /// whether the purchase went through, and refreshes the coin display.
  Future<bool> trySpendCoins(int cost) async {
    if (_storage.coins < cost) return false;
    await _storage.addCoins(-cost);
    _emit();
    return true;
  }

  /// Undo booster: reverts the last placement for [BoosterCosts.undo] coins.
  Future<bool> tryUndo() async {
    if (!_session.canUndo || _storage.coins < BoosterCosts.undo) return false;
    await _storage.addCoins(-BoosterCosts.undo);
    _session.undo();
    _emit();
    return true;
  }

  /// Swap booster: redraws the tray for [BoosterCosts.swap] coins.
  Future<bool> trySwapPieces() async {
    if (_session.isGameOver || _storage.coins < BoosterCosts.swap) return false;
    await _storage.addCoins(-BoosterCosts.swap);
    _session.rerollTray();
    _emit();
    return true;
  }

  /// Bomb booster: clears the 3x3 block around [origin] for
  /// [BoosterCosts.bomb] coins.
  Future<bool> tryBomb(Cell origin) async {
    if (_session.isGameOver || _storage.coins < BoosterCosts.bomb) return false;
    await _storage.addCoins(-BoosterCosts.bomb);
    final hit = _session.bombAt(origin);
    // Feed the hit cells into the clear-burst pipeline so the bomb visibly
    // detonates (particles + sound) even when it only cleared a few blocks.
    _clearEventId += 1;
    _clearedCells = hit;
    _haptics.clear();
    _audio.play(Sfx.clear, pitch: 0.8);
    _emit();
    return true;
  }

  /// Grants earned coins/missions/streak once, at the end of a run.
  void _finalizeRun() {
    _haptics.gameOver();
    _audio.play(Sfx.gameOver);
    if (_finalized) return;
    _finalized = true;

    _roundsThisLaunch += 1;
    _analytics.logEvent(AnalyticsEvent.roundComplete, {
      'score': _session.score,
      'mode': _isDaily ? 'daily' : 'endless',
    });
    if (_roundsThisLaunch == 3) {
      _analytics.logEvent(AnalyticsEvent.reachRound3);
    }
    if (_isDaily) _analytics.logEvent(AnalyticsEvent.dailyPlayed);

    _finalizeAsync();
  }

  Future<void> _finalizeAsync() async {
    final now = DateTime.now();

    await _storage.setLifetimeStats(
      _storage.lifetimeStats.merge(_session.stats),
    );

    // Piggy bank fills with the run's cleared lines (C.5).
    await _storage.setPiggyBank(
      _storage.piggyBank.addLines(_session.linesCleared),
    );

    // Start the one-time starter offer after the 5th run (C.6).
    if (StarterOffer.shouldStart(
      gamesPlayed: _storage.lifetimeStats.games,
      startMillis: _storage.starterOfferStart,
      purchased: _storage.starterPurchased,
    )) {
      await _storage.setStarterOfferStart(now.millisecondsSinceEpoch);
    }

    // Mission + daily rewards are doubled during the weekend event (C.7);
    // level-up coins are not.
    var rewardCoins = 0;

    final completed = _missions.recordGame(_session.stats);
    for (final m in completed) {
      rewardCoins += m.reward;
    }
    _completedMissions = completed.map((m) => m.description).toList();
    await _storage.setMissionProgress(_missions.progress);

    var dailyCompleted = false;
    if (_isDaily) {
      final result = DailyStreak.onDailyCompleted(
        lastDateKey: _storage.lastDailyDate,
        currentStreak: _storage.streak,
        today: now,
      );
      if (!result.alreadyPlayedToday) {
        dailyCompleted = true;
        rewardCoins += result.coinsAwarded;
        await _storage.setStreak(result.streak);
        await _storage.setLastDailyDate(DailyChallenge.dateKey(now));
      }
      _streak = result.streak;
    }

    var earned = WeekendEvent.apply(rewardCoins, now);

    // Player XP + level-ups (C.3).
    final gainedXp = LevelSystem.xpForRun(
      score: _session.score,
      dailyCompleted: dailyCompleted,
    );
    final outcome = LevelSystem.applyXp(
      level: _storage.playerLevel,
      xpIntoLevel: _storage.xp,
      gainedXp: gainedXp,
    );
    await _storage.setPlayerLevel(outcome.level);
    await _storage.setXp(outcome.xpIntoLevel);
    earned += outcome.coinsAwarded;
    _levelsGainedThisRun = outcome.levelsGained.length;
    _levelUpCoins = outcome.coinsAwarded;

    // Level-up chime + haptic pulse to reinforce the celebration.
    if (outcome.leveledUp) {
      _audio.play(Sfx.levelUp);
      _haptics.feverBurst();
    }

    // Grant the cosmetics the level-ups unlocked (only those not yet owned).
    final unlocked = <LevelReward>[];
    for (final reward in outcome.rewards) {
      final isNew = reward.kind == LevelRewardKind.theme
          ? await _storage.addUnlockedTheme(reward.id)
          : await _storage.addUnlockedSkin(reward.id);
      if (isNew) unlocked.add(reward);
    }
    _rewardsThisRun = unlocked;
    if (unlocked.isNotEmpty) onCosmeticsGranted?.call();

    if (earned > 0) await _storage.addCoins(earned);
    // Total for the run = end-of-run bonuses + coins earned live during play
    // (the play coins were already added to the balance as they were earned).
    _coinsEarnedThisRun = earned + _playCoinsThisRun;
    _isNewHighscore = await _storage.submitScore(_session.score);

    // Achievements: evaluate against the now-updated aggregates.
    final life = _storage.lifetimeStats;
    final progress = AchievementProgress(
      games: life.games,
      highscore: _storage.highscore,
      totalLines: life.totalLines,
      bestCombo: life.bestCombo,
      level: _storage.playerLevel,
      streak: _storage.streak,
      puzzlesSolved: _storage.puzzleStars.length,
      totalPieces: life.totalPieces,
    );
    final already = _storage.unlockedAchievements;
    final fresh = Achievements.newlyUnlocked(progress, already);
    if (fresh.isNotEmpty) {
      await _storage.setUnlockedAchievements(
        {...already, for (final a in fresh) a.id},
      );
      _achievementsThisRun = fresh;
      _audio.play(Sfx.levelUp, pitch: 1.25);
    }

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
      supporter: _storage.supporter,
      reviveUsed: _reviveUsed,
      canUndo: _session.canUndo,
      coinsDoubled: _coinsDoubled,
      streakRepairAvailable: _streakRepairAvailable(),
      lastGained: _lastGained,
      lastClearedLineCount: _session.lastClearedLineCount,
      lastWasAllClear: _session.lastWasAllClear,
      playerLevel: _storage.playerLevel,
      xpIntoLevel: _storage.xp,
      xpForNextLevel: LevelSystem.xpForNext(_storage.playerLevel),
      levelsGainedThisRun: _levelsGainedThisRun,
      levelUpCoins: _levelUpCoins,
      weekendActive: WeekendEvent.isActive(DateTime.now()),
      piggyCoins: _storage.piggyBank.coins,
      piggyCapacity: _storage.piggyBank.capacity,
      starterOfferActive: _starterActive,
      starterHoursLeft: _starterHoursLeft,
      comboEndsAt: _session.comboExpiresAt,
      rotationCharges: _session.rotationCharges,
      rotationFree: _session.freeRotation,
      runActive: _session.placements > 0 && !_session.isGameOver,
      playerName: _storage.playerName,
      lastSubmittedScore: _storage.lastSubmittedScore,
      rewardsUnlockedThisRun: _rewardsThisRun,
      achievementsUnlockedThisRun: _achievementsThisRun,
      lastCoinGain: _lastCoinGain,
    );
  }

  bool _streakRepairAvailable() => StreakRepair.isRepairable(
        lastDateKey: _storage.lastDailyDate,
        currentStreak: _storage.streak,
        today: DateTime.now(),
        lastRepairDateKey: _storage.lastStreakRepairDate,
      );

  Future<void> _applyStreakRepair() async {
    final now = DateTime.now();
    await _storage.setLastDailyDate(StreakRepair.repairedLastDateKey(now));
    await _storage.setLastStreakRepairDate(DailyChallenge.dateKey(now));
    _streak = _storage.streak;
    _analytics.logEvent(AnalyticsEvent.dailyPlayed, {'action': 'streak_repair'});
    _emit();
  }

  /// Repairs a broken streak for [StreakRepair.coinCost] coins.
  Future<bool> repairStreakWithCoins() async {
    if (!_streakRepairAvailable()) return false;
    if (_storage.coins < StreakRepair.coinCost) return false;
    await _storage.addCoins(-StreakRepair.coinCost);
    await _applyStreakRepair();
    return true;
  }

  /// Repairs a broken streak by watching a rewarded ad.
  Future<bool> repairStreakWithAd() async {
    if (!_streakRepairAvailable()) return false;
    final earned = await _ads.showRewarded();
    _analytics.logEvent(
      AnalyticsEvent.rewardedWatched,
      {'placement': 'streak_repair'},
    );
    if (earned) await _applyStreakRepair();
    return earned;
  }
}
