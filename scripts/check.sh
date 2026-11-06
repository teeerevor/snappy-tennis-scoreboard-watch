#!/usr/bin/env bash
#
# Checks everything is in a state to commit: the TennisScoring package tests, the Companion App
# (which builds the Watch App inside it) and the Watch App's unit tests.
# The screenshot tours are left to scripts/screenshots.sh, as they take several minutes.
#
# Usage: scripts/check.sh
# Set WATCH_SIMULATOR to run the Watch App's unit tests on a different simulator.

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="snappy-tennis-scoreboard.xcodeproj"
WATCH_SIMULATOR="${WATCH_SIMULATOR:-Apple Watch Series 11 (42mm)}"

echo "==> TennisScoring package tests"
(cd Packages/TennisScoring && swift test --quiet)

echo "==> Companion App and Watch App build"
xcodebuild build \
    -project "$PROJECT" \
    -scheme "Snappy Tennis Scoreboard" \
    -destination "generic/platform=iOS Simulator" \
    -quiet

echo "==> Watch App unit tests"
# By id: the same name can exist on several watchOS versions, and inside an iPhone pairing
WATCH_ID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
runtimes = json.load(sys.stdin)["devices"]
watchos = sorted(
    (r for r in runtimes if ".watchOS-" in r),
    key=lambda r: [int(p) for p in r.rsplit("watchOS-", 1)[1].split("-")],
)
print(next((d["udid"] for r in reversed(watchos) for d in runtimes[r] if d["name"] == name), ""))
' "$WATCH_SIMULATOR")
if [ -z "$WATCH_ID" ]; then
    echo "No simulator named \"$WATCH_SIMULATOR\". Set WATCH_SIMULATOR to one from: xcrun simctl list devices" >&2
    exit 1
fi
xcodebuild test \
    -project "$PROJECT" \
    -scheme "snappy-tennis-scoreboard Watch App" \
    -destination "platform=watchOS Simulator,id=$WATCH_ID" \
    -only-testing:"snappy-tennis-scoreboard Watch AppTests" \
    -quiet

echo "All checks passed"
