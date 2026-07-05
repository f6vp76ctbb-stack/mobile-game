#!/usr/bin/env bash
# GridPop dev environment bootstrap.
# Installs the Flutter SDK (stable) into a cache dir and runs `flutter pub get`.
# Idempotent: safe to run on every session start. Used as the SessionStart hook.
set -euo pipefail

FLUTTER_CHANNEL="stable"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.flutter-sdk}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  log "Flutter not found — cloning $FLUTTER_CHANNEL into $FLUTTER_HOME"
  git clone --depth 1 -b "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
else
  log "Flutter already present at $FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

# Persist PATH for interactive shells in this environment.
if ! grep -qs 'flutter-sdk/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$FLUTTER_HOME/bin:\$PATH\"" >> "$HOME/.bashrc"
fi

log "Flutter version:"
flutter --version || true

# Precache Linux + web artifacts only (no Android/iOS toolchain needed for unit tests).
log "Precaching build artifacts (this may take a minute)…"
flutter precache --universal >/dev/null 2>&1 || true

if [ -f "$REPO_ROOT/pubspec.yaml" ]; then
  log "Running flutter pub get"
  (cd "$REPO_ROOT" && flutter pub get)
else
  log "No pubspec.yaml yet — skipping pub get (project not created)."
fi

log "Done. Add to PATH in new shells with:  export PATH=\"$FLUTTER_HOME/bin:\$PATH\""
