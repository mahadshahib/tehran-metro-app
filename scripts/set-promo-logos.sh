#!/usr/bin/env bash
# Install the Muvi and Cheetah logos into the asset catalog.
# Usage: ./scripts/set-promo-logos.sh path/to/muvi.png path/to/cheetah.png
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/App/Resources/Assets.xcassets"

install_logo() {  # $1 = source png, $2 = imageset name
  local src="$1" name="$2" dir="$ASSETS/$2.imageset"
  cp "$src" "$dir/$name.png"
  cat > "$dir/Contents.json" <<JSON
{
  "images" : [
    { "idiom" : "universal", "filename" : "$name.png", "scale" : "1x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "preserves-vector-representation" : false }
}
JSON
  echo "Installed $name from $src"
}

install_logo "$1" MuviLogo
install_logo "$2" CheetahLogo
echo "Done. Run 'xcodegen generate' (if needed) and rebuild."
