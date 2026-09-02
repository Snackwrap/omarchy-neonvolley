#!/usr/bin/env bash
# Capture the popup, one PNG per scene, for the marketplace listing assets.
#
# Uses debugPreviewScene to freeze menu / mid-match / game-over layouts, and
# debugGeometry so the panel reports its screen rect to the journal (the popup
# lives in a fullscreen layer — grim cannot discover it otherwise).
#
# Run tools/build-preview.sh afterward for preview.png.
#
# Usage:  tools/capture-preview.sh [menu play gameover]   (default: all three)
set -euo pipefail

ID="com.leafbox.neonvolley"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTDIR="$ROOT/assets/tabs"

SCENES=("$@")
[ ${#SCENES[@]} -eq 0 ] && SCENES=(menu play gameover)

mkdir -p "$OUTDIR"

read_setting() {
  python3 - "$1" <<'PYEOF'
import json, os, sys
try:
    cfg = json.load(open(os.path.expanduser("~/.config/omarchy/shell.json")))
except Exception:
    sys.exit()
for slot in cfg.get("bar", {}).get("layout", {}).values():
    for w in slot:
        if w.get("id") == "com.leafbox.neonvolley" and sys.argv[1] in w:
            print(w[sys.argv[1]])
PYEOF
}

restore_scene=$(read_setting debugPreviewScene)
restore_geom=$(read_setting debugGeometry)

hyprctl dispatch 'hl.dsp.cursor.move({x=4,y=796})' >/dev/null 2>&1 \
  || hyprctl dispatch movecursor 4 796 >/dev/null 2>&1 || true
sleep 1.5

omarchy bar set "$ID" debugGeometry true

for scene in "${SCENES[@]}"; do
  omarchy bar set "$ID" debugPreviewScene "$scene"
  sleep 0.6
  omarchy restart shell
  sleep 4.5

  omarchy-shell shell summon "$ID"
  sleep 2.5

  geom=$(journalctl --user --since "12 seconds ago" --no-pager 2>/dev/null \
         | grep -oE 'NEON_VOLLEY_GEOMETRY [0-9-]+ [0-9-]+ [0-9]+ [0-9]+' | tail -1 || true)
  if [ -z "$geom" ]; then
    echo "!! $scene: the panel did not report its geometry, skipping" >&2
    omarchy-shell shell hide "$ID" 2>/dev/null || true
    continue
  fi

  read -r _ x y w h <<<"$geom"
  grim -g "${x},${y} ${w}x${h}" "$OUTDIR/$scene.png"
  omarchy-shell shell hide "$ID" 2>/dev/null || true
  echo "   $scene -> assets/tabs/$scene.png ($(magick identify -format '%wx%h' "$OUTDIR/$scene.png"))"
done

omarchy bar set "$ID" debugPreviewScene "${restore_scene:-off}"
omarchy bar set "$ID" debugGeometry "${restore_geom:-false}"
omarchy restart shell
echo "Done. Now run tools/build-preview.sh to compose preview.png."
