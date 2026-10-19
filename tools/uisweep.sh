#!/bin/bash
# Capture DEBUG demo hooks on a disposable simulator. Never touches a user's app data.
# tools/uisweep.sh [--no-build] [--screen NAME ...] | --list
# GT_SIM selects an available device name (default: iPhone 17).
# Default: capture large and AX5. GT_CONTENT_SIZE selects a single category instead.
# GT_APPEARANCE selects light or dark (default: dark).
# GT_LANGUAGE selects ko or en (default: ko).
# GT_BOLD_TEXT=1 turns on the system Bold Text setting before the app launches.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE=com.michaelju.glasstable
DEVICE_NAME="${GT_SIM:-iPhone 17}"
APPEARANCE="${GT_APPEARANCE:-dark}"
LANGUAGE="${GT_LANGUAGE:-ko}"
case "$LANGUAGE" in
  ko) LANGUAGE_PREFERENCE=korean ;;
  en) LANGUAGE_PREFERENCE=english ;;
  *) echo "unknown language: $LANGUAGE" >&2; exit 2 ;;
esac
case "$APPEARANCE" in
  light|dark) ;;
  *) echo "unknown appearance: $APPEARANCE" >&2; exit 2 ;;
esac
CONTENT_SIZES=(large accessibility-extra-extra-extra-large)
if [ -n "${GT_CONTENT_SIZE:-}" ]; then CONTENT_SIZES=("$GT_CONTENT_SIZE"); fi
for content_size in "${CONTENT_SIZES[@]}"; do
  case "$content_size" in
    extra-small|small|medium|large|extra-large|extra-extra-large|extra-extra-extra-large|accessibility-medium|accessibility-large|accessibility-extra-large|accessibility-extra-extra-large|accessibility-extra-extra-extra-large) ;;
    *) echo "unknown content size: $content_size" >&2; exit 2 ;;
  esac
