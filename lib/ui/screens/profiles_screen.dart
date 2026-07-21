/// Local player profiles: switch, create, rename, delete. Fully offline —
/// each profile has its own coins, level, highscore and progress.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage.dart';
import '../state/game_controller.dart';
import '../state/puzzle_controller.dart';
import '../state/settings_controller.dart';
import '../state/skin_controller.dart';
import '../state/theme_controller.dart';
import '../theme.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  Storage get _storage => ref.read(storageProvider);

  /// All state controllers cache storage values — rebuild them after a
  /// profile change so the whole app reflects the new profile.
  void _refreshProviders() {
    ref.invalidate(gameControllerProvider);
    ref.invalidate(settingsControllerProvider);
    ref.invalidate(themeControllerProvider);
    ref.invalidate(skinControllerProvider);
    ref.invalidate(puzzleControllerProvider);
  }

  Future<void> _switchTo(PlayerProfile profile) async {
    await _storage.setActiveProfile(profile.id);
    _refreshProviders();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aktives Profil: ${profile.name}')),
    );
  }

  Future<String?> _askName({String? initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: GridColors.boardBackground,
        title: Text(
          initial == null ? 'Neues Profil' : 'Profil umbenennen',
          style: const TextStyle(color: GridColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          style: const TextStyle(color: GridColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addProfile() async {
    final name = await _askName();
    if (name == null || name.isEmpty) return;
    final profile = await _storage.addProfile(name);
    await _switchTo(profile);
  }

  Future<void> _renameProfile(PlayerProfile profile) async {
    final name = await _askName(initial: profile.name);
    if (name == null || name.isEmpty) return;
    await _storage.renameProfile(profile.id, name);
    if (mounted) setState(() {});
  }

  Future<void> _deleteProfile(PlayerProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: GridColors.boardBackground,
        title: Text(
          '„${profile.name}" löschen?',
          style: const TextStyle(color: GridColors.textPrimary),
        ),
        content: const Text(
          'Der gesamte Fortschritt dieses Profils (Münzen, Level, Highscore, '
          'Themes …) wird endgültig gelöscht.',
          style: TextStyle(color: GridColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GridColors.fever),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final wasActive = _storage.activeProfileId == profile.id;
    await _storage.deleteProfile(profile.id);
    if (wasActive) _refreshProviders();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _storage.profiles;
    final activeId = _storage.activeProfileId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: GridColors.background,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProfile,
        backgroundColor: GridColors.placed,
        foregroundColor: GridColors.background,
        icon: const Icon(Icons.person_add),
        label: const Text('Neues Profil'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Jedes Profil hat eigene Münzen, eigenes Level und eigenen '
              'Fortschritt — alles bleibt auf diesem Gerät.',
              style: TextStyle(color: GridColors.textMuted, fontSize: 13),
            ),
          ),
          for (final profile in profiles)
            ListTile(
              onTap: profile.id == activeId ? null : () => _switchTo(profile),
              leading: Icon(
                profile.id == activeId
                    ? Icons.check_circle
                    : Icons.person_outline,
                color: profile.id == activeId
                    ? GridColors.placed
                    : GridColors.textMuted,
              ),
              title: Text(
                profile.name,
                style: const TextStyle(color: GridColors.textPrimary),
              ),
              subtitle: profile.id == activeId
                  ? const Text(
                      'Aktiv',
                      style:
                          TextStyle(color: GridColors.placed, fontSize: 12),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: GridColors.textMuted, size: 20),
                    tooltip: 'Umbenennen',
                    onPressed: () => _renameProfile(profile),
                  ),
                  if (profiles.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: GridColors.textMuted, size: 20),
                      tooltip: 'Löschen',
                      onPressed: () => _deleteProfile(profile),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}
