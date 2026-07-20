/// Settings: sound/haptics toggles, ad-free/restore, privacy, about.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../state/notifications_controller.dart';
import '../state/settings_controller.dart';
import '../theme.dart';
import 'shop_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Hidden admin/test mode: unlocked by tapping the footer 7 times.
  static const int _adminTapTarget = 7;
  int _footerTaps = 0;
  bool _adminUnlocked = false;

  void _onFooterTap() {
    if (_adminUnlocked) return;
    setState(() => _footerTaps += 1);
    if (_footerTaps >= _adminTapTarget) {
      setState(() => _adminUnlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔧 Admin-Modus aktiviert')),
      );
    } else if (_footerTaps >= _adminTapTarget - 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 600),
          content: Text(
            'Noch ${_adminTapTarget - _footerTaps}× tippen für Admin-Modus',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final snap = ref.watch(gameControllerProvider);
    final adFree = snap.adFree;
    final iap = ref.read(iapServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: GridColors.background,
      ),
      body: ListView(
        children: [
          const _SectionLabel('Ton & Haptik'),
          SwitchListTile(
            title: const Text('Sound', style: _tileStyle),
            value: settings.sound,
            onChanged: controller.setSound,
            activeThumbColor: GridColors.placed,
          ),
          SwitchListTile(
            title: const Text('Musik', style: _tileStyle),
            value: settings.music,
            onChanged: controller.setMusic,
            activeThumbColor: GridColors.placed,
          ),
          SwitchListTile(
            title: const Text('Vibration', style: _tileStyle),
            value: settings.haptics,
            onChanged: controller.setHaptics,
            activeThumbColor: GridColors.placed,
          ),
          const _SectionLabel('Erinnerungen'),
          SwitchListTile(
            title: const Text('Benachrichtigungen', style: _tileStyle),
            subtitle: const Text(
              'Daily-Erinnerung & Streak-Schutz',
              style: TextStyle(color: GridColors.textMuted, fontSize: 13),
            ),
            value: ref.watch(notificationsControllerProvider),
            activeThumbColor: GridColors.placed,
            onChanged: (want) async {
              final notifier =
                  ref.read(notificationsControllerProvider.notifier);
              if (want) {
                final ok = await notifier.enable();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('In den System-Einstellungen erlauben.'),
                    ),
                  );
                }
              } else {
                await notifier.disable();
              }
            },
          ),
          const _SectionLabel('Käufe'),
          if (adFree)
            const ListTile(
              leading: Icon(Icons.check_circle, color: GridColors.placed),
              title: Text('Werbung entfernt', style: _tileStyle),
            )
          else
            ListTile(
              leading: const Icon(Icons.block, color: GridColors.textPrimary),
              title: const Text('Werbefrei kaufen', style: _tileStyle),
              trailing: const Icon(Icons.chevron_right,
                  color: GridColors.textMuted),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.restore, color: GridColors.textPrimary),
            title: const Text('Käufe wiederherstellen', style: _tileStyle),
            onTap: () async {
              await iap.restore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Käufe werden wiederhergestellt…')),
                );
              }
            },
          ),
          const _SectionLabel('Rechtliches'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: GridColors.textPrimary),
            title: const Text('Datenschutz', style: _tileStyle),
            onTap: () => _showPrivacy(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: GridColors.textPrimary),
            title: const Text('Impressum', style: _tileStyle),
            onTap: () => _showImpressum(context),
          ),
          if (_adminUnlocked) ...[
            const _SectionLabel('Admin (Test)'),
            ListTile(
              leading: const Icon(Icons.paid_outlined,
                  color: GridColors.textPrimary),
              title: Text('🪙 ${snap.coins} Münzen', style: _tileStyle),
              subtitle: const Text(
                'Nur zum Testen — nicht in Release-Screenshots zeigen',
                style: TextStyle(color: GridColors.textMuted, fontSize: 12),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: GridColors.placed),
              title: const Text('+1.000 Münzen', style: _tileStyle),
              onTap: () =>
                  ref.read(gameControllerProvider.notifier).grantCoins(1000),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: GridColors.placed),
              title: const Text('+10.000 Münzen', style: _tileStyle),
              onTap: () =>
                  ref.read(gameControllerProvider.notifier).grantCoins(10000),
            ),
            ListTile(
              leading:
                  const Icon(Icons.exposure_zero, color: GridColors.fever),
              title: const Text('Münzen auf 0 setzen', style: _tileStyle),
              onTap: () =>
                  ref.read(gameControllerProvider.notifier).setCoinsForTest(0),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onFooterTap,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Qubble • Offline Block Puzzle',
                  style: TextStyle(color: GridColors.textMuted, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GridColors.boardBackground,
        title: const Text('Datenschutz', style: _tileStyle),
        content: const Text(
          'Qubble speichert deinen Fortschritt nur lokal auf dem Gerät — kein '
          'Konto, kein eigener Server. Werbung (AdMob) und Analyse (Firebase) '
          'nutzen Drittdienste; vor der ersten Anzeige läuft der DSGVO-'
          'Einwilligungsdialog. Die vollständige Datenschutzerklärung wird vor '
          'dem Launch verlinkt.',
          style: TextStyle(color: GridColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImpressum(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GridColors.boardBackground,
        title: const Text('Impressum', style: _tileStyle),
        content: const Text(
          'Anbieterangaben gemäß § 5 DDG werden vor dem Launch hier eingetragen '
          'und verlinkt.',
          style: TextStyle(color: GridColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

const _tileStyle = TextStyle(color: GridColors.textPrimary);

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: GridColors.textMuted,
          fontSize: 12,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
