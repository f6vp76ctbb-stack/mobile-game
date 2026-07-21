/// Block skin picker: preview, unlock with coins, and equip skins.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/block_skin.dart';
import '../state/skin_controller.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/mini_board_preview.dart';

class SkinsScreen extends ConsumerWidget {
  const SkinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skinControllerProvider);
    final theme = ref.watch(activeThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Block-Skins'),
        backgroundColor: GridColors.background,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: kSkinCatalog.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
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
                  Text(
                    active
                        ? 'Aktiv'
                        : owned
                            ? 'Tippen zum Aktivieren'
                            : skin.supporterOnly
                                ? '❤️ Im Unterstützer-Paket'
                                : '🪙 ${skin.cost} zum Freischalten',
                    style: const TextStyle(
                      color: GridColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle, color: accent)
            else if (!owned)
              const Icon(Icons.lock_outline, color: GridColors.textMuted),
          ],
        ),
      ),
    );
  }
}
