/// Native (Android/iOS) Firebase bootstrap: Crashlytics + Analytics.
///
/// Options are built from [FirebaseConfig] instead of `flutterfire configure`
/// output, so the git-ignored google-services.json is only needed by the
/// Android Gradle build itself. iOS is skipped until an iOS app is registered
/// in the Firebase console (App-Store phase).
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics.dart';
import 'firebase_config.dart';

/// Initializes Firebase and returns the analytics backend, or null when this
/// platform has no Firebase app (or init failed) — the game runs fine without.
Future<Analytics?> initFirebase() async {
  if (!Platform.isAndroid) return null;
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: FirebaseConfig.apiKey,
        appId: FirebaseConfig.androidAppId,
        messagingSenderId: FirebaseConfig.messagingSenderId,
        projectId: FirebaseConfig.projectId,
        storageBucket: FirebaseConfig.storageBucket,
      ),
    );
    // Crash reporting: uncaught Flutter + platform errors go to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    return FirebaseAnalyticsBackend(FirebaseAnalytics.instance);
  } catch (e) {
    // Never block the game on analytics infrastructure.
    debugPrint('Firebase init failed, running without: $e');
    return null;
  }
}

/// Sends the funnel events to Firebase Analytics (fire-and-forget).
class FirebaseAnalyticsBackend implements Analytics {
  FirebaseAnalyticsBackend(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {
    // Firebase only accepts String/num parameter values.
    final cleaned = <String, Object>{
      for (final e in params.entries)
        if (e.value != null)
          e.key: (e.value is String || e.value is num)
              ? e.value!
              : e.value.toString(),
    };
    unawaited(_analytics.logEvent(
      name: name,
      parameters: cleaned.isEmpty ? null : cleaned,
    ));
  }
}
