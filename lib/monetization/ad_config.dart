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
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  // --- Real production unit IDs (fill in before release) --------------------
  static const _prodInterstitialAndroid = 'REPLACE_ME_INTERSTITIAL_ANDROID';
  static const _prodInterstitialIos = 'REPLACE_ME_INTERSTITIAL_IOS';
  static const _prodRewardedAndroid = 'REPLACE_ME_REWARDED_ANDROID';
  static const _prodRewardedIos = 'REPLACE_ME_REWARDED_IOS';

  static bool get _isAndroid => Platform.isAndroid;

  static String get interstitialUnitId {
    if (kDebugMode) {
      return _isAndroid ? _testInterstitialAndroid : _testInterstitialIos;
    }
    return _isAndroid ? _prodInterstitialAndroid : _prodInterstitialIos;
  }

  static String get rewardedUnitId {
    if (kDebugMode) {
      return _isAndroid ? _testRewardedAndroid : _testRewardedIos;
    }
    return _isAndroid ? _prodRewardedAndroid : _prodRewardedIos;
  }
}
