# Agent handoff

## Through 2026-09-30 — condensed 2026-10-01

Full detail: [the 10-01 archive](handoff-archive/2026-10-01-before-direction-a.md), which retains the earlier archive links and all historical entries.

- Shipped through 09-30: combined beginner release and four-tab navigation; lessons,
  answer reveals, accessibility/Bold Text, floating sheets and spacing rules;
  first-run guide and Hold'em basics; policy-details, Range Read, locked-choice and
  Position-order audit fixes; initial full-screen free table with replay and help.
- Open human/release checks: physical VoiceOver, minimum iOS 17, novice comprehension,
  signed Store/distribution validation, screenshots, age rating/territories,
  very-large-history save latency, and system permission/notification/share/review
  flows remain unverified. Enrolment, counsel and submission remain owner work;
  support/privacy pages are now queued after Direction A.
- Runtime gaps: iOS 17–18 attached sheets compile but were not observed; the iOS 27
  watchdog fix removed UIKit window reads from ActionSheet.body and needs the
  affected phone checked after install. The known AX walkthrough failure on one
  iPhone 16e simulator was not investigated; CI passed on its device. Live Bold Text
  changes reach views that redraw; reopening makes them consistent without resetting
  a hand. Shared table dimensions remain a readability tradeoff.
- Copy/audit checks: KO.wordJoined does not cover literal Text or Button/Label titles;
  recheck the reported Position intro leaks before calling them resolved. EV-loss
  range-grid labels remain about 6 pt; backup export/import is unverified. Empty
  practice-change content was a fixture artifact. Scrolled-audit screen-wide findings
  remain unexplained. The uncommitted crawler's Play steps predate the full-screen
  free table; preserve tools/uxaudit/, UXAuditCrawl.swift and .scratch/uxaudit-codex/.
- Device reset backup: .build/device-backups/20260924-before-reset/; restore by copying
  its files back. Do not reset phone progress otherwise. Archive ignored evidence
  before removing worktrees; proposal evidence is .build/archive/glass-table-proposal-uisweep.
  .scratch/pot-calculation-redesign/ remains intentionally untracked and unrelated.

## 2026-10-01 — Direction A early checkpoints, condensed

Full exploration, step1 candidate/approval and step2 pause details remain in
[the early-checkpoint archive](handoff-archive/2026-10-01-direction-a-early-checkpoints.md).

- Created feat/free-table-direction-a from 33e5384; step 0 is 6dc95b6 and step 1
  spacing is 22bb963. No push. The delivery spec supersedes all exploration pages.
- Step 1 passed 61 app units, 19 UI checks and 394 Drills tests. Dock visible normal
  top/left/right/bottom: 25.67/21.67/20.33/20.33 → 20.33/21.67/20/20 pt;
  AX5 bottom 64 → 20 pt. Title ink retains normal 1.67/AX 3.33 pt glyph bearings.
- Owner approved wrapping exact AX titles and native corners with 0.765 pt minimum
  clearance exception. Recorded in spec §13; no custom corner curve.
- Owner paused during step 2, then resumed; source/evidence survived. The old
  50-minute target expired with that pause. Current verified step 2 entry follows.
- Outs/Math level 2 and fast-table remain deferred. Support work stays strictly
  after Direction A. Engine, progression, settings and excluded audit paths remain
  outside scope. Physical haptics, VoiceOver and older-runtime checks remain open.

## 2026-10-01 — Direction A steps 2–4, condensed 2026-10-02

Full entries: [steps 2–4 archive](handoff-archive/2026-10-02-direction-a-steps-2-to-4.md).

- Step2 a52b094: paper hero, clockwise seats,8pt felt edges, fixed36/43pt cards.
  Revised AX scroll proof excludes chrome-covered names; six KO/EN2/3/4 seat
  checks pass. Seat heights differ by at most0.667pt; physical readability remains
  a tradeoff. Step3 dd348cb: three fixed slots, public replay prices, warnings,
  Skip×3 and stable tallest-face dock. Full all-face sizing later passesStep5.
