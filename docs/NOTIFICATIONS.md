# Lokale Benachrichtigungen — Setup & Verifikation

Offline, kein Server. Logik in `lib/services/notification_planner.dart` (pure,
getestet), Zustellung in `lib/services/notifications.dart`
(`flutter_local_notifications` + `timezone`).

## Was drin ist

- **Daily-Reminder** 19:00, **Streak-Warnung** 21:30 (ab Streak ≥ 3),
  **Comeback** nach 72 h; Comeback-Geschenk (100 Münzen) beim Öffnen.
- **Opt-in** erst beim 2. App-Start (Dialog), abschaltbar unter
  Einstellungen → Benachrichtigungen.
- Wird bei jedem App-Start neu geplant (`NotificationsController.refresh`).

## Auf einem echten Build zu prüfen (👤)

Der Dart-Code kompiliert (via `flutter analyze`), aber die native Zustellung
braucht ein Geräte-/Emulator-Build. Bitte einmal verifizieren:

- **Android 13+**: Laufzeit-Permission `POST_NOTIFICATIONS` (im Manifest
  ergänzt) wird beim Opt-in abgefragt. Prüfen, dass der Dialog erscheint.
- Es wird **inexakte** Planung genutzt (`inexactAllowWhileIdle`) — bewusst,
  um die `SCHEDULE_EXACT_ALARM`-Sonderrechte zu vermeiden. Benachrichtigungen
  können dadurch um einige Minuten variieren (für Reminder unkritisch).
- **Zeitzone**: `flutter_timezone` liefert die lokale Zone; bei Fehler Fallback
  auf UTC. Auf dem Testgerät kontrollieren, dass der Reminder zur lokalen Zeit
  kommt.
- **iOS** (später): Permission-Abfrage läuft über den Opt-in-Flow. Für den
  App-Store-Gang ggf. `AppDelegate` gemäß Plugin-Doku prüfen.
- Optional: `RECEIVE_BOOT_COMPLETED` (im Manifest) erlaubt Reschedule nach
  Neustart — die Notes werden ohnehin bei jedem App-Start neu geplant.

## Testen ohne 3 Tage warten

Zeiten in `NotificationPlanner` sind Konstanten — zum manuellen Testen temporär
`dailyReminderHour`/`comebackAfter` verkleinern, Build starten, App schließen,
warten. Vor dem Commit zurücksetzen.