done
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
  "learn:GT_DEMO_TAB=learn"
  "placement:GT_DEMO_PLACEMENT=1"
  "play:GT_DEMO_TAB=play"
  "play-open:GT_DEMO_TAB=play GT_DEMO_PLAY_OPEN=6"
  "play-setup:GT_DEMO_TAB=play GT_DEMO_PLAY_SETUP=1"
  "opponent-details:GT_DEMO_TAB=play GT_DEMO_PLAY_SETUP=1 GT_DEMO_OPPONENT=tag"
  "play-hand:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1"
  "play-hand-2:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_PLAYERS=2"
  "play-hand-3:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_PLAYERS=3"
  "play-motion-2:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_MOTION=deal-2 GT_DEMO_FREE_MOTION_FREEZE=1 GT_DEMO_FREE_MOTION_TIME=1250"
  "play-motion-3:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_MOTION=deal-3 GT_DEMO_FREE_MOTION_FREEZE=1 GT_DEMO_FREE_MOTION_TIME=1400"
  "play-motion-4:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_MOTION=deal-4 GT_DEMO_FREE_MOTION_FREEZE=1 GT_DEMO_FREE_MOTION_TIME=1500"
  "play-motion-refund:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_MOTION=refund GT_DEMO_FREE_MOTION_FREEZE=1 GT_DEMO_FREE_MOTION_START=refund GT_DEMO_FREE_MOTION_FRACTION=0.5"
  "play-motion-sidepots:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_MOTION=sidepots GT_DEMO_FREE_MOTION_FREEZE=1 GT_DEMO_FREE_MOTION_START=award GT_DEMO_FREE_MOTION_FRACTION=0.5"
  "play-motion-odd:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_MOTION=odd GT_DEMO_FREE_MOTION_FREEZE=1 GT_DEMO_FREE_MOTION_START=winners"
  "play-motion-rm:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_MOTION=sidepots GT_DEMO_FREE_MOTION_FREEZE=1 GT_DEMO_FREE_MOTION_START=award GT_DEMO_REDUCE_MOTION=1"
  "play-computer:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=computer"
  "play-dealing:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=dealing"
  "play-runout:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=runout"
  "play-all-in-call:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=all-in-call"
  "play-short-all-in:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=short-all-in"
  "play-result-all-in:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=result-all-in"
  "play-result:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=result"
  "play-raise:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-open"
  "play-raise-2:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_PLAYERS=2 GT_DEMO_FREE_PHASE=raise-open"
  "play-raise-3:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_PLAYERS=3 GT_DEMO_FREE_PHASE=raise-open"
  "play-raise-facing:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-facing"
  "play-raise-postflop:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-postflop"
  "play-raise-postflop-raise:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-postflop-raise"
  "play-raise-short-stack:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-short-stack"
  "play-math:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-open GT_DEMO_FREE_BACK=math"
  "play-math-2:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_PLAYERS=2 GT_DEMO_FREE_PHASE=raise-open GT_DEMO_FREE_BACK=math"
  "play-math-3:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_PLAYERS=3 GT_DEMO_FREE_PHASE=raise-open GT_DEMO_FREE_BACK=math"
  "play-math-flop:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-postflop GT_DEMO_FREE_BACK=math"
  "play-history:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-open GT_DEMO_FREE_BACK=hand"
  "play-rules:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=raise-open GT_DEMO_FREE_BACK=rules"
  "play-finished-hint:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=result-review GT_DEMO_FREE_BACK=hint"
  "play-review-river:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=result-review GT_DEMO_FREE_BACK=hand"
  "play-review:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_FREE_PHASE=result-all-in GT_DEMO_FREE_BACK=hand"
  "play-guide:GT_DEMO_TAB=play GT_DEMO_PRACTICE=1 GT_DEMO_PLAY_GUIDE=1"
  "first-lesson:GT_DEMO_FIRST_LESSON=welcome"
  "first-lesson-pot:GT_DEMO_FIRST_LESSON=pot"
  "first-lesson-blinds:GT_DEMO_FIRST_LESSON=blinds"
  "first-lesson-actions:GT_DEMO_FIRST_LESSON=actions"
  "first-lesson-flow:GT_DEMO_FIRST_LESSON=flow"
  "first-lesson-best:GT_DEMO_FIRST_LESSON=best"
  "first-lesson-example:GT_DEMO_FIRST_LESSON=example"
  "first-lesson-answer:GT_DEMO_FIRST_LESSON=example-answer"
  "first-lesson-wrong:GT_DEMO_FIRST_LESSON=example-wrong"
  "first-lesson-transfer:GT_DEMO_FIRST_LESSON=transfer"
  "first-lesson-transfer-answer:GT_DEMO_FIRST_LESSON=transfer-answer"
  "first-lesson-wrap-up:GT_DEMO_FIRST_LESSON=wrap-up"
  "basics:GT_DEMO_BASICS=ladder"
  "basics-check:GT_DEMO_BASICS=check"
  "basics-check-wrong:GT_DEMO_BASICS=check-wrong"
  "basics-kicker:GT_DEMO_BASICS=kicker"
  "basics-kicker-right:GT_DEMO_BASICS=kicker-right"
  "guided-invitation:GT_DEMO_GUIDED_INVITATION=1"
  "today-empty:GT_DEMO_TAB=today"
  "path-empty:GT_DEMO_TAB=path"
  "records-empty:GT_DEMO_TAB=records"
  "records-help-only:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=help-only"
  "records-helped:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=helped"
  "records-wrong:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=wrong"
  "records-four-days:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=four-days"
  "records-before-fourth:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=before-fourth"
  "records-sparse-future:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=sparse-future"
  "records-returning:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=returning"
  "records-mixed:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=mixed"
  "records-completed:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=completed"
  "progress-today:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=progress-today"
  "progress-large-count:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=progress-large-count"
  "progress-away:GT_DEMO_TAB=records GT_DEMO_ACTIVITY=progress-away"
  "today:GT_DEMO_SEED=1 GT_DEMO_TAB=today"
  "path:GT_DEMO_SEED=1 GT_DEMO_TAB=path"
  "records:GT_DEMO_SEED=1 GT_DEMO_TAB=records"
  "settings:GT_DEMO_SEED=1 GT_DEMO_SETTINGS=1"
  "settings-responsible:GT_DEMO_SEED=1 GT_DEMO_SETTINGS=1 GT_DEMO_RESPONSIBLE=1"
  "settings-reminder:GT_DEMO_SEED=1 GT_DEMO_SETTINGS=1 GT_DEMO_REMINDER=on"
  "settings-reminder-refused:GT_DEMO_SEED=1 GT_DEMO_SETTINGS=1 GT_DEMO_REMINDER=refused"
  "glossary:GT_DEMO_SEED=1 GT_DEMO_SETTINGS=1 GT_DEMO_GLOSSARY=1"
  "guide:GT_DEMO_SETTINGS=1 GT_DEMO_GUIDE=1"
  "guide-question:GT_DEMO_SETTINGS=1 GT_DEMO_GUIDE=1 GT_DEMO_GUIDE_PAGE=1"
  "freeplay:GT_DEMO_SEED=1 GT_DEMO_FREEPLAY=1"
  "review:GT_DEMO_SEED=1 GT_DEMO_REVIEW=1"
  "review-complete:GT_DEMO_SEED=1 GT_DEMO_REVIEW=1 GT_DEMO_REVIEW_COMPLETE=1"
  "lesson-complete:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds GT_DEMO_SESSION_COMPLETE=1"
  "lesson-milestone:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds GT_DEMO_SESSION_COMPLETE=1 GT_DEMO_MILESTONE=unit"
  "lesson-mastered:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds GT_DEMO_SESSION_COMPLETE=1 GT_DEMO_MILESTONE=mastered"
  "lesson-passed-hint:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-outs GT_DEMO_SESSION_COMPLETE=1 GT_DEMO_SESSION_MARKS=hrr"
  "lesson-not-passed:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-outs GT_DEMO_SESSION_COMPLETE=1 GT_DEMO_SESSION_MARKS=rww"
  "lesson-not-passed-again:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds GT_DEMO_SESSION_COMPLETE=1 GT_DEMO_SESSION_MARKS=rww"
  "guided-showdown:GT_DEMO_NODE=u1-showdown GT_DEMO_STAGE=together"
  "guided-potodds:GT_DEMO_NODE=u2-potOdds GT_DEMO_STAGE=together"
  "replay:GT_DEMO_SEED=1 GT_DEMO_REPLAY=potOdds"
  "drill-showdown:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-showdown"
  "drill-potmath:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-potMath GT_DEMO_POT_STATE=question"
  "step2-showdown:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-showdown.2"
  "step3-showdown:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-showdown.3"
  "step2-potmath:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-potMath.2 GT_DEMO_POT_STATE=question"
  "step3-potmath:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-potMath.3 GT_DEMO_POT_STATE=question"
  "step2-callfold:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-callFold.2"
  "step3-callfold:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-callFold.3"
  "step2-outs:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-outs.2"
  "step3-outs:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-outs.3"
  "step2-equity:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-equitySense.2"
  "step3-equity:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-equitySense.3"
  "step2-potodds:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds.2"
  "step3-potodds:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds.3"
  "step2-combos:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-combos.2"
  "step3-combos:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-combos.3"
  "step2-notation:GT_DEMO_SEED=1 GT_DEMO_NODE=u3-notation.2"
  "step3-notation:GT_DEMO_SEED=1 GT_DEMO_NODE=u3-notation.3"
  "step2-evcall:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-evCall.2"
  "step3-evcall:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-evCall.3"
  "step2-position:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-position.2"
  "step3-position:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-position.3"
  "step2-rfi:GT_DEMO_SEED=1 GT_DEMO_NODE=u3-rfi.2"
  "step3-rfi:GT_DEMO_SEED=1 GT_DEMO_NODE=u3-rfi.3"
  "step2-defend:GT_DEMO_SEED=1 GT_DEMO_NODE=u8-defend.2"
  "step3-defend:GT_DEMO_SEED=1 GT_DEMO_NODE=u8-defend.3"
  "step2-rangeread:GT_DEMO_SEED=1 GT_DEMO_NODE=u4-rangeRead.2"
  "step3-rangeread:GT_DEMO_SEED=1 GT_DEMO_NODE=u4-rangeRead.3"
  "step2-actionread:GT_DEMO_SEED=1 GT_DEMO_NODE=u7-actionRead.2"
  "step3-actionread:GT_DEMO_SEED=1 GT_DEMO_NODE=u7-actionRead.3"
  "potmath-intro:GT_DEMO_NODE=u1-potMath GT_DEMO_POT_STATE=intro:4"
  "potmath-three:GT_DEMO_NODE=u1-potMath GT_DEMO_POT_STATE=question GT_DEMO_POT_PLAYERS=3:4"
  "potmath-four:GT_DEMO_NODE=u1-potMath GT_DEMO_POT_STATE=question GT_DEMO_POT_PLAYERS=4:4"
  "potmath-reveal:GT_DEMO_NODE=u1-potMath GT_DEMO_POT_STATE=reveal GT_DEMO_POT_PLAYERS=4:4"
  "potmath-totals-confirm:GT_DEMO_NODE=u1-potMath GT_DEMO_POT_STATE=question GT_DEMO_POT_PLAYERS=4 GT_DEMO_POT_TOTALS=confirm:4"
  "potmath-totals:GT_DEMO_NODE=u1-potMath GT_DEMO_POT_STATE=question GT_DEMO_POT_PLAYERS=4 GT_DEMO_POT_TOTALS=shown:4"
  "explain-position:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-position GT_DEMO_EXPLAIN=1"
  "explain-potodds:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds GT_DEMO_EXPLAIN=1"
  "teach-potodds-check:GT_DEMO_NODE=u2-potOdds GT_DEMO_BEAT=3"
  "drill-position:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-position"
  "drill-combos:GT_DEMO_SEED=1 GT_DEMO_NODE=u1-combos"
  "drill-potodds:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-potOdds"
  "drill-mdf:GT_DEMO_NODE=u9-mdf"
  "drill-outs:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-outs"
  "drill-outs-reveal:GT_DEMO_NODE=u2-outs GT_DEMO_OUTS_SPOT=24500:4 GT_DEMO_REVEAL=15"
  "drill-equity:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-equitySense"
  "drill-ev:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-evCall"
  "teach-evcall-zero:GT_DEMO_NODE=u2-evCall GT_DEMO_BEAT=0"
  "drill-callfold:GT_DEMO_CONCEPT=callFold"
  "lesson-callfold:GT_DEMO_SEED=1 GT_DEMO_NODE=u2-callFold"
  "drill-notation:GT_DEMO_SEED=1 GT_DEMO_NODE=u3-notation"
  "drill-rfi:GT_DEMO_SEED=1 GT_DEMO_NODE=u3-rfi"
  "drill-rangeread:GT_DEMO_SEED=1 GT_DEMO_NODE=u4-rangeRead"
  # The reveal is the two-channel comparison grid: fill = truth, ring = your guess.
  # 18 lands close, 60 lands badly wrong — both bands need looking at.
  "drill-rangeread-close:GT_DEMO_SEED=1 GT_DEMO_NODE=u4-rangeRead GT_DEMO_REVEAL=18"
  "drill-rangeread-off:GT_DEMO_SEED=1 GT_DEMO_NODE=u4-rangeRead GT_DEMO_REVEAL=60"
  "teach-showdown-b0:GT_DEMO_NODE=u1-showdown GT_DEMO_BEAT=0"
  "teach-showdown-b1:GT_DEMO_NODE=u1-showdown GT_DEMO_BEAT=1"
  "teach-showdown-b3:GT_DEMO_NODE=u1-showdown GT_DEMO_BEAT=3"
  "teach-combos-define:GT_DEMO_NODE=u1-combos GT_DEMO_BEAT=0"
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
  "drill-evloss:GT_DEMO_SEED=1 GT_DEMO_NODE=u6-evLoss:8"
  "drill-evloss-call:GT_DEMO_SEED=1 GT_DEMO_NODE=u6-evLoss GT_DEMO_REVEAL=1:8"
  "drill-evloss-fold:GT_DEMO_SEED=1 GT_DEMO_NODE=u6-evLoss GT_DEMO_REVEAL=0:8"
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
  "table-policy:GT_DEMO_TABLE=tag GT_DEMO_TABLE_POLICY=1"
  "table-preflop-grade:GT_DEMO_TABLE=tag GT_DEMO_TABLE_STEP=1:6"
  "table-chart:GT_DEMO_TABLE=tag GT_DEMO_TABLE_STEP=1 GT_DEMO_TABLE_CHART=1:6"
  "table-bet-sizes:GT_DEMO_TABLE=station GT_DEMO_TABLE_STEP=1 GT_DEMO_TABLE_CONTINUE=1 GT_DEMO_TABLE_SIZES=1:12"
  "table-check:GT_DEMO_TABLE=station GT_DEMO_TABLE_STEP=1 GT_DEMO_TABLE_CONTINUE=1:12"
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

