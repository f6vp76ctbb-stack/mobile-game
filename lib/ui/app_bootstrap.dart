/// Runs one-time monetization init (ads consent + SDK, IAP purchase stream)
/// and wires IAP delivery to entitlements. Wraps the home screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monetization/iap.dart';
import '../services/analytics.dart';
import '../services/notification_planner.dart';
import 'screens/home_screen.dart';
import 'state/game_controller.dart';
import 'state/notifications_controller.dart';
import 'state/settings_controller.dart';

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the UI is usable while ads/IAP warm up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Force settings creation so sound/haptics flags are applied to the live
    // services from launch.
    ref.read(settingsControllerProvider);
    await ref.read(adServiceProvider).initialize();
    await ref.read(iapServiceProvider).initialize(_deliver);
    await _sessionStartHousekeeping();
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

    // Keep any already-scheduled notifications fresh.
    await ref.read(notificationsControllerProvider.notifier).refresh();

    // Opt-in on the second launch (never on the very first).
    if (opens == 2 &&
        !storage.notificationsEnabled &&
        mounted) {
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

  /// Applies a purchased/restored entitlement. Idempotent.
  Future<void> _deliver(String productId) async {
    final controller = ref.read(gameControllerProvider.notifier);
    if (productId == IapProducts.removeAds) {
      await controller.applyAdFree();
    } else if (productId == IapProducts.piggy) {
      await controller.openPiggy();
    } else {
      await controller.grantCoins(IapProducts.coinAmounts[productId] ?? 0);
    }
    ref
        .read(analyticsProvider)
        .logEvent(AnalyticsEvent.purchase, {'product': productId});
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
