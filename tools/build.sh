#!/usr/bin/env bash
# Build Yogi and print only what went wrong.
#   ./tools/build.sh          simulator build (fastest, skips signing)
#   ./tools/build.sh device   device build (also checks signing)
set -uo pipefail
cd "$(dirname "$0")/../ios/Yogi" || exit 1

[ "${1:-sim}" = "device" ] && DEST='generic/platform=iOS' || DEST='generic/platform=iOS Simulator'

echo "Building Yogi for ${DEST}..."
LOG=$(mktemp)
xcodebuild -project Yogi.xcodeproj -scheme Yogi -destination "$DEST" build > "$LOG" 2>&1
STATUS=$?

if [ $STATUS -eq 0 ]; then
  echo "BUILD SUCCEEDED"
else
  echo
  echo "===== ERRORS ($(grep -c 'error:' "$LOG") total) ====="
  grep -E "error:" "$LOG" | sed 's|.*/ios/Yogi/||' | sort -u
  echo
  echo "===== WARNINGS (first 15) ====="
  grep -E "warning:" "$LOG" | sed 's|.*/ios/Yogi/||' | sort -u | head -15
  echo
  echo "Full log: $LOG"
fi
exit $STATUS
