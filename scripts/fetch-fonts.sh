#!/usr/bin/env bash
# Fetch the Vazirmatn font (SIL OFL) for Persian typography. Optional — the app
# falls back to the system font if these are absent.
set -euo pipefail

DEST="$(cd "$(dirname "$0")/.." && pwd)/App/Resources/Fonts"
BASE="https://github.com/rastikerdar/vazirmatn/raw/master/fonts/ttf"

echo "Downloading Vazirmatn into $DEST"
curl -fsSL "$BASE/Vazirmatn-Regular.ttf" -o "$DEST/Vazirmatn-Regular.ttf"
curl -fsSL "$BASE/Vazirmatn-Bold.ttf"    -o "$DEST/Vazirmatn-Bold.ttf"
echo "Done."
