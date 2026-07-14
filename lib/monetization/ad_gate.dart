/// Pure-Dart interstitial frequency capping. No Flutter imports.
///
/// The non-negotiable monetization rules (CLAUDE.md):
///  - Interstitials show at the earliest after round 3.
///  - At most one interstitial per 90 seconds.
///  - "Ad-free" (IAP) suppresses interstitials entirely.
///  - Rewarded ads are NOT gated here — they are always voluntary and always
///    granted, so they never pass through this capping logic.
///
/// This is the single source of truth for interstitial timing; UI code must
/// ask [canShowInterstitial] and never show one directly.
library;

class AdGate {
  AdGate({
    required this.now,
    this.minRoundsBeforeInterstitial = 3,
    this.minInterstitialGap = const Duration(seconds: 90),
  });

  /// Injectable clock (real time in the app, controllable in tests).
  final DateTime Function() now;
  final int minRoundsBeforeInterstitial;
  final Duration minInterstitialGap;

  int _roundsCompleted = 0;
  DateTime? _lastInterstitialAt;

  /// Set true once the player owns the "remove ads" IAP.
  bool adFree = false;

  int get roundsCompleted => _roundsCompleted;

  /// Call once whenever a run ends (game over).
  void recordRoundComplete() => _roundsCompleted += 1;

  /// Whether an interstitial may be shown right now.
  bool canShowInterstitial() {
    if (adFree) return false;
    if (_roundsCompleted < minRoundsBeforeInterstitial) return false;
    final last = _lastInterstitialAt;
    if (last != null && now().difference(last) < minInterstitialGap) {
      return false;
    }
    return true;
  }

  /// Call right after an interstitial was actually shown, to start the cooldown.
  void recordInterstitialShown() => _lastInterstitialAt = now();
}
