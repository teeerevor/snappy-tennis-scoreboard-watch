#!/usr/bin/env bash
#
# Runs the UI screenshot tour and exports the screenshots for review into
# build/screenshots/<device>/, with a contact sheet at build/screenshots/index.html.
#
# By default it tours the Watch App on three Apple Watch sizes (one per score font size).
# With --companion it tours the Companion App on an iPhone and an iPad instead,
# into build/screenshots/companion/.
#
# Usage: scripts/screenshots.sh [--companion] [device name ...]

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="snappy-tennis-scoreboard.xcodeproj"

if [ "${1:-}" = "--companion" ]; then
    shift
    PLATFORM="iOS"
    SCHEME="Snappy Tennis Scoreboard"
    TESTS="Snappy Tennis ScoreboardUITests/ScreenshotTourTests"
    OUT="build/screenshots/companion"
    TITLE="Companion App screenshots"
    IMAGE_WIDTH=240
    DEFAULT_DEVICES=("iPhone 17 Pro" "iPad Pro 11-inch (M5)")
else
    PLATFORM="watchOS"
    SCHEME="snappy-tennis-scoreboard Watch App"
    TESTS="snappy-tennis-scoreboard Watch AppUITests/ScreenshotTourTests"
    OUT="build/screenshots"
    TITLE="Watch screenshots"
    IMAGE_WIDTH=200
    DEFAULT_DEVICES=(
        "Apple Watch Series 9 (41mm)"
        "Apple Watch Series 11 (42mm)"
        "Apple Watch Ultra 3 (49mm)"
    )
fi

if [ $# -gt 0 ]; then
    DEVICES=("$@")
else
    DEVICES=("${DEFAULT_DEVICES[@]}")
fi

# Newest installed runtime for the platform, used when a simulator has to be created
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
platform = sys.argv[1]
runtimes = [r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == platform and r["isAvailable"]]
print(sorted(runtimes, key=lambda r: [int(p) for p in r["version"].split(".")])[-1]["identifier"])
' "$PLATFORM")

# Prints the id of the simulator with this name on $RUNTIME, creating it if needed
simulator_id() {
    local name="$1"
    local id
    id=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
name, runtime = sys.argv[1], sys.argv[2]
devices = json.load(sys.stdin)["devices"].get(runtime, [])
print(next((d["udid"] for d in devices if d["name"] == name), ""))
' "$name" "$RUNTIME")
    if [ -z "$id" ]; then
        local type
        type=$(xcrun simctl list devicetypes -j | python3 -c '
import json, sys
name = sys.argv[1]
print(next(t["identifier"] for t in json.load(sys.stdin)["devicetypes"] if t["name"] == name))
' "$name")
        echo "Creating simulator: $name" >&2
        id=$(xcrun simctl create "$name" "$type" "$RUNTIME")
    fi
    echo "$id"
}

# Keep the other app's screenshots: the Companion App's live inside the Watch App's folder
if [ "$PLATFORM" = "watchOS" ]; then
    find "$OUT" -mindepth 1 -maxdepth 1 ! -name companion -exec rm -rf {} + 2>/dev/null || true
else
    rm -rf "$OUT"
fi
mkdir -p "$OUT"

for device in "${DEVICES[@]}"; do
    id=$(simulator_id "$device")
    slug=$(echo "$device" | tr -cs '[:alnum:]' '-' | sed 's/-$//')
    result="$OUT/$slug.xcresult"

    echo "==> $device"
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=$PLATFORM Simulator,id=$id" \
        -only-testing:"$TESTS" \
        -parallel-testing-enabled NO \
        -resultBundlePath "$result" \
        -quiet || echo "!! Some tests failed on $device (screenshots taken so far are still exported)"

    raw="$OUT/$slug/raw"
    mkdir -p "$raw"
    xcrun xcresulttool export attachments --path "$result" --output-path "$raw" > /dev/null

    # Rename exported files to their attachment names, e.g. 07-match-result.png
    python3 - "$raw" "$OUT/$slug" <<'PY'
import json, os, re, shutil, sys
raw, dest = sys.argv[1], sys.argv[2]
with open(os.path.join(raw, "manifest.json")) as f:
    manifest = json.load(f)
for test in manifest:
    for attachment in test.get("attachments", []):
        name = attachment.get("suggestedHumanReadableName", attachment["exportedFileName"])
        name = re.sub(r"_\d+_[0-9A-Fa-f-]{36}(?=\.\w+$)", "", name)
        if not re.match(r"\d\d", name):
            continue  # Xcode's own failure attachments; see the .xcresult for those
        shutil.copy(os.path.join(raw, attachment["exportedFileName"]), os.path.join(dest, name))
shutil.rmtree(raw)
PY
done

# Contact sheet: one row per screenshot, one column per device
python3 - "$OUT" "$TITLE" "$IMAGE_WIDTH" <<'PY'
import html, os, sys
out, title, image_width = sys.argv[1], sys.argv[2], sys.argv[3]
devices = sorted(
    d for d in os.listdir(out)
    if os.path.isdir(os.path.join(out, d)) and not d.endswith(".xcresult") and d != "companion"
)
shots = sorted({f for d in devices for f in os.listdir(os.path.join(out, d)) if f.endswith(".png")})
rows = []
for shot in shots:
    cells = "".join(
        f'<td><img src="{html.escape(d)}/{html.escape(shot)}" loading="lazy"></td>'
        if os.path.exists(os.path.join(out, d, shot)) else "<td>missing</td>"
        for d in devices
    )
    rows.append(f"<tr><th>{html.escape(shot[:-4])}</th>{cells}</tr>")
header = "".join(f"<th>{html.escape(d)}</th>" for d in devices)
with open(os.path.join(out, "index.html"), "w") as f:
    f.write(f"""<!doctype html>
<meta charset="utf-8">
<title>{html.escape(title)}</title>
<style>
  body {{ font-family: -apple-system, sans-serif; background: #111; color: #eee; margin: 16px; }}
  table {{ border-collapse: collapse; }}
  th, td {{ padding: 8px; vertical-align: top; text-align: left; }}
  img {{ width: {image_width}px; border-radius: 24px; }}
</style>
<table><tr><th></th>{header}</tr>{''.join(rows)}</table>
""")
print(f"Contact sheet: {os.path.join(out, 'index.html')}")
PY
