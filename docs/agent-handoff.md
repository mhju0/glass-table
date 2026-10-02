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

## 2026-10-01 17:24 KST — Direction A resumed, step 2 verified

- Resumed on the same branch with local changes preserved. Step 2 now passes its
  builds and Drills (363 XCTest + 31 Swift Testing), 61 app unit tests, nine existing
  selected UI checks, six KO/EN 2/3/4-player AX5 seat/portrait checks, and one bilingual
  status-height check. No app changes were needed after the paused screenshots.
- The first aggregate scroll test failed: fixed drags overshot KO4 C2 and its viewport
  bounds also allowed chrome-covered names. Reject that proof. Six bounded tests now
  use the actual title's bottom and measured slow drags; all pass, with 22 inspected
  attachments in `.build/direction-a/step2/native-final/`. Style-to-winner seat height
  is unchanged in both languages. Empty/other seat heights differ by up to 0.667 pt.
- Final 2/3/4 KO/EN large/AX5 sweep images and legacy freeplay/Pot Math images were
  inspected. Felt margins measure 8/8 pt; cards measure 26×36 and 31×43 pt. Name ink
  measures 10 pt top/10.667 pt left against 10 pt content inset (glyph bearing).
  Commands, verbatim failure, source references and limits: `.build/direction-a/step2/`.
- Step 3 will establish passive maximum-height measurement using existing faces;
  step 4 supplies the new raise face and step 5 the back. Final all-face height proof
  belongs to step 5 once all three exist; long back content scrolls in a bounded body.
  Restore Rules-based guide reopening coverage then. Steps 3–8 and the queued support
  task remain unfinished. Engine, persistence and excluded audit paths are untouched.

## 2026-10-01 19:14 KST — Direction A step 3 verified, owner decisions pending

- Step 2 committed locally as `a52b094`; nothing pushed. Step 3 remains uncommitted
  in Components.swift, FreeTableView.swift, FreeDockPresentationTests.swift,
  FreeDockFlowTests.swift and tools/uisweep.sh. It adds fixed action slots, public
  replay titles/prices, the two warnings, Skip, passive stable dock sizing and
  bounded accessible scrolling. Existing raise/Math faces await steps 4/5.
- Generic/sweep builds and `git diff --check` pass. App units: 61 XCTest + 8 Swift
  Testing; Drills: 363 XCTest + 31 Swift Testing. All 17 selected unique UI methods
  passed across preserved gates and focused rechecks, not one green aggregate run.
  Initial child-ID containment defect was fixed; invalid overflow fixtures, Skip
  query race and scroll gestures were corrected in tests. All failed attempts and
  exact commands are retained in `.build/direction-a/step3/`.
- Inspected KO/EN 2/3/4-player large/AX5 matrix, replay/warning states and native
  full-control/prose reachability. Rejected black EN4 AX capture was replaced by
  `.uisweep/20261001-190334-844O9K/.../play-hand.png`. Normal painted dock height
  315 pt; measured title top 20.33, action sides 20.33 and bottom 20 pt. Normal
  native buttons 87.17 pt; AX buttons 87–172 pt, including wrapped Korean price.
- Four async owner choices remain unanswered: permit AX button growth/price wrap;
  choose 1-chip raise increments versus unreachable odd legal amounts with ±2;
  permit the small Drills Facts fix (bestHandOfAny) versus app-only adapter; correct
  short-call Math using public contestable pot versus show unavailable. Preflight
  reports prove the parity conflict, flop Facts crash and 19% versus 24% discrepancy.
  Do not infer approval or commit step 3 until its AX exception is settled (§11).
- Next: record owner decisions in spec §13, commit accepted step 3 with explicit
  paths, then continue steps 4–8. Final all-face sizing proof belongs to step 5.
  Support/email/privacy/Pages work remains strictly last and has not started.
- No owned jobs remain; owned iPhone 17 is shut down, user Audit devices untouched.
  No Engine, progression, saved-setting, excluded audit-path edits or pushes.

## 2026-10-01 — Owner approved four recommendations

- Owner explicitly approved AX action growth/price wrapping, one-chip raise steps,
  the small Drills Facts evaluator-call fix and public contestable-pot Math.
  Recorded in spec §13. Step 3 verified candidate is accepted; continue step 4,
  with the two Facts/Math fixes in step 5. Existing evidence remains valid because
  this approval changes no implementation. No push; support task stays last.

## 2026-10-01 — Direction A step 4 verified

- Step 3 committed locally as dd348cb. Step 4 adds five context-aware presets,
  exact incremental stack cost, one-chip tap/hold controls and the normal gold
  commit. Illegal/duplicate presets remain; the slider is gone. AX reflows the
  amount below Back/Math and scrolls the five-preset row without shrinking text.
- Generic builds pass; Drills passes 363 XCTest + 31 Swift Testing. App units pass
  61 XCTest + 12 Swift Testing. Eight unique UI methods passed across preserved
  gates; the final native-button gate passes all four focused methods. A real
  pan-from-step-key defect was found and fixed with native Button press handling;
  tap, hold, release, next tap, limit, odd amount and parent-scroll behavior pass.
  Every failed attempt remains verbatim in .build/direction-a/step4/report.md.
- Inspected KO/EN 2/3/4-player large/AX5 raise, facing-raise, postflop and short-stack
  captures, plus full-control native screenshots. Final AX roots: KO
  .uisweep/20261001-211912-tes2TE/ and EN .uisweep/20261001-212309-U62K3P/.
  Measured normal amount top20.333 pt, control left20.667/right20/bottom20.333;
  final AX Back ink top19.667 pt in both languages. Native corner clearance19.143
  pt is within one screenshot pixel of the accepted Step1 native-curve exception.
- Rejected EN cold-demo landing capture was replaced using an ignored warm-relaunch
  sweep copy, with fresh uninstall before each case. This is capture setup, not a
  claimed product cold-launch fix. Exact copy diff, commands, measurements and
  rejected evidence are retained. Native cold-launch interaction gates passed.
- Condensed older handoff entries per AGENTS and retained their full text in
  docs/handoff-archive/2026-10-01-before-direction-a.md; unresolved checks remain.
  Next: step 5 flip/back/review and the two approved Facts fixes. Its dot-square
  versus 1-in-N contradiction awaits the separate owner answer; independent work
  may proceed, but do not infer that answer. Steps 5–8 and support work remain.
- No Engine, progression, saved setting, excluded audit-path edits or push.
  Physical haptics/VoiceOver and older-runtime visual execution remain unverified.

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
