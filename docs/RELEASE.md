# Release- & Build-Checkliste

Reihenfolge für einen sauberen (Soft-)Launch. 👤 = nur der Mensch kann es tun.
Voraussetzung: die Konten-Schritte aus `docs/SETUP-ACCOUNTS.md` (inkl. der
steuerlichen Punkte in Abschnitt 0).

> **Play Store zuerst.** Abschnitt 3 (iOS) ist *(später/optional)* — überspringe
> ihn beim ersten Launch. Alles andere gilt für den Android-Release.

## 0. Vor dem Release im Code prüfen

- [ ] 👤 Echte AdMob-IDs eingetragen (`lib/monetization/ad_config.dart` +
      `AndroidManifest.xml` + `Info.plist`) — sonst laufen im Release die
      `REPLACE_ME`-Platzhalter ins Leere. Debug nutzt weiter Test-IDs.
- [ ] 👤 IAP-Produkte in beiden Konsolen mit den IDs aus `lib/monetization/iap.dart`.
- [ ] 👤 Firebase-Config-Dateien vorhanden (`android/app/google-services.json`,
      `ios/Runner/GoogleService-Info.plist`) → dann Firebase-Backend anbinden.
- [ ] Versionsnummer in `pubspec.yaml` erhöhen (`version: 1.0.0+1` → z. B. `1.0.1+2`;
      der Teil nach `+` ist der Build-/Versionscode und muss je Upload steigen).
- [ ] `flutter analyze` und `flutter test` grün (CI prüft das bei jedem Push).

## 1. Android – Signing (einmalig)

1. 👤 Upload-Keystore erzeugen (sicher verwahren, **niemals** committen):
   ```bash
   keytool -genkey -v -keystore ~/gridpop-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. 👤 `android/key.properties` anlegen (Vorlage: `android/key.properties.example`)
   mit Passwörtern, Alias und Pfad zur `.jks`. Die Datei ist bereits
   git-ignored; ohne sie baut das Projekt weiter mit Debug-Keys.
3. Prüfen: `flutter build appbundle` signiert dann mit dem Upload-Key.

> Empfehlung: In der Play Console **Play App Signing** aktivieren — Google
> verwaltet den finalen Signing-Key, du lädst nur mit dem Upload-Key hoch.

## 2. Android – Build

```bash
flutter build appbundle        # -> build/app/outputs/bundle/release/app-release.aab
# optional zum lokalen Testen:
flutter build apk --release
```

Optional Code-Shrinking (kleinere App): in `android/app/build.gradle.kts`
`isMinifyEnabled`/`isShrinkResources` auf `true` setzen (Keep-Regeln liegen in
`proguard-rules.pro`) und **einen Release-Build testen**, bevor du hochlädst.

## 3. iOS – Build  *(später/optional – beim Play-first-Launch überspringen)*

1. 👤 In Xcode (`ios/Runner.xcworkspace`) unter *Signing & Capabilities* dein
   Team wählen; Bundle-ID muss zu App Store Connect passen.
2. Build:
   ```bash
   flutter build ipa            # -> build/ios/ipa/*.ipa
   ```
3. 👤 Upload via Xcode Organizer oder Transporter zu App Store Connect.

## 4. Screenshots (jetzt möglich, da Build läuft)

1. App auf Emulator/Gerät starten: `flutter run --release`.
2. Die 6 Screens aus `docs/STORE-LISTING.md` aufnehmen (Combo-Fieber lohnt sich
   im richtigen Moment). Für einen glühenden Fieber-Screen mehrere Reihen in
   Folge räumen.
3. In Rahmen + Text setzen (z. B. Paket `screenshots`, oder manuell) mit den dort
   hinterlegten DE/EN-Captions.

## 5. Store-Einträge (👤)

- ASO-Texte aus `docs/STORE-LISTING.md`, Icon ist bereits gesetzt.
- Datenschutz-URL (aus `docs/PRIVACY-POLICY.md`, gehostet) eintragen.
- Impressum-URL (aus `docs/IMPRESSUM.md`, gehostet) eintragen und in der App
  hinterlegen (Einstellungen → Impressum).
- Datensicherheit-Formular + Altersfreigabe in der Play Console ausfüllen.

## 6. Soft Launch (Phase 4)

- Zuerst **nur Play Store**, 1–2 kleine Märkte (z. B. Niederlande/Skandinavien).
- KPIs beobachten (siehe MASTERPLAN.md): D1/D7-Retention, Session-Länge,
  Rewarded-Engagement, Crash-freie-Rate > 99,5 %.
- Erst tunen (Fairness-Generator, Ad-Frequenz), dann global ausrollen.

## 7. Letzter Check vor „Veröffentlichen"

- [ ] Release-Build startet, spielbar, keine Debug-Banner.
- [ ] Echte Ads laden im Release (Test-Gerät als AdMob-Testgerät registrieren,
      um nicht auf Live-Ads zu klicken).
- [ ] Unterstützer-Paket liefert Aurora-Theme + Kristall-Skin + 1.500 Münzen
      + ❤️; „Wiederherstellen" funktioniert.
- [ ] Absturz-frei in einer 10-Minuten-Session.