- Step4 3f6b61b: gold commit, presets, one-chip native press/hold, limit dimming
  without haptic, AX amount/preset scrolling. Real pan-from-key bug fixed;8 unique
  UI methods passed. Normal dock315pt; amount top20.333/control left20.667/right20/
  bottom20.333pt; native corner exception stays within approved tolerance.
- Builds/units/Drills and inspected KO/ENlarge/AX gates passed for each step.
  Commands, every failed attempt, measurements and captures: .build/direction-a/
  step2/report.md, step3/report.md, step4/report.md. Rejected cold EN landing
  captures were replaced with identified warm/native evidence; no product cold
  launch fix claimed. Step5 restores Rules reopening and verifies all dock faces.
- Physical haptics/VoiceOver/older runtimes remain unverified. No Engine/
  progression/new saved setting/excluded audit-path edits or push. Outs and fast
  table remain deferred; support/privacy/Pages work follows Direction A.

## 2026-10-02 — Direction A step 5 verified

- Step 4 committed as 3f6b61b. Step 5 replaces help/guide sheets with the fixed
  flipping dock back: Math, This hand and Rules; inactive fronts unmount. First-use
  seen semantics remain. Math uses public shown cards, capped contestable pot and
  refund-adjusted cost; approved Drills best-hand correction supports flop/turn.
  Historical decision rows use only automatically disclosed heads-up opponents
  and each decision's board prefix; manual reveal cannot enable chance.
- Owner approved N dots in two columns and intrinsic AX Math scrolling. AX tabs
  also scroll as a routine layout adaptation. Cached close-symbol alpha cropping
  preserves all ink; explicit back-body clipping fixes actual paint overflow.
  Normal dock stays315pt; tab top20.333/left20.667pt, AX close top/left20pt.
  Short Math retains122.333pt bottom blank space under the fixed tallest-face rule;
  do not claim equal visible-ink insets for that short face.
- Generic build passes. Drills363 XCTest+35 Swift Testing pass; full app61+20
  pass, then focused9 pass including the added symbol test. Native all-face height,
  complete AX controls, actual review, first-use/resume and manual reveal gates
  pass. Final cream-copy overlap passes EN26.273s/KO21.958s; root inspected all
  portions. KO/EN2/3/4-player large/AX5 Math/back screenshots checked. Rejected
  demo landing/black frames are replaced by identified warm/native captures.
- Exact commands, verbatim failed attempts, inspected paths, measurements and
  verification limits: .build/direction-a/step5/report.md and sibling artifacts.
  Astra approved frozen semantic module hashes; serial cache cancellation has
  source/UI proof, no dedicated queued-cancellation unit. iOS27 visual execution
  only; physical haptics/VoiceOver and older runtimes remain unverified.
- Older early checkpoints condensed with full text retained in
  docs/handoff-archive/2026-10-01-direction-a-early-checkpoints.md. Next: step6
  supervised public replay/motion/haptics, then7–8; support work remains last.
  No Engine/progression/new saved setting/excluded audit edits or push.

## 2026-10-02 — Direction A step 6 verified

- Step5 committed5513364. Step6 adds app-local typed public replay, integer chip
  projection, real seat/pot/card flights, public runout/refunds/reverse side-pot
  payouts/odd chips, winner5pt lift and next-hand clear/refill/dealer/deal. One
  supervised clock freezes on background and resumes exact cursor/cues; shown
  actions/cards drive Facts/history and settlement unlocks only after visual pay.
- SwiftUI sensoryFeedback replaces UIKit generators with the specified meanings,
  highest-priority collision choice and150ms wall-time spacing. Same-hand RM
  changes preserve completed/active phase timings; renderer suppresses motion
  immediately, future phases use new timing. Old-clear cards retain provenance.
- Astra reviewed successive fixes and approved current core hashes. Root visual
  inspection caught detached winner edges then stale final front bet piles; both
  fixed, including next-hand clear. Settled frame has0pot/transit/front bets.
