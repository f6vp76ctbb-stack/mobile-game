import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monetization/ads.dart';
import 'monetization/iap.dart';
import 'services/analytics.dart';
import 'services/audio.dart';
import 'services/notifications.dart';
import 'services/storage.dart';
import 'ui/app_bootstrap.dart';
import 'ui/state/game_controller.dart';
import 'ui/state/notifications_controller.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await Storage.create();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        audioProvider.overrideWithValue(AudioplayersAudio()),
        adServiceProvider.overrideWithValue(GoogleAdService()),
        iapServiceProvider.overrideWithValue(StoreIap()),
        // Firebase backend lands once config files exist; DebugAnalytics prints
        // the funnel in the meantime (see docs/SETUP-ACCOUNTS.md).
        analyticsProvider.overrideWithValue(DebugAnalytics()),
        notificationServiceProvider.overrideWithValue(LocalNotifications()),
      ],
      child: const GridPopApp(),
    ),
  );
}

class GridPopApp extends StatelessWidget {
  const GridPopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridPop',
      debugShowCheckedModeBanner: false,
      theme: buildGridTheme(),
      home: const AppBootstrap(),
    );
  }
}
