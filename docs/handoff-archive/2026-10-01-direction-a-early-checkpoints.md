# Direction A early checkpoints — archived 2026-10-01

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

