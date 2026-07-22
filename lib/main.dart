import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monetization/ads.dart';
import 'monetization/iap.dart';
import 'services/analytics.dart';
import 'services/audio.dart';
import 'services/firebase_boot.dart';
import 'services/notifications.dart';
import 'services/storage.dart';
import 'ui/app_bootstrap.dart';
import 'ui/state/game_controller.dart';
import 'ui/state/notifications_controller.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await Storage.create();

  // Configure audio as a GAME (ambient) before any player is created, so the
  // music never shows up in the system media controls like a Spotify track.
  await configureGameAudioSession();

  // Firebase (Analytics + Crashlytics) on native builds; null on web (the
  // stub) or when init fails — the game never depends on it.
  final firebaseAnalytics = await initFirebase();

  // AdMob, in_app_purchase and flutter_local_notifications have no web
  // implementation — on the web/PWA build they throw when invoked (which was
  // breaking "Nochmal spielen"). Use the no-op fakes there; native builds use
  // the real services.
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        audioProvider.overrideWithValue(AudioplayersAudio()),
        musicProvider.overrideWithValue(AudioplayersMusic()),
        adServiceProvider
            .overrideWithValue(kIsWeb ? FakeAdService() : GoogleAdService()),
        // Web: the released PWA must never deliver purchases for free
        // (leaderboard fairness) — LockedIap has no products and never
        // delivers. FakeIap only in local debug web builds for development.
        iapServiceProvider.overrideWithValue(
          kIsWeb ? (kDebugMode ? FakeIap() : LockedIap()) : StoreIap(),
        ),
        analyticsProvider
            .overrideWithValue(firebaseAnalytics ?? DebugAnalytics()),
        if (!kIsWeb)
          notificationServiceProvider
              .overrideWithValue(LocalNotifications()),
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
      title: 'Qubble',
      debugShowCheckedModeBanner: false,
      theme: buildGridTheme(),
      home: const AppBootstrap(),
    );
  }
}
