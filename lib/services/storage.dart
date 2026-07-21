/// Local persistence for GridPop (no backend). Wraps shared_preferences.
///
/// Keys follow MASTERPLAN.md Anhang A.5.
///
/// ## Local profiles
///
/// Several players can share a device via local profiles. Progress keys
/// (coins, level, highscore, themes, …) are namespaced per profile; the
/// default profile (id 0) uses the legacy unprefixed keys, so pre-profile
/// progress carries over without migration. Device-level state stays global:
/// settings, notifications, and real-money purchase flags (ad-free, starter
/// pack) — purchases belong to the device/store account, not a profile.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/piggy_bank.dart';
import '../game/stats.dart';

/// One local player profile (offline, device-only).
class PlayerProfile {
  const PlayerProfile({required this.id, required this.name});

  final int id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static PlayerProfile fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
      );
}

class Storage {
  Storage(this._prefs);

  final SharedPreferences _prefs;

  // Per-profile keys (namespaced via [_k]).
  static const _kHighscore = 'highscore';
  static const _kCoins = 'coins';
  static const _kStreak = 'streak';
  static const _kLastDailyDate = 'lastDailyDate';
  static const _kActiveTheme = 'activeTheme';
  static const _kUnlockedThemes = 'unlockedThemes';
  static const _kActiveSkin = 'activeSkin';
  static const _kUnlockedSkins = 'unlockedSkins';
  static const _kMissionProgress = 'missionProgress';
  static const _kPuzzleStars = 'puzzleStars';
  static const _kLifetimeStats = 'lifetimeStats';
  static const _kOnboardingDone = 'onboardingDone';
  static const _kLastStreakRepair = 'lastStreakRepairDate';
  static const _kXp = 'xp';
  static const _kPlayerLevel = 'playerLevel';
  static const _kPiggyCoins = 'piggyCoins';
  static const _kPiggyCapacity = 'piggyCapacity';

  /// Every per-profile key, used to wipe a profile on delete.
  static const List<String> _profileKeys = [
    _kHighscore,
    _kCoins,
    _kStreak,
    _kLastDailyDate,
    _kActiveTheme,
    _kUnlockedThemes,
    _kActiveSkin,
    _kUnlockedSkins,
    _kMissionProgress,
    _kPuzzleStars,
    _kLifetimeStats,
    _kOnboardingDone,
    _kLastStreakRepair,
    _kXp,
    _kPlayerLevel,
    _kPiggyCoins,
    _kPiggyCapacity,
  ];

  // Device-global keys.
  static const _kAdFree = 'adFree';
  static const _kSoundEnabled = 'settings.sound';
  static const _kHapticsEnabled = 'settings.haptics';
  static const _kMusicEnabled = 'settings.music';
  static const _kNotificationsEnabled = 'settings.notifications';
  static const _kStarterStart = 'starterOfferStart';
  static const _kStarterPurchased = 'starterPurchased';
  static const _kLastActiveMillis = 'lastActiveMillis';
  static const _kAppOpenCount = 'appOpenCount';
  static const _kProfiles = 'profiles';
  static const _kActiveProfile = 'activeProfile';

  static const int startingCoins = 100;
  static const String defaultProfileName = 'Spieler 1';

  static Future<Storage> create() async {
    return Storage(await SharedPreferences.getInstance());
  }

  // ---------------------------------------------------------------------------
  // Profiles

