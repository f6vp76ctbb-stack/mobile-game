/// Shop: remove-ads (non-consumable) and coin packs (consumable) + restore.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../monetization/iap.dart';
import '../state/game_controller.dart';
import '../theme.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.watch(iapServiceProvider);
    final adFree = ref.watch(gameControllerProvider).adFree;
    final products = iap.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: GridColors.background,
        actions: [
          TextButton(
            onPressed: iap.restore,
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final p in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ProductTile(
                product: p,
                owned: p.id == IapProducts.removeAds && adFree,
                onBuy: () => iap.buy(p.id),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Käufe sind an dein Store-Konto gebunden und lassen sich jederzeit '
            'wiederherstellen. „Werbefrei“ entfernt Interstitials — freiwillige '
            'Video-Belohnungen bleiben erhalten.',
            style: TextStyle(color: GridColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.owned,
    required this.onBuy,
  });

  final ShopProduct product;
  final bool owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GridColors.gridLine),
      ),
      child: Row(
        children: [
          Text(
            product.id == IapProducts.removeAds ? '🚫' : '🪙',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              product.title,
              style: const TextStyle(
                color: GridColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (owned)
            const Text(
              'Aktiv',
              style: TextStyle(color: GridColors.placed, fontSize: 14),
            )
          else
            FilledButton(
              onPressed: onBuy,
              child: Text(product.price),
            ),
        ],
      ),
    );
  }
}
