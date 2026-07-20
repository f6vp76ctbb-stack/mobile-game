/// Riverpod controller for user settings (sound, music, haptics). Applies the
/// flags to the live [Haptics], [AudioService] and [MusicService] instances
/// and persists them.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio.dart';
import '../../services/haptics.dart';
import '../../services/storage.dart';
import 'game_controller.dart';

@immutable
class SettingsState {
  const SettingsState({
    required this.sound,
    required this.music,
    required this.haptics,
  });

  final bool sound;
  final bool music;
  final bool haptics;
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(
    ref.read(storageProvider),
    ref.read(hapticsProvider),
    ref.read(audioProvider),
    ref.read(musicProvider),
  );
});

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._storage, this._haptics, this._audio, this._music)
      : super(SettingsState(
          sound: _storage.soundEnabled,
          music: _storage.musicEnabled,
          haptics: _storage.hapticsEnabled,
        )) {
    _apply();
  }

  final Storage _storage;
  final Haptics _haptics;
  final AudioService _audio;
  final MusicService _music;

  void _apply() {
    _haptics.enabled = state.haptics;
    _audio.enabled = state.sound;
    _music.enabled = state.music;
  }

  Future<void> setSound(bool value) async {
    await _storage.setSoundEnabled(value);
    state = SettingsState(
      sound: value,
      music: state.music,
      haptics: state.haptics,
    );
    _apply();
  }

  Future<void> setMusic(bool value) async {
    await _storage.setMusicEnabled(value);
    state = SettingsState(
      sound: state.sound,
      music: value,
      haptics: state.haptics,
    );
    _apply();
    // Turning music on is itself a tap — start the loop right away.
    if (value) await _music.ensureStarted();
  }

  Future<void> setHaptics(bool value) async {
    await _storage.setHapticsEnabled(value);
    state = SettingsState(
      sound: state.sound,
      music: state.music,
      haptics: value,
    );
    _apply();
  }
}