  List<PlayerProfile> get profiles {
    final raw = _prefs.getString(_kProfiles);
    if (raw == null) {
      return const [PlayerProfile(id: 0, name: defaultProfileName)];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in decoded)
        PlayerProfile.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<void> _saveProfiles(List<PlayerProfile> list) => _prefs.setString(
        _kProfiles,
        jsonEncode([for (final p in list) p.toJson()]),
      );

  int get activeProfileId => _prefs.getInt(_kActiveProfile) ?? 0;

  PlayerProfile get activeProfile => profiles.firstWhere(
        (p) => p.id == activeProfileId,
        orElse: () => profiles.first,
      );

  Future<void> setActiveProfile(int id) =>
      _prefs.setInt(_kActiveProfile, id);

  /// Creates a profile with a fresh id and returns it.
  Future<PlayerProfile> addProfile(String name) async {
    final list = profiles;
    final nextId =
        list.map((p) => p.id).fold(0, (a, b) => a > b ? a : b) + 1;
    final profile = PlayerProfile(id: nextId, name: name);
    await _saveProfiles([...list, profile]);
    return profile;
  }

  Future<void> renameProfile(int id, String name) async {
    await _saveProfiles([
      for (final p in profiles)
        p.id == id ? PlayerProfile(id: id, name: name) : p,
    ]);
  }

  /// Deletes a profile and wipes its stored progress. The last remaining
  /// profile cannot be deleted; deleting the active one switches to the first
  /// remaining profile.
  Future<bool> deleteProfile(int id) async {
    final list = profiles;
    if (list.length <= 1) return false;
    final remaining = [
      for (final p in list)
        if (p.id != id) p,
    ];
    if (remaining.length == list.length) return false;

    for (final key in _profileKeys) {
      await _prefs.remove(_keyFor(id, key));
    }
    await _saveProfiles(remaining);
    if (activeProfileId == id) {
      await setActiveProfile(remaining.first.id);
    }
    return true;
  }

  /// Namespaces [key] for [profileId]. Profile 0 keeps the legacy unprefixed
  /// keys so existing progress survives the introduction of profiles.
  static String _keyFor(int profileId, String key) =>
      profileId == 0 ? key : 'p$profileId.$key';

  String _k(String key) => _keyFor(activeProfileId, key);

  // ---------------------------------------------------------------------------
  // Per-profile progress

  int get highscore => _prefs.getInt(_k(_kHighscore)) ?? 0;
  Future<void> setHighscore(int value) =>
      _prefs.setInt(_k(_kHighscore), value);

  /// Records [score] if it beats the stored highscore. Returns true if it was
  /// a new record.
  Future<bool> submitScore(int score) async {
    if (score > highscore) {
      await setHighscore(score);
      return true;
    }
    return false;
  }

  int get coins => _prefs.getInt(_k(_kCoins)) ?? startingCoins;
  Future<void> setCoins(int value) => _prefs.setInt(_k(_kCoins), value);

  /// Adds [delta] coins (never drops below zero) and returns the new balance.
  Future<int> addCoins(int delta) async {
    final next = (coins + delta).clamp(0, 1 << 31);
    await setCoins(next);
    return next;
  }

  Map<String, int> get missionProgress {
    final raw = _prefs.getString(_k(_kMissionProgress));
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> setMissionProgress(Map<String, int> progress) =>
      _prefs.setString(_k(_kMissionProgress), jsonEncode(progress));

  /// Best stars per puzzle level (level -> stars).
  Map<int, int> get puzzleStars {
    final raw = _prefs.getString(_k(_kPuzzleStars));
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
  }

  Future<void> setPuzzleStars(Map<int, int> stars) {
    final encoded = stars.map((k, v) => MapEntry(k.toString(), v));
    return _prefs.setString(_k(_kPuzzleStars), jsonEncode(encoded));
  }

  LifetimeStats get lifetimeStats {
    final raw = _prefs.getString(_k(_kLifetimeStats));
    if (raw == null) return const LifetimeStats();
    return LifetimeStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setLifetimeStats(LifetimeStats stats) =>
      _prefs.setString(_k(_kLifetimeStats), jsonEncode(stats.toJson()));

  int get streak => _prefs.getInt(_k(_kStreak)) ?? 0;
  Future<void> setStreak(int value) => _prefs.setInt(_k(_kStreak), value);

  int get playerLevel => _prefs.getInt(_k(_kPlayerLevel)) ?? 1;
  Future<void> setPlayerLevel(int value) =>
      _prefs.setInt(_k(_kPlayerLevel), value);

  int get xp => _prefs.getInt(_k(_kXp)) ?? 0;
  Future<void> setXp(int value) => _prefs.setInt(_k(_kXp), value);

  PiggyBank get piggyBank => PiggyBank(
        coins: _prefs.getInt(_k(_kPiggyCoins)) ?? 0,
        capacity:
            _prefs.getInt(_k(_kPiggyCapacity)) ?? PiggyBank.baseCapacity,
      );

  Future<void> setPiggyBank(PiggyBank piggy) async {
    await _prefs.setInt(_k(_kPiggyCoins), piggy.coins);
    await _prefs.setInt(_k(_kPiggyCapacity), piggy.capacity);
  }

  String? get lastDailyDate => _prefs.getString(_k(_kLastDailyDate));
  Future<void> setLastDailyDate(String key) =>
      _prefs.setString(_k(_kLastDailyDate), key);

  String? get lastStreakRepairDate =>
      _prefs.getString(_k(_kLastStreakRepair));
  Future<void> setLastStreakRepairDate(String key) =>
      _prefs.setString(_k(_kLastStreakRepair), key);

  bool get onboardingDone => _prefs.getBool(_k(_kOnboardingDone)) ?? false;
  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_k(_kOnboardingDone), value);

  String get activeTheme => _prefs.getString(_k(_kActiveTheme)) ?? 'classic';
  Future<void> setActiveTheme(String id) =>
      _prefs.setString(_k(_kActiveTheme), id);

  /// Theme ids the player owns. 'classic' is always included.
  Set<String> get unlockedThemes {
    final list = _prefs.getStringList(_k(_kUnlockedThemes)) ?? const [];
    return {'classic', ...list};
  }

  Future<void> setUnlockedThemes(Set<String> ids) =>
      _prefs.setStringList(_k(_kUnlockedThemes), ids.toList());

  String get activeSkin => _prefs.getString(_k(_kActiveSkin)) ?? 'classic';
  Future<void> setActiveSkin(String id) =>
      _prefs.setString(_k(_kActiveSkin), id);

  Set<String> get unlockedSkins {
    final list = _prefs.getStringList(_k(_kUnlockedSkins)) ?? const [];
    return {'classic', ...list};
  }

  Future<void> setUnlockedSkins(Set<String> ids) =>
      _prefs.setStringList(_k(_kUnlockedSkins), ids.toList());

  // ---------------------------------------------------------------------------
  // Device-global state (settings, purchases, notification bookkeeping)

  bool get adFree => _prefs.getBool(_kAdFree) ?? false;
  Future<void> setAdFree(bool value) => _prefs.setBool(_kAdFree, value);

  int? get starterOfferStart => _prefs.getInt(_kStarterStart);
  Future<void> setStarterOfferStart(int millis) =>
      _prefs.setInt(_kStarterStart, millis);

  bool get starterPurchased => _prefs.getBool(_kStarterPurchased) ?? false;
  Future<void> setStarterPurchased(bool value) =>
      _prefs.setBool(_kStarterPurchased, value);

  bool get soundEnabled => _prefs.getBool(_kSoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _prefs.setBool(_kSoundEnabled, value);

  bool get hapticsEnabled => _prefs.getBool(_kHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _prefs.setBool(_kHapticsEnabled, value);

  bool get musicEnabled => _prefs.getBool(_kMusicEnabled) ?? true;
  Future<void> setMusicEnabled(bool value) =>
      _prefs.setBool(_kMusicEnabled, value);

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
}
