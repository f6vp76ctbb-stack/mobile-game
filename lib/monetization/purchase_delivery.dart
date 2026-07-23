/// Idempotent delivery of store products to local game entitlements.
library;

import '../game/starter_offer.dart';
import '../game/supporter_pack.dart';
import '../services/analytics.dart';
import '../services/storage.dart';
import 'iap.dart';

typedef _GrantCoins = Future<void> Function(int amount);
typedef _GrantEntitlement = Future<void> Function(String id);
typedef _MarkPurchased = Future<void> Function();

/// Applies purchased and restored products in arrival order.
///
/// Store purchase streams can emit a new batch while the previous batch is
/// still being delivered. Serializing here prevents two supporter events from
/// both observing the entitlement as unowned.
class PurchaseDelivery {
  factory PurchaseDelivery({
    required Storage storage,
    required Future<void> Function(int amount) grantCoins,
    required Future<void> Function(String id) grantTheme,
    required Future<void> Function(String id) grantSkin,
    required Future<void> Function() markSupporter,
    required Future<void> Function() markStarterPurchased,
    required Future<void> Function() grantRenameCredit,
    required Analytics analytics,
  }) {
    return PurchaseDelivery._(
      storage,
      grantCoins,
      grantTheme,
      grantSkin,
      markSupporter,
      markStarterPurchased,
      grantRenameCredit,
      analytics,
    );
  }

  PurchaseDelivery._(
    this._storage,
    this._grantCoins,
    this._grantTheme,
    this._grantSkin,
    this._markSupporter,
    this._markStarterPurchased,
    this._grantRenameCredit,
    this._analytics,
  );

  final Storage _storage;
  final _GrantCoins _grantCoins;
  final _GrantEntitlement _grantTheme;
  final _GrantEntitlement _grantSkin;
  final _MarkPurchased _markSupporter;
  final _MarkPurchased _markStarterPurchased;
  final _MarkPurchased _grantRenameCredit;
  final Analytics _analytics;

  Future<void> _tail = Future<void>.value();

  /// Delivers one product and completes when its writes have finished.
  Future<void> deliver(String productId) {
    final result = _tail.then((_) => _deliverNow(productId));
    // Keep the queue usable after one failed delivery while returning the
    // original error to the store callback.
    _tail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  Future<void> _deliverNow(String productId) async {
    if (productId == IapProducts.supporter) {
      final grantsWelcomeCoins = !_storage.supporter;

      // Persist ownership before the additive reward. A repeated stream event
      // or later restore can therefore never grant the 1,500 coins again.
      if (grantsWelcomeCoins) {
        await _markSupporter();
        await _grantCoins(SupporterPack.coins);
      }

      // These grants are set-based and intentionally run on every restore, so
      // an incomplete or migrated installation repairs missing cosmetics.
      await _grantTheme(SupporterPack.themeId);
      await _grantSkin(SupporterPack.skinId);
    } else if (productId == IapProducts.rename) {
      await _grantRenameCredit();
    } else if (productId == IapProducts.neonTheme) {
      await _grantTheme('neon');
    } else if (productId == IapProducts.starter) {
      await _grantCoins(StarterOffer.coins);
      await _grantTheme(StarterOffer.themeId);
      await _markStarterPurchased();
    } else {
      await _grantCoins(IapProducts.coinAmounts[productId] ?? 0);
    }

    _analytics.logEvent(AnalyticsEvent.purchase, {'product': productId});
  }
}
