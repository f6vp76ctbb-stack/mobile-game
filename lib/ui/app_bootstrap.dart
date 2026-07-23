/// Runs one-time monetization init (ads consent + SDK, IAP purchase stream)
/// and wires IAP delivery to entitlements. Wraps the home screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monetization/purchase_delivery.dart';
import '../services/notification_planner.dart';
import 'screens/home_screen.dart';
import 'state/game_controller.dart';
import 'state/notifications_controller.dart';
import 'state/settings_controller.dart';
import 'state/skin_controller.dart';
import 'state/theme_controller.dart';

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  PurchaseDelivery? _purchaseDelivery;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the UI is usable while ads/IAP warm up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Force settings creation so sound/haptics flags apply from launch. Each
    // external subsystem is isolated: a store, notification or consent outage
    // must never prevent the remaining startup work.
    ref.read(settingsControllerProvider);
    await _runSafely(
      'in-app purchases',
      () => ref.read(iapServiceProvider).initialize(_deliver),
    );
    await _runSafely('session housekeeping', _sessionStartHousekeeping);
    await _runSafely(
      'ads/consent',
      () => ref.read(adServiceProvider).initialize(),
    );
  }

  Future<void> _runSafely(
    String subsystem,
    Future<void> Function() task,
  ) async {
    try {
      await task();
    } catch (error) {
      debugPrint('$subsystem initialization failed: $error');
    }
  }

  /// Comeback gift, app-open counting, opt-in prompt, and re-scheduling.
  Future<void> _sessionStartHousekeeping() async {
    final storage = ref.read(storageProvider);
    final now = DateTime.now();

    // Comeback gift for returning after a long absence (before updating time).
    final gift = NotificationPlanner.comebackGift(
      lastActive: storage.lastActive,
      now: now,
    );
    if (gift > 0) {
      await ref.read(gameControllerProvider.notifier).grantCoins(gift);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Willkommen zurück! 🪙 +$gift Münzen')),
        );
      }
    }
    await storage.setLastActive(now);

    final opens = storage.appOpenCount + 1;
    await storage.setAppOpenCount(opens);

    // Retry a best-score upload that may have failed offline last time.
    ref.read(gameControllerProvider.notifier).autoUploadBestScore();

    // Keep any already-scheduled notifications fresh.
    await ref.read(notificationsControllerProvider.notifier).refresh();

    // Opt-in on the second launch (never on the very first).
    if (opens == 2 && !storage.notificationsEnabled && mounted) {
      await _promptNotificationsOptIn();
    }
  }

  Future<void> _promptNotificationsOptIn() async {
    final enable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erinnerungen?'),
        content: const Text(
          'Sollen wir dich an dein tägliches Puzzle erinnern und deinen Streak '
          'schützen? Du kannst das jederzeit in den Einstellungen ändern.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nicht jetzt'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ja, gerne'),
          ),
        ],
      ),
    );
    if (enable ?? false) {
      await ref.read(notificationsControllerProvider.notifier).enable();
    }
  }

  PurchaseDelivery _createPurchaseDelivery() {
    final controller = ref.read(gameControllerProvider.notifier);
    return PurchaseDelivery(
      storage: ref.read(storageProvider),
      grantCoins: controller.grantCoins,
      grantTheme: ref.read(themeControllerProvider.notifier).grantTheme,
      grantSkin: ref.read(skinControllerProvider.notifier).grantSkin,
      markSupporter: controller.applySupporter,
      markStarterPurchased: controller.markStarterPurchased,
      grantRenameCredit: controller.grantRenameCredit,
      analytics: ref.read(analyticsProvider),
    );
  }

  /// Applies a purchased/restored product through one serialized delivery
  /// queue for the lifetime of this app instance.
  Future<void> _deliver(String productId) {
    final delivery = _purchaseDelivery ??= _createPurchaseDelivery();
    return delivery.deliver(productId);
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
