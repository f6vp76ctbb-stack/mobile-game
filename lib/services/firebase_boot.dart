/// Platform-split Firebase bootstrap.
///
/// Native builds initialize Firebase (Analytics + Crashlytics); the web build
/// compiles the stub instead, so no Firebase SDK code ends up in the PWA
/// bundle at all (the web leaderboard talks plain REST, see leaderboard.dart).
library;

export 'firebase_boot_stub.dart' if (dart.library.io) 'firebase_boot_native.dart';
