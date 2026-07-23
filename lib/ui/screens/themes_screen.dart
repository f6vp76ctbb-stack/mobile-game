/// Theme picker: preview, unlock with coins, and equip board palettes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/block_skin.dart';
import '../state/game_controller.dart';
import '../state/skin_controller.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/mini_board_preview.dart';

class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final coins = ref.watch(gameControllerProvider).coins;
    final skinStyle = ref.watch(activeSkinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
        backgroundColor: GridColors.background,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: kThemeCatalog.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final entry = kThemeCatalog[i];
          final owned = themeState.isUnlocked(entry.id);
          final active = themeState.activeId == entry.id;
          return _ThemeTile(
            entry: entry,
            skinStyle: skinStyle,
            owned: owned,
            active: active,
            onTap: () async {
              final ok = await ref
                  .read(themeControllerProvider.notifier)
                  .selectOrUnlock(entry);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      entry.supporterOnly
                          ? 'Exklusiv im Unterstützer-Paket (siehe Shop) ❤️'
                          : 'Nicht genug Münzen (brauchst ${entry.cost}, hast $coins)',
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

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.entry,
    required this.skinStyle,
    required this.owned,
    required this.active,
    required this.onTap,
  });

  final ThemeEntry entry;
  final BlockSkinStyle skinStyle;
  final bool owned;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = entry.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.boardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? t.placed : GridColors.gridLine,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            MiniBoardPreview(theme: t, style: skinStyle, size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      color: GridColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!active &&
                      !owned &&
                      !entry.supporterOnly &&
                      entry.cost >= 0)
                    Row(
                      children: [
                        entry.id == 'neon'
                            ? const DiamondIcon(size: 14)
                            : const CoinIcon(size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '${entry.cost} zum Freischalten',
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
              Icon(Icons.check_circle, color: t.placed)
            else if (!owned)
              const Icon(Icons.lock_outline, color: GridColors.textMuted),
          ],
        ),
      ),
    );
  }
}
