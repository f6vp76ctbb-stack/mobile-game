# Asset-Credits & Lizenzen

Alle Assets sind entweder selbst erstellt oder CC0 (siehe CLAUDE.md).
Neue Assets hier mit Quelle und Lizenz eintragen.

## Audio (`assets/audio/`)

| Datei | Quelle | Lizenz |
|---|---|---|
| `place.wav` | Selbst synthetisiert (`scripts`-Generator, Sinus + Hüllkurve) | Eigenwerk / CC0 |
| `clear.wav` | Selbst synthetisiert | Eigenwerk / CC0 |
| `combo.wav` | Selbst synthetisiert | Eigenwerk / CC0 |
| `fever.wav` | Selbst synthetisiert | Eigenwerk / CC0 |
| `gameover.wav` | Selbst synthetisiert | Eigenwerk / CC0 |
| `music.wav` | Selbst synthetisiert (`scripts/gen_music.py`, Ambient-Loop aus Sinustönen) | Eigenwerk / CC0 |
| `levelup.wav` | Selbst synthetisiert (aufsteigendes C-Dur-Arpeggio) | Eigenwerk / CC0 |

Die WAV-Dateien wurden prozedural erzeugt (kurze, mono, 22050 Hz, 16-bit PCM
mit Attack/Release-Hüllkurve). Kein Fremdmaterial, damit keine Lizenzfragen.

## Grafik

Board, Teile und Effekte werden zur Laufzeit gezeichnet (CustomPaint) — keine
externen Grafik-Assets.

| Datei | Quelle | Lizenz |
|---|---|---|
| `assets/icon/icon.png` | Selbst erstellt (prozedural, Pillow) | Eigenwerk / CC0 |
| `assets/icon/icon_foreground.png` | Selbst erstellt (adaptiver Vordergrund) | Eigenwerk / CC0 |

Aus diesen Quellen generiert `flutter_launcher_icons` die Android-Mipmaps und
das iOS-AppIcon-Set.

## Schrift

| Datei | Quelle | Lizenz |
|---|---|---|
| `assets/fonts/Nunito.ttf` | Nunito (Vernon Adams, Cyreal, Jacques Le Bailly) via Google Fonts | SIL Open Font License 1.1 |

Nunito ist unter der **SIL OFL 1.1** frei nutzbar (auch kommerziell,
Einbettung erlaubt). Variable Schrift — eine Datei deckt alle Gewichte ab.
Lizenztext: https://openfontlicense.org