# CoreSimulator can stall on first boot or leave a launch pending before a process
# exists. Bound those waits; a failed command must not leave an unattended sweep hung.
run_with_timeout() {
  python3 - "$@" <<'PYTIMEOUT'
import subprocess, sys
try:
    sys.exit(subprocess.run(sys.argv[2:], timeout=int(sys.argv[1])).returncode)
except subprocess.TimeoutExpired:
    print('Timed out: ' + ' '.join(sys.argv[2:]), file=sys.stderr)
    sys.exit(124)
PYTIMEOUT
}

restart_device() {
  xcrun simctl shutdown "$DEV" >>"$OUT/simulator.log" 2>&1
  xcrun simctl boot "$DEV" >>"$OUT/simulator.log" 2>&1
  run_with_timeout 120 xcrun simctl bootstatus "$DEV" -b >>"$OUT/simulator.log" 2>&1
  xcrun simctl ui "$DEV" appearance "$APPEARANCE" >>"$OUT/simulator.log" 2>&1
}

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
devices_by_runtime = json.load(open(sys.argv[1]))['devices']
for runtime, devices in sorted(devices_by_runtime.items(),
        key=lambda item: tuple(map(int, item[0].split('-')[1:])), reverse=True):
    for d in devices:
        if d['name'] == sys.argv[2]:
            print(d['deviceTypeIdentifier'], runtime)
            sys.exit(0)
