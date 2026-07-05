/// Runs one-time monetization init (ads consent + SDK, IAP purchase stream)
/// and wires IAP delivery to entitlements. Wraps the home screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monetization/iap.dart';
import '../services/analytics.dart';
import 'screens/home_screen.dart';
import 'state/game_controller.dart';
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
  }

  /// Applies a purchased/restored entitlement. Idempotent.
  Future<void> _deliver(String productId) async {
    final controller = ref.read(gameControllerProvider.notifier);
    if (productId == IapProducts.removeAds) {
      await controller.applyAdFree();
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
