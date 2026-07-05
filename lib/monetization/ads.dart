/// Ad service abstraction over `google_mobile_ads`.
///
/// [FakeAdService] keeps tests and headless contexts ad-free (and always grants
/// rewards, matching the "rewarded always pays out" rule). [GoogleAdService]
/// drives real AdMob interstitials + rewarded ads and runs the UMP consent flow
/// before the first request.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

abstract class AdService {
  /// Runs consent + SDK init and preloads the first ads.
  Future<void> initialize();

  /// Shows an interstitial if available; completes when dismissed.
  Future<void> showInterstitial();

  /// Shows a rewarded ad. Returns true if the reward was earned.
  Future<bool> showRewarded();
}

/// No-op implementation for tests/dev. Rewards are always granted.
class FakeAdService implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> showInterstitial() async {}

  @override
  Future<bool> showRewarded() async => true;
}

class GoogleAdService implements AdService {
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _requestConsent();
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  /// UMP (GDPR) consent must complete before the first ad request.
  Future<void> _requestConsent() {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!completer.isCompleted) completer.complete();
        });
      },
      (error) {
        // Fail open: consent errors must not block a working (non-personalized)
        // experience.
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          _interstitial = null;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) {
          _rewarded = null;
          debugPrint('Rewarded failed to load: $error');
        },
      ),
    );
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
    );
    await ad.show();
    return completer.future;
  }

  @override
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) => earned = true,
    );
    return completer.future;
  }
}