print('No available simulator named ' + sys.argv[2], file=sys.stderr)
sys.exit(1)
PYDEVICE
)
DEV=$(xcrun simctl create "GlassTable sweep $(basename "$OUT")" "$TYPE" "$RUNTIME")
echo "Starting disposable simulator; logs and captures: $OUT"
printf 'device=%s\nruntime=%s\nsource=%s\n' "$DEV" "$RUNTIME" "$fingerprint" >"$OUT/run.txt"
printf 'content_size=%s\n' "${CONTENT_SIZES[@]}" >>"$OUT/run.txt"
printf 'appearance=%s\n' "$APPEARANCE" >>"$OUT/run.txt"
printf 'language=%s\ninitial_language_preference=%s\n' "$LANGUAGE" "$LANGUAGE_PREFERENCE" >>"$OUT/run.txt"
printf 'bold_text=%s\n' "${GT_BOLD_TEXT:-0}" >>"$OUT/run.txt"
xcrun simctl boot "$DEV" >>"$OUT/simulator.log" 2>&1
if ! run_with_timeout 120 xcrun simctl bootstatus "$DEV" -b >>"$OUT/simulator.log" 2>&1; then
  echo "First boot stalled; restarting the disposable device once."
  restart_device
fi

xcrun simctl ui "$DEV" appearance "$APPEARANCE" >>"$OUT/simulator.log" 2>&1
if [ "${GT_BOLD_TEXT:-0}" = 1 ]; then
  xcrun simctl spawn "$DEV" defaults write com.apple.Accessibility EnhancedTextLegibilityEnabled -bool YES >>"$OUT/simulator.log" 2>&1
