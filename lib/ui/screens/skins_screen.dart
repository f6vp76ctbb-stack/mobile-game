/// Block skin picker: preview, unlock with gold or diamonds, and equip skins.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/block_skin.dart';
import '../../game/economy.dart';
import '../state/game_controller.dart';
import '../state/skin_controller.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/mini_board_preview.dart';

class SkinsScreen extends ConsumerWidget {
  const SkinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skinControllerProvider);
    final theme = ref.watch(activeThemeProvider);
    final snap = ref.watch(gameControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Block-Skins'),
        backgroundColor: GridColors.background,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: DiamondAmount(
                amount: snap.diamonds,
                size: 16,
                color: GridColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: kSkinCatalog.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i == kSkinCatalog.length) {
            return _ExchangeCard(coins: snap.coins);
          }
          final skin = kSkinCatalog[i];
          final owned = state.isUnlocked(skin.id);
          final active = state.activeId == skin.id;
          return _SkinTile(
            skin: skin,
            theme: theme,
            owned: owned,
            active: active,
            onTap: () async {
              final ok = await ref
                  .read(skinControllerProvider.notifier)
                  .selectOrUnlock(skin);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      skin.supporterOnly
                          ? 'Exklusiv im Unterstützer-Paket (siehe Shop) ❤️'
                          : skin.currency == SkinCurrency.diamond
                              ? 'Nicht genug Diamanten (unten Gold eintauschen)'
                              : 'Nicht genug Münzen',
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.theme,
    required this.owned,
    required this.active,
    required this.onTap,
  });

  final BlockSkin skin;
  final GameTheme theme;
  final bool owned;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = theme.placed;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GridColors.boardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? accent : GridColors.gridLine,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            MiniBoardPreview(theme: theme, style: skin.style, size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skin.name,
                    style: const TextStyle(
                      color: GridColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!active && !owned && !skin.supporterOnly)
                    Row(
                      children: [
                        if (skin.currency == SkinCurrency.diamond)
                          const DiamondIcon(size: 14)
                        else
                          const CoinIcon(size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '${skin.cost} zum Freischalten',
                          style: const TextStyle(
                            color: GridColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      active
                          ? 'Aktiv'
                          : owned
                              ? 'Tippen zum Aktivieren'
                              : 'Im Unterstützer-Paket ❤️',
                      style: const TextStyle(
                        color: GridColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle_rounded, color: accent)
            else if (!owned)
              const Icon(Icons.lock_outline_rounded,
                  color: GridColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Gold → diamond exchange. Deliberately steep so it takes real playtime.
class _ExchangeCard extends ConsumerWidget {
  const _ExchangeCard({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> exchange(int diamonds) async {
      final ok = await ref
          .read(gameControllerProvider.notifier)
          .exchangeGoldForDiamonds(diamonds);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nicht genug Gold.')),
        );
      }
    }

    Widget option(int diamonds) {
      final cost = Economy.goldCostForDiamonds(diamonds);
      final canAfford = coins >= cost;
      return Opacity(
        opacity: canAfford ? 1 : 0.4,
        child: FilledButton.tonal(
          onPressed: canAfford ? () => exchange(diamonds) : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiamondAmount(
                amount: diamonds,
                size: 15,
                color: GridColors.textPrimary,
              ),
              const SizedBox(height: 3),
              CoinAmount(
                amount: cost,
                size: 12,
                color: GridColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GridColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CoinIcon(size: 18),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: GridColors.textMuted),
              DiamondIcon(size: 18),
              SizedBox(width: 8),
              Text(
                'Gold eintauschen',
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${Economy.goldPerDiamond} Gold = 1 Diamant. Diamanten schalten die '
            'edelsten Skins frei — lass dir Zeit beim Sammeln.',
            style: const TextStyle(color: GridColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [option(1), option(10), option(50)],
          ),
        ],
      ),
    );
  }
}
