# Direction A steps 2–4 — full handoff entries

Archived verbatim from docs/agent-handoff.md on 2026-10-02. Later verified entries supersede historical pending status; unresolved checks remain in the active handoff.

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

