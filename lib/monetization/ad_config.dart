/// Centralized AdMob unit IDs.
///
/// CLAUDE.md rule: debug builds must use Google's official TEST ad unit IDs
/// only. Release builds use the real IDs — fill in the `REPLACE_ME_*`
/// placeholders once the AdMob units exist (see docs/SETUP-ACCOUNTS.md).
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AdConfig {
  const AdConfig._();

  // --- Google's official sample/test unit IDs (safe to ship in debug) -------
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  // --- Real production unit IDs ---------------------------------------------
  // Rewarded is the ONLY ad format in Qubble (no interstitials, no banners).
  // Android id set 2026-07 (AdMob app "Qubble"); iOS follows with the
  // App-Store phase.
  static const _prodRewardedAndroid = 'ca-app-pub-8596176219181991/4303264559';
  static const _prodRewardedIos = 'REPLACE_ME_REWARDED_IOS';

  static bool get _isAndroid => Platform.isAndroid;

  static String get rewardedUnitId {
    if (kDebugMode) {
      return _isAndroid ? _testRewardedAndroid : _testRewardedIos;
    }
    return _isAndroid ? _prodRewardedAndroid : _prodRewardedIos;
  }
}
