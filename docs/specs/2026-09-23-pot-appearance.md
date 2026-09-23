# Native pot lesson and adaptive appearance

Delivered locally and installed on the owner's iPhone 12 mini, September 23, 2026.
Runtime candidate: `ae641433f52a13c2ba445661eb94d94bbb3b20c6`.
Subsequent commits `b89445a` and `ed14b72` change screenshot timing and a test
expectation only. The primary checkout contains the implementation. No push or
App Store submission was performed for this delivery.

## Implemented behavior

- The pot lesson replaces the stepper/transcript with a green table and three or
  four contribution trays. One active-seat caption explains each user-paced move.
  Blind posts are separate events; folds retain paid chips; raises add only the
  amount above the player's previous contribution. The stopping point can still
  have a player waiting to act, so it is not presented as a settled betting round.
- First entry explains why/how and SB/BB, then begins at the first blind post.
  Returning questions can start at the final replay position. Previous/next and
  calculation help remain available. Answers unlock at the final replay step.
- Three unique seeded choices contain exactly one correct value. Distractors use
  plausible calculation errors, but feedback does not diagnose the learner's
  thought process. Correct position and numeric rank vary. The first three
  generated questions ask for the current pot; later ones ask for a fraction.
- No aggregate pot is disclosed before commitment. Optional arithmetic follows
  the answer. Existing outcome recording and progression schema are unchanged.
- Pot content uses one scroll view. At larger text sizes, ordered contribution
  rows replace the fixed seat diagram and answer choices stack vertically.
  The short decorative chip flight respects Reduce Motion and task cancellation.
- App-wide System/Light/Dark preference lives separately from learning progress.
  Neutral panels and amber actions replace the green-on-green hierarchy; poker
  tables and card faces retain fixed colors. The Settings sheet updates live.
- Added app-only UserDefaults privacy reason CA92.1 and corresponding Release
  manifest checks. Release binaries exclude the new DEBUG demo hooks.

The design-system and accessibility skills guided semantic color pairs, compact
layout, equal-weight choices and rendered verification. The supplied Swift and
motion guidance informed value-model replay and cancellable decorative motion.

## Verification evidence

Local artifacts are under `.build/pot-appearance-native/` in the primary checkout.
Paths below are relative to that retained implementation worktree.

| Gate | Result and evidence |
|---|---|
| Engine Release | 91 passed; `.build/engine-release.log` |
| Drills | 341 passed; `.build/drills-tests.log` |
| Tooling | 17 passed using `python3 -m unittest discover -s tools/tests -p 'test_*.py'` |
| App model and appearance | 33 XCTest tests plus 6 Swift Testing functions passed; `.build/final-contrast-tests.log` |
| Debug UI | Initial full run passed 34/35; `.build/full-tests.log`. The failing test expected 1 answer despite seeding 16. Diagnostics showed the correct persisted 17. Test-only correction passed in `.build/pot-persistence-final.log`; the full suite was not repeated after that correction. |
| Accessibility | All 10 existing AX UI flows passed in the full run. Pot intro/replay/AX5 reachability and exact-once recording have dedicated UI coverage. The final Defend AX test also passed in `.build/final-contrast-tests.log`. |
| Appearance behavior | Both appearance UI tests passed, including rendered light/dark brightness and relaunch persistence. Manual live System-mode switch inspected in `.build/system-appearance/`. |
| Release UI | 2 passed with `-only-testing:GlassTableUITests/ReleaseSmokeTests`; `.build/release-smoke-targeted.log`. An earlier unfiltered invocation was stopped because it also selected DEBUG-fixture tests against Release. |
| Signed device bundle | Release build succeeded; `.build/device-build-final.log`. `tools/verify_release.py` and strict code-sign verification passed. Version 1.0, build 3. |
| Independent review | Read-only review of frozen `ae64143` found no remaining must-fix issues after fixing translucent Defend fills and adding an actual-fill contrast regression. |

Screenshot sweeps used disposable iPhone 12 mini simulators at normal and AX5
text sizes, in both light and dark modes. Inspected contact sheets and individual
pot/settings frames, not only capture exit codes:

- Broad light: `.uisweep/20260923-124634-s7jM9W`, 29 screens at both sizes.
- Broad dark: `.uisweep/20260923-124731-LyZM7s`, the same 29 screens/sizes.
- Final light rechecks: `.uisweep/20260923-130016-B6OcDy`, Defend/table chart and
  replacement captures for early blank or notification-obscured frames.
- Final dark rechecks: `.uisweep/20260923-130613-ynNAmr`, Defend/table chart,
  path, records and EV-loss. An earlier disposable simulator timed out on launch;
  that failed capture run is not evidence of a verified screen.
- The dark AX5 table-chart frame caught sheet presentation in progress; its
  inspected replacement is `.build/system-appearance/table-chart-dark-ax5.png`.

The sweep now accepts `GT_APPEARANCE=light|dark` and waits four seconds by default
before capture. Screenshot fixtures are visual evidence; XCTest separately
exercises answers, scrolling, optional arithmetic and navigation.

## iPhone delivery and preservation

Built and signed the Release app, copied the phone's existing `progression.json`,
then installed over the existing bundle without uninstalling or resetting it.
Device inventory confirmed Glass Table 1.0 (3), and device launch succeeded.
Progress matched byte-for-byte before installation, after installation and after
launch. Copies remain in `.build/device-preservation/`; their SHA-256 is
`64915631193c292f0f1f8064130eaffaec3f4edb139f92fabb982af97600fc34`.

## Remaining limits

- The owner still needs to judge comfort and learning flow on the physical phone.
  Physical VoiceOver, minimum-iOS-17 runtime, distribution and App Store approval
  remain separate gates. Simulator reachability is not physical VoiceOver proof.
- This ships the pot introduction, not new introductions for every lesson/mode.
  Five/six-player generated pot diagrams are intentionally outside this scope.
- Existing non-pot lesson layouts were checked for appearance regressions, not
  redesigned. Larger content remains scrollable; every item need not fit at once.
- Current production ranges use whole-class 0/1 weights. Recheck label contrast
  before exposing fractional range weights; that is not current UI coverage.
- Earlier public/store screenshots retain their dated provenance and were not
  republished in this task. The local mock history remains available separately.
