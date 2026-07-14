# Lokal testen: PC + iPhone (Web-Version)

GridPop ist eine **Flutter**-App, keine Expo/React-Native-App — Expo Go
funktioniert damit nicht. Diese Anleitung nutzt stattdessen Flutters
**Web-Version**: läuft über deinen Windows-PC im lokalen WLAN, das iPhone
öffnet sie im Safari-Browser. Kein Mac, kein Xcode nötig.

**Einschränkung der Web-Version:** Werbung (AdMob), In-App-Käufe, Push-
Benachrichtigungen und Vibration funktionieren im Browser nicht (Plattform-
Limits). Board, Ziehen der Steine, Punkte, Combo/Fieber, Themes, Missionen,
Rätsel-Modus, Sound und Statistik laufen aber normal.

## 1. Flutter auf deinem Windows-PC installieren

1. Flutter SDK laden: https://docs.flutter.dev/get-started/install/windows
   (ZIP entpacken, z. B. nach `C:\flutter`, den `bin`-Ordner zum PATH hinzufügen)
2. Prüfen: PowerShell öffnen, `flutter --version` ausführen
3. `flutter doctor` ausführen — für die Web-Version reicht es, wenn Chrome
   erkannt wird; Android-Studio-/Visual-Studio-Warnungen können ignoriert werden

## 2. Projekt nach `C:\Spiele` holen

```powershell
cd C:\Spiele
git clone https://github.com/f6vp76ctbb-stack/mobile-game.git gridpop
cd gridpop
git checkout claude/app-store-game-idea-jn0blw
flutter pub get
```

> Der aktuelle Entwicklungsstand liegt auf dem Branch
> `claude/app-store-game-idea-jn0blw` (noch nicht in `main` gemerged).

## 3. Auf dem PC direkt im Browser testen

```powershell
flutter run -d chrome
```

Öffnet automatisch Chrome mit der App. Hot Reload funktioniert: Code ändern,
im Terminal `r` drücken, sofort sehen.

## 4. Auf dem iPhone testen (über dein WLAN)

Handy und PC müssen im **gleichen WLAN** sein.

```powershell
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

Dann die **lokale IP-Adresse deines PCs** herausfinden:

```powershell
ipconfig
```

(unter „IPv4-Adresse" nachsehen, z. B. `192.168.1.23`)

Auf dem iPhone in Safari öffnen: `http://<PC-IP>:8080` — z. B.
`http://192.168.1.23:8080`

> Falls die Windows-Firewall fragt: PC-Netzwerk als „Privat" erlauben, damit
> das iPhone den Port erreicht.

## 5. Was du wirklich testen kannst

- Board, Drag & Drop der Steine, Reihen/Spalten-Clear, Punkte, Combo/Fieber
- Daily Challenge, Missionen, Münzen, Themes wechseln
- Booster (Undo/Tausch/Bombe), Rätsel-Modus mit Sternen
- Statistik-Screen, Einstellungen (Sound/Vibration — Vibration wirkt im
  Browser nicht, der Schalter selbst funktioniert)

**Nicht testbar im Browser** (nur auf echtem Android/iOS-Gerätebuild):
Werbung, In-App-Käufe, Push-Benachrichtigungen, Haptik/Vibration.

## 6. Später: volles Testen mit allen Funktionen

- **Android**: Handy per USB anschließen, USB-Debugging aktivieren,
  `flutter run` erkennt es automatisch — dort funktioniert alles (auch Ads/IAP
  mit Test-IDs, Push, Vibration).
- **iPhone mit allen Funktionen**: braucht einen Mac mit Xcode
  (`flutter build ipa` bzw. `flutter run` mit angeschlossenem iPhone).
