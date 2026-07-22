/// Shop: supporter pack (non-consumable) and coin packs (consumable) + restore.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../monetization/iap.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import '../widgets/app_icons.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.watch(iapServiceProvider);
    final supporter = ref.watch(gameControllerProvider).supporter;
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
          // Locked storefront (public web/PWA): purchases only exist in the
          // store apps, so the web demo can't hand out anything for free.
          if (products.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GridColors.boardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GridColors.gridLine),
              ),
              child: const Text(
                'Käufe gibt es nur in der App aus dem Play Store. Diese '
                'Web-Version ist eine kostenlose Demo — spielen kannst du '
                'hier trotzdem alles.',
                style: TextStyle(color: GridColors.textMuted, fontSize: 14),
              ),
            ),
          for (final p in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ProductTile(
                product: p,
                owned: p.id == IapProducts.supporter && supporter,
                onBuy: () => iap.buy(p.id),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Qubble zeigt keine erzwungene Werbung — kaufen musst du hier '
            'nichts. Das Unterstützer-Paket (Aurora-Theme, Kristall-Skin, '
            '1.500 Münzen, ❤️-Abzeichen) ist ein Dankeschön fürs Unterstützen. '
            'Käufe sind an dein Store-Konto gebunden und jederzeit '
            'wiederherstellbar.',
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
          product.id == IapProducts.supporter
              ? const Icon(Icons.favorite_rounded,
                  color: Color(0xFFFF6FB0), size: 24)
              : const CoinIcon(size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.id == IapProducts.supporter)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Aurora-Theme + Kristall-Skin + 1.500 Münzen',
                      style:
                          TextStyle(color: GridColors.textMuted, fontSize: 12),
                    ),
                  ),
              ],
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
