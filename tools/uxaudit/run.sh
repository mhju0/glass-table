#!/bin/bash
# Runs the UX audit crawl (GlassTable/UITests/UXAuditCrawl.swift) on one simulator.
#   tools/uxaudit/run.sh <simulator-udid> <out-dir> <test> [<test> ...]
# Tests are UXAuditCrawl method names (test01FirstRun, test10Unit1, ...).
# Build first: xcodebuild build-for-testing ... -derivedDataPath .build/uxaudit
set -euo pipefail
cd "$(dirname "$0")/../.."
sim=$1; out=$2; shift 2
mkdir -p "$out" .build/uxaudit-results
xcrun simctl boot "$sim" 2>/dev/null || true
xcrun simctl bootstatus "$sim" -b >/dev/null
xcrun simctl ui "$sim" appearance light
xcrun simctl status_bar "$sim" override --time 9:41 --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
# Settings flows persist in UserDefaults, which the per-launch test store does not reset.
for key in appAppearance reminder.enabled reminder.minutes glassTable.language; do
  xcrun simctl spawn "$sim" defaults delete com.michaelju.glasstable "$key" 2>/dev/null || true
done
only=()
for t in "$@"; do only+=("-only-testing:GlassTableUITests/UXAuditCrawl/$t"); done
bundle=".build/uxaudit-results/$(date +%H%M%S)-$sim.xcresult"
TEST_RUNNER_GT_AUDIT_OUT="$(cd "$out" && pwd)" \
TEST_RUNNER_GT_AUDIT_NODES="${GT_AUDIT_NODES:-}" \
xcodebuild test-without-building -project GlassTable.xcodeproj -scheme GlassTable \
  -destination "platform=iOS Simulator,id=$sim" -derivedDataPath "${GT_AUDIT_DD:-.build/uxaudit}" \
  "${only[@]}" -resultBundlePath "$bundle" 2>&1 | grep -E "Test Case|error|Executed|SUCCEEDED|FAILED" || true
