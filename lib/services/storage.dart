/// Local persistence for GridPop (no backend). Wraps shared_preferences.
///
/// Keys follow MASTERPLAN.md Anhang A.5.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/piggy_bank.dart';
import '../game/stats.dart';

class Storage {
  Storage(this._prefs);

  final SharedPreferences _prefs;

  static const _kHighscore = 'highscore';
  static const _kCoins = 'coins';
  static const _kStreak = 'streak';
  static const _kLastDailyDate = 'lastDailyDate';
  static const _kAdFree = 'adFree';
  static const _kActiveTheme = 'activeTheme';
  static const _kUnlockedThemes = 'unlockedThemes';
  static const _kMissionProgress = 'missionProgress';
  static const _kPuzzleStars = 'puzzleStars';
  static const _kLifetimeStats = 'lifetimeStats';
  static const _kOnboardingDone = 'onboardingDone';
  static const _kSoundEnabled = 'settings.sound';
  static const _kHapticsEnabled = 'settings.haptics';
  static const _kLastStreakRepair = 'lastStreakRepairDate';
  static const _kXp = 'xp';
  static const _kPlayerLevel = 'playerLevel';
  static const _kPiggyCoins = 'piggyCoins';
  static const _kPiggyCapacity = 'piggyCapacity';
  static const _kStarterStart = 'starterOfferStart';
  static const _kStarterPurchased = 'starterPurchased';
  static const _kNotificationsEnabled = 'settings.notifications';
  static const _kLastActiveMillis = 'lastActiveMillis';
  static const _kAppOpenCount = 'appOpenCount';

  static const int startingCoins = 100;

  static Future<Storage> create() async {
    return Storage(await SharedPreferences.getInstance());
  }

  int get highscore => _prefs.getInt(_kHighscore) ?? 0;
  Future<void> setHighscore(int value) => _prefs.setInt(_kHighscore, value);

  /// Records [score] if it beats the stored highscore. Returns true if it was
  /// a new record.
  Future<bool> submitScore(int score) async {
    if (score > highscore) {
      await setHighscore(score);
      return true;
    }
    return false;
  }

  int get coins => _prefs.getInt(_kCoins) ?? startingCoins;
  Future<void> setCoins(int value) => _prefs.setInt(_kCoins, value);

  /// Adds [delta] coins (never drops below zero) and returns the new balance.
  Future<int> addCoins(int delta) async {
    final next = (coins + delta).clamp(0, 1 << 31);
    await setCoins(next);
    return next;
  }

  Map<String, int> get missionProgress {
    final raw = _prefs.getString(_kMissionProgress);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> setMissionProgress(Map<String, int> progress) =>
      _prefs.setString(_kMissionProgress, jsonEncode(progress));

  /// Best stars per puzzle level (level -> stars).
  Map<int, int> get puzzleStars {
    final raw = _prefs.getString(_kPuzzleStars);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
  }

  Future<void> setPuzzleStars(Map<int, int> stars) {
    final encoded = stars.map((k, v) => MapEntry(k.toString(), v));
    return _prefs.setString(_kPuzzleStars, jsonEncode(encoded));
  }

  LifetimeStats get lifetimeStats {
    final raw = _prefs.getString(_kLifetimeStats);
    if (raw == null) return const LifetimeStats();
    return LifetimeStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setLifetimeStats(LifetimeStats stats) =>
      _prefs.setString(_kLifetimeStats, jsonEncode(stats.toJson()));

  int get streak => _prefs.getInt(_kStreak) ?? 0;
  Future<void> setStreak(int value) => _prefs.setInt(_kStreak, value);

  int get playerLevel => _prefs.getInt(_kPlayerLevel) ?? 1;
  Future<void> setPlayerLevel(int value) =>
      _prefs.setInt(_kPlayerLevel, value);

  int get xp => _prefs.getInt(_kXp) ?? 0;
  Future<void> setXp(int value) => _prefs.setInt(_kXp, value);

  PiggyBank get piggyBank => PiggyBank(
        coins: _prefs.getInt(_kPiggyCoins) ?? 0,
        capacity: _prefs.getInt(_kPiggyCapacity) ?? PiggyBank.baseCapacity,
      );

  Future<void> setPiggyBank(PiggyBank piggy) async {
    await _prefs.setInt(_kPiggyCoins, piggy.coins);
    await _prefs.setInt(_kPiggyCapacity, piggy.capacity);
  }

  int? get starterOfferStart => _prefs.getInt(_kStarterStart);
  Future<void> setStarterOfferStart(int millis) =>
      _prefs.setInt(_kStarterStart, millis);

  bool get starterPurchased => _prefs.getBool(_kStarterPurchased) ?? false;
  Future<void> setStarterPurchased(bool value) =>
      _prefs.setBool(_kStarterPurchased, value);

  String? get lastDailyDate => _prefs.getString(_kLastDailyDate);
  Future<void> setLastDailyDate(String key) =>
      _prefs.setString(_kLastDailyDate, key);

  String? get lastStreakRepairDate => _prefs.getString(_kLastStreakRepair);
  Future<void> setLastStreakRepairDate(String key) =>
      _prefs.setString(_kLastStreakRepair, key);

  bool get adFree => _prefs.getBool(_kAdFree) ?? false;
  Future<void> setAdFree(bool value) => _prefs.setBool(_kAdFree, value);

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_kOnboardingDone, value);

  bool get soundEnabled => _prefs.getBool(_kSoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _prefs.setBool(_kSoundEnabled, value);

  bool get hapticsEnabled => _prefs.getBool(_kHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _prefs.setBool(_kHapticsEnabled, value);

  bool get notificationsEnabled =>
      _prefs.getBool(_kNotificationsEnabled) ?? false;
  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_kNotificationsEnabled, value);

  DateTime? get lastActive {
    final ms = _prefs.getInt(_kLastActiveMillis);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastActive(DateTime when) =>
      _prefs.setInt(_kLastActiveMillis, when.millisecondsSinceEpoch);

  int get appOpenCount => _prefs.getInt(_kAppOpenCount) ?? 0;
  Future<void> setAppOpenCount(int value) =>
      _prefs.setInt(_kAppOpenCount, value);

  String get activeTheme => _prefs.getString(_kActiveTheme) ?? 'classic';
  Future<void> setActiveTheme(String id) =>
      _prefs.setString(_kActiveTheme, id);

  /// Theme ids the player owns. 'classic' is always included.
  Set<String> get unlockedThemes {
    final list = _prefs.getStringList(_kUnlockedThemes) ?? const [];
    return {'classic', ...list};
  }

  Future<void> setUnlockedThemes(Set<String> ids) =>
      _prefs.setStringList(_kUnlockedThemes, ids.toList());
}
