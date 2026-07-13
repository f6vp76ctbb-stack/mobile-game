/// Riverpod controller for unlockable block skins (mirrors the theme system).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/block_skin.dart';
import '../../services/storage.dart';
import 'game_controller.dart';

@immutable
class SkinState {
  const SkinState({required this.activeId, required this.unlocked});

  final String activeId;
  final Set<String> unlocked;

  bool isUnlocked(String id) => unlocked.contains(id);
}

final skinControllerProvider =
    StateNotifierProvider<SkinController, SkinState>((ref) {
  return SkinController(ref.read(storageProvider), ref);
});

/// The active block-skin style for painters.
final activeSkinProvider = Provider<BlockSkinStyle>((ref) {
  return skinStyleById(ref.watch(skinControllerProvider).activeId);
});

class SkinController extends StateNotifier<SkinState> {
  SkinController(this._storage, this._ref)
      : super(SkinState(
          activeId: _storage.activeSkin,
          unlocked: _storage.unlockedSkins,
        ));

  final Storage _storage;
  final Ref _ref;

  Future<void> setActive(String id) async {
    if (!state.isUnlocked(id)) return;
    await _storage.setActiveSkin(id);
    state = SkinState(activeId: id, unlocked: state.unlocked);
  }

  /// Buys (if needed) and equips [skin]. Returns false if unaffordable.
  Future<bool> selectOrUnlock(BlockSkin skin) async {
    if (state.isUnlocked(skin.id)) {
      await setActive(skin.id);
      return true;
    }
    final paid =
        await _ref.read(gameControllerProvider.notifier).trySpendCoins(skin.cost);
    if (!paid) return false;

    final unlocked = {...state.unlocked, skin.id};
    await _storage.setUnlockedSkins(unlocked);
    await _storage.setActiveSkin(skin.id);
    state = SkinState(activeId: skin.id, unlocked: unlocked);
    return true;
  }
}
