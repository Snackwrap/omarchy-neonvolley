#!/usr/bin/env bash
# Compose preview.png (the marketplace listing card) from assets/tabs/*.png.
#
# Run tools/capture-preview.sh first to refresh the scene captures.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 tools/build-preview.py
chromium --headless --disable-gpu --hide-scrollbars \
         --window-size=1600,1000 --screenshot="$ROOT/preview.png" \
         "file://$ROOT/tools/promo.html" >/dev/null 2>&1
magick "$ROOT/preview.png" -strip "$ROOT/preview.png"
echo "preview.png -> $(magick identify -format '%wx%h %b' "$ROOT/preview.png")"
