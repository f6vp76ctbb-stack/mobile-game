# App bauen ohne Computer (GitHub-Auto-Build)

Baut die signierte Play-Store-Datei (`.aab`) direkt auf GitHub — du brauchst
**keinen** Rechner mit Flutter, nur einen Browser. Workflow:
`.github/workflows/build-release.yaml`.

## Einmalig: 4 Signatur-Geheimnisse (+ 1 optionales) hinterlegen

GitHub → dein Repo `f6vp76ctbb-stack/mobile-game` → **Settings** →
**Secrets and variables** → **Actions** → **New repository secret**. Lege
diese an (Name exakt so):

| Secret-Name | Wert |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | der lange base64-Text aus der Datei `qubble-upload.jks.b64` (alles markieren + einfügen) |
| `ANDROID_KEYSTORE_PASSWORD` | das Store-Passwort (bekommst du von Claude) |
| `ANDROID_KEY_PASSWORD` | das Key-Passwort (bekommst du von Claude) |
| `ANDROID_KEY_ALIAS` | `upload` |
| `GOOGLE_SERVICES_JSON` *(optional)* | kompletter Inhalt deiner `google-services.json` (für Firebase im Release) |

> **Wichtig:** Bewahre die Schlüssel-Datei (`qubble-upload.jks`) und die beiden
> Passwörter sicher auf (z. B. Passwort-Manager). Mit dieser Datei werden alle
> App-Updates signiert. Falls sie verloren geht: Bei **Play App Signing**
> (unten) kann Google den Upload-Schlüssel zurücksetzen — also kein Weltuntergang,
> aber Backup ist besser.

## Bauen (jedes Mal, wenn du eine neue Datei brauchst)

1. GitHub → Tab **Actions** → links **„Build Android Release (.aab)"**
2. Rechts **„Run workflow"** → **„Run workflow"** (grüner Knopf)
3. ~5–10 Minuten warten, bis der Lauf grün ist
4. Den Lauf öffnen → unten unter **„Artifacts"** → **`qubble-release-aab`**
   herunterladen → darin liegt `app-release.aab`

## Diese Datei in die Play Console

- Play Console → deine App → **Test** (z. B. Geschlossener Test) oder
  **Produktion** → **Neue Version erstellen** → `.aab` hochladen.
- Beim ersten Upload fragt Google nach **Play App Signing** → **aktivieren**
  (empfohlen). Google verwaltet dann den finalen Signaturschlüssel; unser
  Keystore ist nur der Upload-Schlüssel.
- Versionscode: Bei jeder neuen `.aab` muss `version:` in `pubspec.yaml` erhöht
  werden (der Teil nach `+`). Sag Claude Bescheid, dann zählt er hoch.

## Wenn der Build fehlschlägt

Öffne den roten Lauf → das Log zeigt den Fehler. Häufig:
- Ein Secret fehlt/vertippt → oben erscheint „ANDROID_KEYSTORE_BASE64 secret
  is not set".
- Schick Claude die letzten Zeilen des Logs, dann fixt er es.
