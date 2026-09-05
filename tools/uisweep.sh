#!/bin/bash
# Capture DEBUG demo hooks on a disposable simulator. Never touches a user's app data.
# tools/uisweep.sh [--no-build] [--screen NAME ...] | --list
# GT_SIM selects an available device name (default: iPhone 17).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE=com.michaelju.glasstable
DEVICE_NAME="${GT_SIM:-iPhone 17}"
BUILD=1
LIST=0
SELECTED=()
while [ $# -gt 0 ]; do
  case "$1" in
    --no-build) BUILD=0 ;;
    --list) LIST=1 ;;
    --screen)
      [ $# -ge 2 ] || { echo "--screen needs a name" >&2; exit 2; }
      SELECTED+=("$2"); shift ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

SCREENS=(
  "today-empty:GT_DEMO_TAB=today"
  "path-empty:GT_DEMO_TAB=path"
  "records-empty:GT_DEMO_TAB=records"
  "today:GT_DEMO_SEED=1 GT_DEMO_TAB=today"
  "path:GT_DEMO_SEED=1 GT_DEMO_TAB=path"
  "records:GT_DEMO_SEED=1 GT_DEMO_TAB=records"
  "settings:GT_DEMO_SEED=1 GT_DEMO_SETTINGS=1"
  "glossary:GT_DEMO_SEED=1 GT_DEMO_SETTINGS=1 GT_DEMO_GLOSSARY=1"
  "freeplay:GT_DEMO_SEED=1 GT_DEMO_FREEPLAY=1"
  "review:GT_DEMO_SEED=1 GT_DEMO_REVIEW=1"
  "replay:GT_DEMO_SEED=1 GT_DEMO_REPLAY=potOdds"
  "drill-showdown:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-showdown"
  "drill-potmath:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-potMath"
  "drill-position:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-position"
  "drill-combos:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-combos"
  "drill-potodds:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds"
  "drill-outs:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-outs"
  "drill-equity:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-equitySense"
  "drill-ev:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-evCall"
  "drill-callfold:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-boss"
  "drill-notation:GT_DEMO_SEED=1 GT_DEMO_NODE=u3-notation"
  "drill-rfi:GT_DEMO_SEED=1 GT_DEMO_NODE=u3-rfi"
  "drill-rangeread:GT_DEMO_SEED=1 GT_DEMO_NODE=u4-rangeRead"
  # The reveal is the two-channel comparison grid: fill = truth, ring = your guess.
  # 18 lands close, 60 lands badly wrong — both bands need looking at.
  "drill-rangeread-close:GT_DEMO_SEED=1 GT_DEMO_NODE=u4-rangeRead GT_DEMO_REVEAL=18"
  "drill-rangeread-off:GT_DEMO_SEED=1 GT_DEMO_NODE=u4-rangeRead GT_DEMO_REVEAL=60"
  "teach-showdown-b1:GT_DEMO_NODE=u1-showdown GT_DEMO_BEAT=1"
  "teach-showdown-b3:GT_DEMO_NODE=u1-showdown GT_DEMO_BEAT=3"
  "teach-showdown-b5:GT_DEMO_NODE=u1-showdown GT_DEMO_BEAT=5"
  "teach-outs-grid:GT_DEMO_NODE=u2-outs GT_DEMO_BEAT=4"
  "teach-rfi-grid:GT_DEMO_NODE=u3-rfi GT_DEMO_BEAT=3"
  "teach-notation:GT_DEMO_NODE=u3-notation GT_DEMO_BEAT=2"
  "teach-rangeread-stats:GT_DEMO_NODE=u4-rangeRead GT_DEMO_BEAT=2"
  "teach-rangeread-grid:GT_DEMO_NODE=u4-rangeRead GT_DEMO_BEAT=4"
  "drill-hitfreq:GT_DEMO_SEED=1 GT_DEMO_NODE=u5-hitFrequency"
  "drill-hitfreq-reveal:GT_DEMO_SEED=1 GT_DEMO_NODE=u5-hitFrequency GT_DEMO_REVEAL=40"
  "drill-rangeadv:GT_DEMO_SEED=1 GT_DEMO_NODE=u5-rangeAdvantage"
  "drill-rangeadv-reveal:GT_DEMO_SEED=1 GT_DEMO_NODE=u5-rangeAdvantage GT_DEMO_REVEAL=55"
  # The stacked bucket bars are the whole lesson of both board drills.
  "teach-hitfreq-buckets:GT_DEMO_NODE=u5-hitFrequency GT_DEMO_BEAT=3"
  "teach-rangeadv-buckets:GT_DEMO_NODE=u5-rangeAdvantage GT_DEMO_BEAT=3"
  # R4-S2. Both sides of the reveal, because the headline differs: one of these is a
  # 0bb choice and the other is what it cost to take the other one.
  "drill-evloss:GT_DEMO_SEED=1 GT_DEMO_NODE=u6-evLoss"
  "drill-evloss-call:GT_DEMO_SEED=1 GT_DEMO_NODE=u6-evLoss GT_DEMO_REVEAL=1"
  "drill-evloss-fold:GT_DEMO_SEED=1 GT_DEMO_NODE=u6-evLoss GT_DEMO_REVEAL=0"
  "teach-evloss-range:GT_DEMO_NODE=u6-evLoss GT_DEMO_BEAT=1"
  "teach-evloss-cost:GT_DEMO_NODE=u6-evLoss GT_DEMO_BEAT=5"
  # R4-S3. The reveal swaps the grid for before/after bars — both states need looking
  # at, plus the rule beat (the policy table) and the bars beat in the walkthrough.
  "drill-actionread:GT_DEMO_SEED=1 GT_DEMO_NODE=u7-actionRead"
  "drill-actionread-reveal:GT_DEMO_SEED=1 GT_DEMO_NODE=u7-actionRead GT_DEMO_REVEAL=60"
  "teach-actionread-rule:GT_DEMO_NODE=u7-actionRead GT_DEMO_BEAT=2"
  # R5b. GT_DEMO_REVEAL: 0 폴드, 1 콜, 2 3벳 — the reveal's chart is the payload.
  "drill-defend:GT_DEMO_SEED=1 GT_DEMO_NODE=u8-defend"
  "drill-defend-reveal:GT_DEMO_SEED=1 GT_DEMO_NODE=u8-defend GT_DEMO_REVEAL=1"
  "teach-defend-chart:GT_DEMO_NODE=u8-defend GT_DEMO_BEAT=3"
  "teach-actionread-bars:GT_DEMO_NODE=u7-actionRead GT_DEMO_BEAT=4"
  # R4-S4. Scripted passive steps drive the seeded hand to a grade pill and, with
  # enough of them, the summary. Flop pricing is seconds in a debug build, so these
  # entries carry their own longer sleep (third field).
  "table-picker:GT_DEMO_TAB=table"
  # R5: the hand now opens at the preflop decision — chart-graded, no pricing wait.
  "table-preflop:GT_DEMO_TABLE=tag"
  "table-preflop-grade:GT_DEMO_TABLE=tag GT_DEMO_TABLE_STEP=1:6"
  "table-chart:GT_DEMO_TABLE=tag GT_DEMO_TABLE_STEP=1 GT_DEMO_TABLE_CHART=1:6"
  "table-hand:GT_DEMO_TABLE=tag GT_DEMO_TABLE_STEP=1 GT_DEMO_TABLE_CONTINUE=1:12"
  "table-grade:GT_DEMO_TABLE=tag GT_DEMO_TABLE_STEP=2:14"
  "table-summary:GT_DEMO_TABLE=tag GT_DEMO_TABLE_STEP=10:24"
)

if [ "$LIST" = 1 ]; then
  for entry in "${SCREENS[@]}"; do echo "${entry%%:*}"; done
  exit 0
fi
if [ ${#SELECTED[@]} -gt 0 ]; then
  captures=()
  for selected in "${SELECTED[@]}"; do
    found=0
    for entry in "${SCREENS[@]}"; do
      if [ "${entry%%:*}" = "$selected" ]; then captures+=("$entry"); found=1; break; fi
    done
    [ "$found" = 1 ] || { echo "unknown screen: $selected (see --list)" >&2; exit 2; }
  done
  SCREENS=("${captures[@]}")
fi

mkdir -p "$ROOT/.uisweep"
OUT=$(mktemp -d "$ROOT/.uisweep/$(date +%Y%m%d-%H%M%S)-XXXXXX")
DERIVED="$ROOT/.build/uisweep"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/GlassTable.app"
DEV=""
cleanup() {
  if [ -n "$DEV" ]; then
    xcrun simctl shutdown "$DEV" >>"$OUT/simulator.log" 2>&1 || true
    xcrun simctl delete "$DEV" >>"$OUT/simulator.log" 2>&1 || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'echo "Sweep failed; logs: $OUT" >&2' ERR

# A local artifact and content fingerprint prevent stale screenshots after edits or
# when several checkouts have generated apps with the same scheme name.
fingerprint=$(python3 - "$ROOT" <<'PYHASH'
import hashlib, pathlib, sys
root = pathlib.Path(sys.argv[1])
files = [root / 'project.yml']
for package in ('GlassTableEngine', 'GlassTableDrills'):
    files.append(root / package / 'Package.swift')
for folder in ('GlassTable/Sources', 'GlassTable/Resources',
               'GlassTableEngine/Sources', 'GlassTableDrills/Sources'):
    files.extend(p for p in (root / folder).rglob('*') if p.is_file())
h = hashlib.sha256()
for p in sorted(files):
    h.update(str(p.relative_to(root)).encode() + b'\0' + p.read_bytes())
print(h.hexdigest())
PYHASH
)
xcodebuild -version >"$OUT/xcode.txt"
fingerprint="$fingerprint $(shasum -a 256 "$OUT/xcode.txt" | cut -d' ' -f1)"
if [ "$BUILD" = 1 ]; then
  echo "Building; log: $OUT/build.log"
  (cd "$ROOT" && xcodegen generate) >"$OUT/build.log" 2>&1
  xcodebuild -project "$ROOT/GlassTable.xcodeproj" -scheme GlassTable \
    -configuration Debug -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO build >>"$OUT/build.log" 2>&1
  echo "$fingerprint" >"$DERIVED/source-fingerprint"
else
  if [ ! -d "$APP" ] || [ ! -f "$DERIVED/source-fingerprint" ] || \
     [ "$(cat "$DERIVED/source-fingerprint")" != "$fingerprint" ]; then
    echo "No matching sweep build for this source/Xcode. Run tools/uisweep.sh without --no-build." >&2
    exit 1
  fi
fi

# Clone only the device configuration, not its installed apps or data.
xcrun simctl list devices available -j >"$OUT/devices.json"
read -r TYPE RUNTIME < <(python3 - "$OUT/devices.json" "$DEVICE_NAME" <<'PYDEVICE'
import json, sys
for runtime, devices in reversed(list(json.load(open(sys.argv[1]))['devices'].items())):
    for d in devices:
        if d['name'] == sys.argv[2]:
            print(d['deviceTypeIdentifier'], runtime)
            sys.exit(0)
print('No available simulator named ' + sys.argv[2], file=sys.stderr)
sys.exit(1)
PYDEVICE
)
DEV=$(xcrun simctl create "GlassTable sweep $(basename "$OUT")" "$TYPE" "$RUNTIME")
printf 'device=%s\nruntime=%s\nsource=%s\n' "$DEV" "$RUNTIME" "$fingerprint" >"$OUT/run.txt"
xcrun simctl boot "$DEV" >>"$OUT/simulator.log" 2>&1
xcrun simctl bootstatus "$DEV" -b >>"$OUT/simulator.log" 2>&1

for entry in "${SCREENS[@]}"; do
  name="${entry%%:*}"
  rest="${entry#*:}"
  slp="${rest##*:}"
  if [[ "$slp" =~ ^[0-9.]+$ ]]; then envs="${rest%:*}"; else envs="$rest"; slp=2.2; fi
  args=()
  for kv in $envs; do args+=("SIMCTL_CHILD_$kv"); done
  # Uninstall clears progress written by the preceding demo. Empty-state captures
  # remain empty regardless of the requested order.
  if [ -f "$OUT/installed" ]; then
    xcrun simctl uninstall "$DEV" "$BUNDLE" >>"$OUT/simulator.log" 2>&1
  fi
  xcrun simctl install "$DEV" "$APP" >>"$OUT/simulator.log" 2>&1
  touch "$OUT/installed"
  env "${args[@]}" xcrun simctl launch "$DEV" "$BUNDLE" >>"$OUT/$name.log" 2>&1
  sleep "$slp"
  xcrun simctl io "$DEV" screenshot "$OUT/$name.png" >>"$OUT/$name.log" 2>&1
  echo "$name" | tee -a "$OUT/captured.txt"
done
rm "$OUT/installed"
echo "$OUT"