fi
xcrun simctl status_bar "$DEV" override --time '9:41' --batteryState charged --batteryLevel 100 >>"$OUT/simulator.log" 2>&1
# First-boot system announcements can cover the first app frame.
sleep 8

for content_size in "${CONTENT_SIZES[@]}"; do
  capture_dir="$OUT/$content_size"
  mkdir -p "$capture_dir"
  xcrun simctl ui "$DEV" content_size "$content_size" >>"$OUT/simulator.log" 2>&1
  for entry in "${SCREENS[@]}"; do
    name="${entry%%:*}"
    rest="${entry#*:}"
    slp="${rest##*:}"
    if [[ "$slp" =~ ^[0-9.]+$ ]]; then envs="${rest%:*}"; else envs="$rest"; slp=${GT_CAPTURE_DELAY:-8}; fi
    args=("SIMCTL_CHILD_GT_DEMO_LANGUAGE=$LANGUAGE" "SIMCTL_CHILD_GT_TEST_STORE_ID=$(uuidgen)")
    for kv in $envs; do args+=("SIMCTL_CHILD_$kv"); done
    # Uninstall clears progress written by the preceding demo. Empty-state captures
    # remain empty regardless of the requested order.
    if [ -f "$OUT/installed" ]; then
      xcrun simctl uninstall "$DEV" "$BUNDLE" >>"$OUT/simulator.log" 2>&1
    fi
    xcrun simctl install "$DEV" "$APP" >>"$OUT/simulator.log" 2>&1
    touch "$OUT/installed"
    if ! run_with_timeout 60 env "${args[@]}" xcrun simctl launch "$DEV" "$BUNDLE" -glassTable.language "$LANGUAGE_PREFERENCE" >>"$capture_dir/$name.log" 2>&1; then
      echo "Launch failed for $name; restarting the disposable device once."
      restart_device
      xcrun simctl ui "$DEV" content_size "$content_size" >>"$OUT/simulator.log" 2>&1
      run_with_timeout 60 env "${args[@]}" xcrun simctl launch "$DEV" "$BUNDLE" -glassTable.language "$LANGUAGE_PREFERENCE" >>"$capture_dir/$name.log" 2>&1
    fi
    sleep "$slp"
    xcrun simctl io "$DEV" screenshot "$capture_dir/$name.png" >>"$capture_dir/$name.log" 2>&1
    echo "$content_size/$name" | tee -a "$OUT/captured.txt"
  done
done
rm "$OUT/installed"
echo "$OUT"
