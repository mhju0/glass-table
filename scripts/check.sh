#!/usr/bin/env bash
# Gate: runs the checks PR CI runs (.github/workflows/ci.yml jobs unit, focused-ui, release).
# Usage: scripts/check.sh [--fast] [--part unit|focused-ui|release]
#   --fast   simulator-free checks only (screenshot tool tests, Drills package tests)
#   --part   only the checks of that CI job; no args runs every part
# Locally, simulator parts need GATE_SIMULATOR_UDID (a dedicated "Audit ..." simulator).
set -euo pipefail
cd "$(dirname "$0")/.."

fast=0
part=""
while [ $# -gt 0 ]; do
  case "$1" in
    --fast) fast=1 ;;
    --part) part="${2:-}"; [ -n "$part" ] || { echo "--part needs a name" >&2; exit 2; }; shift ;;
    *) echo "usage: scripts/check.sh [--fast] [--part unit|focused-ui|release]" >&2; exit 2 ;;
  esac
  shift
done
case "$part" in ""|unit|focused-ui|release) ;; *) echo "unknown part: $part" >&2; exit 2 ;; esac

trap 'rc=$?; [ "$rc" -eq 0 ] || echo "GATE: FAIL"' EXIT

in_ci() { [ "${CI:-}" = "true" ] || [ "${GITHUB_ACTIONS:-}" = "true" ]; }

need_local_simulator() {
  if [ -z "${GATE_SIMULATOR_UDID:-}" ]; then
    echo "Locally this part needs GATE_SIMULATOR_UDID. Create a dedicated \"Audit ...\" simulator and pass its UDID; never use your own simulators." >&2
    exit 1
  fi
}

# Any iPhone simulator (CI selection logic) or the local dedicated one.
first_iphone() {
  if in_ci; then
    xcrun simctl list devices available -j | python3 -c 'import json, sys; print(next(d["udid"] for devices in json.load(sys.stdin)["devices"].values() for d in devices if d["name"].startswith("iPhone")))'
  else
    need_local_simulator
    echo "$GATE_SIMULATOR_UDID"
  fi
}

run_fast_checks() {
  python3 -m unittest discover -s tools/tests
  swift test --package-path GlassTableDrills
}

part_unit() {
  run_fast_checks
  # Testing builds the app as well; a separate Debug build repeats that work.
  test_simulator=$(first_iphone)
  xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
    -destination "platform=iOS Simulator,id=$test_simulator" \
    -only-testing:GlassTableTests CODE_SIGNING_ALLOWED=NO test > app-tests.log 2>&1 || { cat app-tests.log; exit 1; }
  tail -30 app-tests.log
}

part_focused_ui() {
  if in_ci; then
    TEST_DEVICE="${TEST_DEVICE:-iPhone 17}"
    TEST_RUNTIME="${TEST_RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-26-2}"
    export TEST_DEVICE TEST_RUNTIME
    test_simulator=$(xcrun simctl list devices available -j | python3 -c '
import json, os, sys
devices = json.load(sys.stdin)["devices"].get(os.environ["TEST_RUNTIME"], [])
print(next((d["udid"] for d in devices if d["name"] == os.environ["TEST_DEVICE"]), ""))')
    if [ -z "$test_simulator" ]; then
      echo "::error::No available '$TEST_DEVICE' simulator on $TEST_RUNTIME. Installed:"
      xcrun simctl list devices available
      exit 1
    fi
    echo "Testing on $TEST_DEVICE ($TEST_RUNTIME) $test_simulator"
  else
    need_local_simulator
    test_simulator="$GATE_SIMULATOR_UDID"
  fi
  xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
    -destination "platform=iOS Simulator,id=$test_simulator" \
    -only-testing:GlassTableUITests/GradedTableRecoveryFlowTests \
    -only-testing:GlassTableUITests/ReviewTeachingFollowupTests \
    -only-testing:GlassTableUITests/FreeRaiseFlowTests/testOneChipTapHoldLimitsCancelAndOddCommit \
    -only-testing:GlassTableUITests/FreeRaiseFlowTests/testRaiseAXPanFromAdjustmentCancelsStepAndScrolls \
    -only-testing:GlassTableUITests/FreeRaiseFlowTests/testDraggingAwayAfterRepeatStopsAndLowerLimitHolds \
    -only-testing:GlassTableUITests/FreeRaiseFlowTests/testBackgroundAndReopeningDoNotReviveReleasedRepeat \
    -only-testing:GlassTableUITests/FreeDockFlowTests/testFixedSlotsCancelPressAndPreserveHeightThroughRaiseAndFold \
    -only-testing:GlassTableUITests/NavigationChromeTests/testEnglishLightNavigationControls \
    -only-testing:GlassTableUITests/NavigationChromeTests/testKoreanDarkAXNavigationControls \
    -only-testing:GlassTableUITests/LearningFlowTests/testLessonTitleStartsJustUnderTheCloseChevronOnTheContentEdge \
    -only-testing:GlassTableUITests/GradedLearningFlowTests/testAXPostflopChartIsExplicitlyAStartingHandReference \
    -only-testing:GlassTableUITests/BeginnerReleaseTests/testLegacyTerminologyPreferencesUseOneLearningPolicy \
    -only-testing:GlassTableUITests/TerminologyLearningFlowTests/testKoreanAXComparisonKeepsBothSeatIdentitiesAfterRestore \
    -only-testing:GlassTableUITests/LearningReferenceFlowTests \
    -resultBundlePath focused-ui.xcresult \
    CODE_SIGNING_ALLOWED=NO test > focused-ui.log 2>&1 || { tail -100 focused-ui.log; exit 1; }
  tail -30 focused-ui.log
}

part_release() {
  test_simulator=$(first_iphone)
  xcodebuild -project GlassTable.xcodeproj -scheme GlassTableReleaseSmoke \
    -configuration Release -destination "platform=iOS Simulator,id=$test_simulator" \
    -derivedDataPath .build/ci-release-smoke -only-testing:GlassTableUITests/ReleaseSmokeTests \
    ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO test > release-smoke.log 2>&1 || { tail -100 release-smoke.log; exit 1; }
  tail -30 release-smoke.log
  xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
    -configuration Release -destination 'generic/platform=iOS' \
    -derivedDataPath .build/ci-release CODE_SIGNING_ALLOWED=NO build > release-build.log 2>&1 || { tail -100 release-build.log; exit 1; }
  python3 tools/verify_release.py .build/ci-release/Build/Products/Release-iphoneos/GlassTable.app
}

if [ "$fast" -eq 1 ]; then
  run_fast_checks
else
  case "$part" in
    unit) part_unit ;;
    focused-ui) part_focused_ui ;;
    release) part_release ;;
    "") part_unit; part_focused_ui; part_release ;;
  esac
fi

echo "GATE: PASS"