- Generic build passes. Drills363XCTest+35Swift pass; app61XCTest+37Swift pass.
  Round3 native9methods pass, followup2public-control methods pass, and final
  settlement/caption gate12pure+3UI pass; finalclear16pure+2UI pass. Exact commands and every failed attempt
  verbatim are retained in .build/direction-a/step6/report.md and siblings.
- Root inspected KO/EN2/3/4large/AX motion matrix, actual recorded blind/deal/
  runout/refund/award phases, all6 settled endpoints and full scrolled AX named
  pot+Total captions. Native winning edge+card translate15px=5pt at3x; outer
  felt8pt, board center0.167pt offset. Runout face-on intervals average597.1ms
  at approximate70ms recording tolerance; source timings not all observed exactly.
- Physical haptics, VoiceOver and older-runtime visuals remain unverified. Native
  XCTest/recorded evidence substitutes for unavailable GUI. No Engine/Drills/
  progression/new saved setting/excluded audit edits or push. Next7app-wide,
  then8full verification; support/email/privacy/Pages work strictly afterward.

## 2026-10-02 — Direction A step 7 verified

- App-wide inset/radius and first-font corrections, spade backs, cream selected
  Position/RFI, PotMath outline/fill, action-name 벳 and three graded action slots.
  Checked-to Bet retains all five legal choices; actual saved-answer resume retains
  IDs/payloads. Step6 dealer follow-up now samples SwiftUI Spring(response0.4,
  damping1) on the paused replay clock; independent and native checks pass.
- Generic build, Drills363XCTest+35Swift, frozen app61XCTest+38Swift and6UI pass.
  Separate graded11UI, restoration4UI and spring13pure+2UI gates pass. One build
  failure (.title18) corrected to .title(18); all failures verbatim and commands
  retained in .build/direction-a/step7/report.md and siblings.
- Root/worker/scout reviewed KOlight and ENdark136 scenes each at large/AX5:
  540 accepted original frames plus4 root-inspected ENAX replacements. Original
  landing/black frames retained as rejected evidence; capture exit0 alone was
  insufficient. Warm replacements retain original arguments; unseeded PotMath3
  generated-question identity is not established. No product cold-launch fix.
- Measured title18.667→16pt, graded normal87pt frames, Position contrast13.402:1.
  Mixed-font/glyph residual about1pt and centered shape-first labels qualified;
  debug river review proves public-prefix content, not settled chip piles.
- Frozen source fingerprint b4e1aea94cc08f5bbd459cfa718670806c644434c55032e828ab6bcfe08334ff.
  No Engine/progression/new saved setting/excluded audit edits or push. Next8
  full tracked suite plus exact RangeRead/Settings/Basics scroll reach. Physical
  haptics/VoiceOver/older runtimes remain unverified; support task remains last.

## 2026-10-02 — Direction A step 8 complete

- Added real RangeRead KO/EN large/AX5 comparison/last-row/Next outcomes, bilingual
  AX Basics navigation and complete Settings Version label/value reach checks.
  Updated stale hidden-card/action selectors; scrolling helpers use gutters and
  bounded slow drags. Product sources remain identical to Step7 fingerprint.
- Generic build and Drills398 pass; app units99 pass. Full UI123/134 initially
  passed; affected13/17 then final6/6 passed. All134 unique tracked methods now
  have passing outcomes with failure history preserved, not one green full run.
  See docs/verification/2026-10-02-free-table-direction-a.md and companion ledger.
- Accepted544 sweep slots plus focused native evidence; root inspected final17
  back-face,22 seat/rotation and2 Version PNGs. AX paragraphs require scrolling;
  one-pixel native frame allowance and debug-review settlement limits documented.
- All Steps0–8 committed locally without push. Engine/progression/settings and
  excluded audits untouched; Math outs/fast-table deferred. Owner phone haptics,
  VoiceOver and older-runtime checks remain.14 retained 베팅 strings listed in
  report. Next: queued support email/privacy/support-page task, publish separately
  without pushing the redesign branch. No email/App Store/Notion actions.
