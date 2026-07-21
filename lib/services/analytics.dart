/// Analytics abstraction. The Firebase backend is wired once the config files
/// (`google-services.json` / `GoogleService-Info.plist`) are added by the
/// human (see docs/SETUP-ACCOUNTS.md); until then [NoopAnalytics] is used and
/// [DebugAnalytics] prints the funnel so it can be verified locally.
library;

import 'package:flutter/foundation.dart';

/// Canonical event names for the acquisition/retention funnel.
class AnalyticsEvent {
  const AnalyticsEvent._();

  static const gameStart = 'game_start';
  static const roundComplete = 'round_complete';
  static const reachRound3 = 'reach_round_3';
  static const dailyPlayed = 'daily_played';
  static const rewardedWatched = 'rewarded_watched';
  static const purchase = 'purchase';
  static const themeUnlocked = 'theme_unlocked';
}

abstract class Analytics {
  void logEvent(String name, [Map<String, Object?> params]);
}

class NoopAnalytics implements Analytics {
  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {}
}

class DebugAnalytics implements Analytics {
  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    debugPrint('[analytics] $name $params');
  }
}
