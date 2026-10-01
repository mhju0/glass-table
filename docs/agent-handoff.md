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

## 2026-10-01 — Free table Direction A, round-3 exploration (no code changes)
- Artifacts: Direction A spec https://claude.ai/artifact/MXxoJp3TdKd5MTpLxZrR8n; round 3
  (seat box, style label, My-turn line, raise amounts, Math levels, cards, gold rule,
  app-wide consistency) https://claude.ai/artifact/HvDQgUSKkWnAKAxH8hVZmJ.
- Proposed, awaiting go-ahead: seat box = name / status-or-style / cards + stack
  bottom-right; no sub line under the turn title except all-in call and short-all-in
  no-reraise; fixed fold/call/raise slots (dim, don't hide); spot-aware raise presets;
  Math level 1 always, level 2 unlocked by lessons, equity only after the hand; gold
  outline = now, gold fill = pick/primary, paper = you; one card back.
- Open: table-side outs need a hand-only draw-outs helper (`countOuts` takes the villain
  hand, would leak). This file is over ~200 lines and needs condensing.
- Later 2026-10-01: user approved all round-3/4 recommendations. Final spec with the
  app-wide spacing rules (R1 equal visible inset with per-font top correction, R2 one
  content edge, R3 left = right, R4 concentric corner children, R5 few insets/radii):
  https://claude.ai/artifact/HaBQzPo6uRnpwTrgrv5GUR. Measured: dock top reads 25 pt vs
  20-21 sides; sheet corner ~46 pt vs 14 pt corner buttons; felt 16 pt vs dock 8 pt edge.
  Next: build in the spec's order, starting with the spacing foundation.
- Build handed to Codex with `docs/specs/2026-10-01-free-table-direction-a.md` as the
  source of truth (supersedes the exploration pages where they differ). Deferred: Math
  level 2 (needs a hand-only outs helper), "fast table" setting.

## 2026-10-01 — Direction A step 1 candidate, awaiting owner choices

- Created `feat/free-table-direction-a` from `33e5384`; step 0 committed as `6dc95b6`
  (`docs: add free table Direction A spec`). No push. Step 1 remains uncommitted;
  steps 2–8 have not started.
- Implemented script/font-aware ink-leading correction, spacing/radius tokens, native
  dock corner children, attached-dock home-indicator compensation, and two Learn card
  roles. Added settled-Play audit readiness and KO/EN AX5 Learn scroll/tap verification.
- Brought only the already-approved 87 pt table-button minimum height forward from
  step 3: the old 62.33 pt height clamped the required concentric corner radius.
  Shared button defaults and accessibility growth remain unchanged.
- Final generic build passed; Drills passed 363 XCTest + 31 Swift Testing tests.
  Exact candidate passed 61 app unit + 19 UI tests, zero failures, with saved xcresult.
  Reviewed 2/3/4-player KO/EN large/AX5 captures and native Learn scroll captures.
- Normal dock top/left/right/bottom: 25.67/21.67/20.33/20.33 →
  20.33/21.67/20.00/20.00 pt. AX5 baseline bottom 64 pt (intermediate 42) → 20 pt.
  R1 retains title ink bearings beyond the content edge: 1.67 pt normal, 3.33 pt AX5.
- Owner choices pending: exact AX5 titles cannot fit one line beside Math without
  shrinking (§11); allow wrapping or supply shorter titles. R4 corner clearance is
  19.235 pt versus 20 pt sides, independently measured/reviewed; accept the native
  0.765 pt exception or require a custom offset curve. Do not claim full R4 compliance.
- Evidence, exact commands, verbatim failures, rejected/recovered captures, all 22
  unchanged 베팅 source sites, and pending on-phone haptics checklist are in
  `.build/direction-a/step1/report.md`; final tests in `final-candidate-tests.xcresult`.
  Temporary diagnostic/failed container code was removed. No Engine, progression,
  persisted-setting, or excluded audit-path changes. Outs and fast-table remain deferred.
- Next: resolve owner choices, finish/accept and commit step 1, then continue steps 2–8
  in order. The separate support-contact/privacy/support-page/submission-doc task is
  queued strictly after the redesign finishes; do not start it while this work is paused.

## 2026-10-01 — Direction A owner decisions accepted

- Owner approved wrapping exact AX5 titles and retaining native concentric corners
  with the measured 0.765 pt R4 exception. Recorded both in spec §13; they supersede
  the pending choices above. Step 1 is accepted with its reported optical bearings.
- Continue in build order, targeting a verified table-layout commit within the owner's
  roughly 50-minute window. Stop only when asked to pause; record the exact unfinished
  state then. Local commits/files survive the laptop break; interrupted tests may rerun.
- The separate support task stays queued until the full redesign is finished.

## 2026-10-01 15:37 KST — Direction A paused at owner's request

- Step 1 is committed as `22bb963`; branch remains `feat/free-table-direction-a`.
  Nothing pushed. Step 2 is implemented but uncommitted; preserve its nine modified
  source/config/test files and this handoff edit. Steps 3–8 have not started.
- Step 2 adds portrait-only/natural-height 8 pt felt, the approved seat map and empty
  seat, paper hero, separate public status/stack/committed chips, and shared 36/43 pt
  cards. Legacy lesson seats keep their detail layout. Paper-only gold ink is #88600F
  (4.83:1 against cream); the existing acting border gold is unchanged.
- Automatic first-use guide remains temporarily; the removed ⓘ no longer reopens it.
  Relevant tests/copy reflect this. Restore Rules-based reopening coverage in step 5.
- Builds and Drills passed (363 XCTest + 31 Swift Testing, zero failures). The selected
  app unit/UI gate has NOT started; its prepared command is
  `.build/direction-a/step2/run-tests.sh`. New six-launch AX5 reachability/rotation
  test is unverified. Do not commit step 2 until its remaining gate and review pass.
- Final KO captures: `.uisweep/20261001-153301-2QyvyH`; EN captures:
  `.uisweep/20261001-152912-hzWe3z`. Replacement EN AX3:
  `.uisweep/20261001-153613-RuOnF1/accessibility-extra-extra-extra-large/play-hand-3.png`
  exists but was NOT inspected/measured before pause. The replacement reserves the
  empty seat's AX5 stack line. Evidence/report/commands/measurements are under
  `.build/direction-a/step2/` and remain a partial checkpoint.
- No owned process remains active; disposable sweeps cleaned themselves. Test iPhone
  17 is shut down; existing Audit simulators were left untouched. No Engine,
  progression, persisted-setting, excluded-path, or support-task edits.
- Resume: inspect replacement AX3 and final KO matrix at root; run selected gate;
  inspect native reachability/rotation evidence; finalize step 2 report and commit
  after acceptance, then continue in order. Support work remains strictly last.

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
