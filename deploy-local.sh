#!/usr/bin/env bash
# Symlink this repo into the Omarchy plugins dir for live development, then
# validate it. Editing files here updates the running shell after a restart.
set -euo pipefail

ID="com.leafbox.neonvolley"
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/omarchy/plugins/$ID"

# Drop legacy plugin symlink if present.
LEGACY="$HOME/.config/omarchy/plugins/com.leafbox.vbtennis"
[[ -L "$LEGACY" ]] && rm "$LEGACY"

if [[ -e "$DEST" && ! -L "$DEST" ]]; then
  echo "Refusing to overwrite $DEST (exists and is not a symlink)." >&2
  exit 1
fi

ln -sfn "$SRC" "$DEST"
echo "Linked $DEST -> $SRC"

omarchy plugin validate "$SRC" || true

cat <<EOF

Next steps:
  omarchy plugin disable com.leafbox.vbtennis 2>/dev/null || true
  omarchy plugin enable $ID right
  omarchy restart shell

Remove with:
  omarchy plugin disable $ID
  rm "$DEST"
EOF
