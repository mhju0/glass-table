#!/bin/bash
# Copyright (c) 2026 Michael Ju (github.com/mhju0)
#
# Capture every significant screen, in both appearances, into one folder.
#
# The point is to make *looking at the app* cheap enough to do after every UI
# change. Synthetic taps never reach Simulator content, so each screen is reached
# by a GT_DEMO_* launch hook instead of by driving the UI — see RootView.
#
#   tools/uisweep.sh              # build, install, sweep to a timestamped folder
#   tools/uisweep.sh --no-build   # reuse the current build
#   tools/uisweep.sh --dark-only
#
# Every capture is a fresh launch, so screens never leak state into each other.
set -euo pipefail

BUNDLE=com.michaelju.glasstable
SCHEME=GlassTable
DEVICE_NAME="${GT_SIM:-iPhone 17}"
BUILD=1
APPEARANCES=(light dark)

while [ $# -gt 0 ]; do
  case "$1" in
    --no-build) BUILD=0 ;;
    --dark-only) APPEARANCES=(dark) ;;
    --light-only) APPEARANCES=(light) ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/.uisweep/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

DEV=$(xcrun simctl list devices available \
      | grep "$DEVICE_NAME (" | head -1 \
      | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$DEV" ] || { echo "no available simulator named '$DEVICE_NAME'" >&2; exit 1; }

if [ "$BUILD" = 1 ]; then
  echo "building…"
  xcodebuild -project "$ROOT/GlassTable.xcodeproj" -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$DEV" CODE_SIGNING_ALLOWED=NO build \
    2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
fi

APP=$(find ~/Library/Developer/Xcode/DerivedData/GlassTable-*/Build/Products/Debug-iphonesimulator \
      -maxdepth 1 -name "$SCHEME.app" 2>/dev/null | head -1)
[ -n "$APP" ] || { echo "no built .app found" >&2; exit 1; }

xcrun simctl boot "$DEV" 2>/dev/null || true
xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1 || true
xcrun simctl install "$DEV" "$APP"

# name : GT_DEMO env, space separated. Seeded runs show a populated app; the
# unseeded ones are what a brand-new user actually sees, which is the state
# most easily broken and least often looked at.
SCREENS=(
  "today-empty:GT_DEMO_TAB=today"
  "path-empty:GT_DEMO_TAB=path"
  "records-empty:GT_DEMO_TAB=records"
  "today:GT_DEMO_SEED=1 GT_DEMO_TAB=today"
  "path:GT_DEMO_SEED=1 GT_DEMO_TAB=path"
  "records:GT_DEMO_SEED=1 GT_DEMO_TAB=records"
  "settings:GT_DEMO_SEED=1 GT_DEMO_SETTINGS=1"
  "freeplay:GT_DEMO_SEED=1 GT_DEMO_FREEPLAY=1"
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
)

for mode in "${APPEARANCES[@]}"; do
  xcrun simctl ui "$DEV" appearance "$mode" >/dev/null 2>&1 || true
  mkdir -p "$OUT/$mode"
  for entry in "${SCREENS[@]}"; do
    name="${entry%%:*}"
    envs="${entry#*:}"
    args=()
    for kv in $envs; do args+=("SIMCTL_CHILD_$kv"); done
    xcrun simctl terminate "$DEV" "$BUNDLE" >/dev/null 2>&1 || true
    env "${args[@]}" xcrun simctl launch "$DEV" "$BUNDLE" >/dev/null 2>&1 || true
    sleep 2.2
    xcrun simctl io "$DEV" screenshot "$OUT/$mode/$name.png" >/dev/null 2>&1 || true
    printf '.'
  done
  echo " $mode"
done

xcrun simctl terminate "$DEV" "$BUNDLE" >/dev/null 2>&1 || true
echo "$OUT"
