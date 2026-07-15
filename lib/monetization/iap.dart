/// In-app purchase abstraction over `in_app_purchase`.
///
/// [FakeIap] delivers instantly for tests/dev; [StoreIap] talks to the real
/// stores. Product IDs follow MASTERPLAN.md Anhang A.5. "Remove ads" is
/// non-consumable and keeps rewarded options; coin packs are consumable.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Product identifiers (must match the store console entries exactly).
class IapProducts {
  const IapProducts._();

  static const removeAds = 'qubble_remove_ads';
  static const coinsS = 'qubble_coins_s';
  static const coinsM = 'qubble_coins_m';
  static const coinsL = 'qubble_coins_l';
  static const piggy = 'qubble_piggy';
  static const starter = 'qubble_starter';

  static const all = <String>{
    removeAds,
    coinsS,
    coinsM,
    coinsL,
    piggy,
    starter,
  };

  /// Coins granted per fixed-amount consumable pack. (The piggy bank pays out a
  /// variable amount, so it is not listed here.)
  static const coinAmounts = <String, int>{
    coinsS: 500,
    coinsM: 2000,
    coinsL: 6000,
  };

  static const _consumables = <String>{coinsS, coinsM, coinsL, piggy, starter};

  static bool isConsumable(String id) => _consumables.contains(id);
}

/// A purchasable item surfaced to the shop UI.
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.consumable,
  });

  final String id;
  final String title;
  final String price; // localized price string from the store
  final bool consumable;
}

abstract class IapService {
  /// Sets up the purchase stream. [onDeliver] is invoked for every purchased or
  /// restored product id and must apply the entitlement (idempotently).
  Future<void> initialize(
    FutureOr<void> Function(String productId) onDeliver,
  );

  bool get available;
  List<ShopProduct> get products;
  Future<void> buy(String productId);
  Future<void> restore();
}

/// In-memory implementation: purchases deliver immediately. Used in tests and
/// as a safe default until store products exist.
class FakeIap implements IapService {
  FutureOr<void> Function(String productId)? _onDeliver;

  @override
  bool get available => true;

  @override
  List<ShopProduct> get products => const [
        ShopProduct(
          id: IapProducts.removeAds,
          title: 'Werbefrei',
          price: '4,99 €',
          consumable: false,
        ),
        ShopProduct(
          id: IapProducts.coinsS,
          title: '500 Münzen',
          price: '0,99 €',
          consumable: true,
        ),
        ShopProduct(
          id: IapProducts.coinsM,
          title: '2000 Münzen',
          price: '2,99 €',
          consumable: true,
        ),
        ShopProduct(
          id: IapProducts.coinsL,
          title: '6000 Münzen',
          price: '7,99 €',
          consumable: true,
        ),
      ];

  @override
  Future<void> initialize(
    FutureOr<void> Function(String productId) onDeliver,
  ) async {
    _onDeliver = onDeliver;
  }

  @override
  Future<void> buy(String productId) async {
    await _onDeliver?.call(productId);
  }

  @override
  Future<void> restore() async {}
}

class StoreIap implements IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  FutureOr<void> Function(String productId)? _onDeliver;
  List<ShopProduct> _products = const [];
  bool _available = false;

  @override
  bool get available => _available;

  @override
  List<ShopProduct> get products => _products;

  @override
  Future<void> initialize(
    FutureOr<void> Function(String productId) onDeliver,
  ) async {
    _onDeliver = onDeliver;
    _available = await _iap.isAvailable();
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) => debugPrint('Purchase stream error: $e'),
    );

    final response = await _iap.queryProductDetails(IapProducts.all);
    _products = [
      for (final p in response.productDetails)
        ShopProduct(
          id: p.id,
          title: p.title,
          price: p.price,
          consumable: IapProducts.isConsumable(p.id),
        ),
    ];
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _onDeliver?.call(purchase.productID);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  @override
  Future<void> buy(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) return;
    final details = response.productDetails.first;
    final param = PurchaseParam(productDetails: details);
    if (IapProducts.isConsumable(productId)) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  void dispose() => _sub?.cancel();
}
