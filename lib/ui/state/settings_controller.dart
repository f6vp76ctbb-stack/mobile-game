/// Riverpod controller for user settings (sound, haptics). Applies the flags to
/// the live [Haptics] and [AudioService] instances and persists them.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio.dart';
import '../../services/haptics.dart';
import '../../services/storage.dart';
import 'game_controller.dart';

@immutable
class SettingsState {
  const SettingsState({required this.sound, required this.haptics});

  final bool sound;
  final bool haptics;
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(
    ref.read(storageProvider),
    ref.read(hapticsProvider),
    ref.read(audioProvider),
  );
});

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._storage, this._haptics, this._audio)
      : super(SettingsState(
          sound: _storage.soundEnabled,
          haptics: _storage.hapticsEnabled,
        )) {
    _apply();
  }

  final Storage _storage;
  final Haptics _haptics;
  final AudioService _audio;

  void _apply() {
    _haptics.enabled = state.haptics;
    _audio.enabled = state.sound;
  }

  Future<void> setSound(bool value) async {
    await _storage.setSoundEnabled(value);
    state = SettingsState(sound: value, haptics: state.haptics);
    _apply();
  }

  Future<void> setHaptics(bool value) async {
    await _storage.setHapticsEnabled(value);
    state = SettingsState(sound: state.sound, haptics: value);
    _apply();
  }
}
