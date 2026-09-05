#!/usr/bin/env bash
# Downloads all 206 recorded Albo screens from ScreensDesign into docs/albo/screens/.
# Requires network access to media.screensdesign.com. Run from the repo root:
#   bash scripts/fetch-albo-screens.sh
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=docs/albo/screens
mkdir -p "$OUT"
jq -r '.[] | "\(.position)\t\(.image_url)"' docs/albo/screens.json | while IFS=$'\t' read -r pos url; do
  file=$(printf "%s/%03d.png" "$OUT" "$pos")
  if [ -s "$file" ]; then continue; fi
  curl -fsSL --retry 3 -o "$file" "$url" && echo "saved $file" || echo "FAILED $pos $url" >&2
done
echo "done: $(ls "$OUT" | wc -l) files in $OUT"
