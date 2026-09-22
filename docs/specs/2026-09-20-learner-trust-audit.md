# Learner-trust audit and verified fixes

## Scope and source of truth

Completed 2026-09-20 against the **revamp**, not the older main checkout.
Baseline: `069ddf1ef477ab2bad6d470d187442dda66e31da` on
`codex/research-led-revamp`. Final runtime candidate:
**`4a499974afb1d164fde3d90ac5bf179833ad27d3`**.
Implementation was isolated on `codex/learner-trust-fixes` in
`/Users/michaelju/Workspace/Projects/glass-table-audit-fixes`.
This is local simulator-verified work, not an App Store release.

The owner approved fixing confirmed learner-facing issues, preserving the
revamp, and recording the work only after implementation and verification.
This record was written at that final stage. Earlier dated delivery reports
remain historical evidence, not current test counts. Before reopening this
audit, compare the current commit with this candidate and rerun the relevant
regressions; do not apply old-main line numbers to the revamp.

## Claude report checked against the revamp

| Reported issue | Revamp finding and disposition |
|---|---|
| 1. AX5 table sheet permanently hides hole cards | The revamp already uses continuous scrolling at accessibility sizes and wraps the context. Cards can initially be below the viewport; permanent occlusion and the proposed picker-clearance diagnosis did not describe this branch. Kept the layout and added a geometry regression proving both cards can be fully exposed above the actual tab bar. |
| AX sweep was documented but never implemented | Confirmed tooling gap. `uisweep.sh` now captures `large` and Accessibility XXXL by default, with tested single-size override and failure cleanup. |
| 2. Reveal explains an invisible grid cell | Partly valid: compact initial view does not show the whole grid, but the revamp content already scrolls and the selected hand already had an outline. Added the hand/action summary before the grid, moved EV range evidence first, and exposed semantic chart rows. No claim that all 169 cells fit on one screen. |
| Grid is one opaque accessibility label | Confirmed. Defend and range grids now expose row-level hand/action or inclusion labels while retaining a quick aggregate summary. This is accessibility-tree coverage, not a complete spoken VoiceOver audit. |
| 3. A 0.2bb loss says “최선” | Already corrected to “거의 최선” in the revamp. Improved the remaining hierarchy: lesson first, band secondary, best/chosen EVs and explicit nonnegative loss subtraction. AX rows stack labels above values. |
| 4. Preflop gives a pot-odds rule but grades the chart | The old “40% 이상이면 콜” instruction was already gone; ambiguous reference pricing remained. The strip now says “참고”, shows pot/call amounts, and leaves the published defend chart as the explicit grading basis. |
| 5. Migrated MDF record displays raw `mdf` | Already resolved: the revamp has 9 units / 18 concepts, including `u9-mdf` and “최소 방어 빈도”. No migration or record filtering change needed. |
| 6. Save failures are swallowed | Already resolved by visible save errors, retry, unsaved-state export, and recovery handling. Existing app tests cover failed saves/imports/resets and retained bytes. Production persistence was not changed. |
| Recovery copies accumulate | Retention is real and deliberate data preservation. Cleanup/retention UI is deferred; no recovery copies were deleted. |
| Postflop policy is unreachable anywhere in-app | Overstated: the action-read walkthrough already exposes a bucket table. The Table lacked a direct reference for its current opponent. Its range-count button now opens actual policy rows, bet fraction, caps, and limitations. |
| Records calibration advertises outs intervals | Confirmed misleading empty-state copy; removed outs from that promise. Count drills do not supply intervals. |
| Today calibration lacks a 90% marker | Obsolete: that calibration panel is absent from the revamp's Today screen. No marker added to a nonexistent panel. |
| Path never scrolls to the current lesson | Confirmed. It expands the current unit and scrolls once to the actual available node; returning preserves manual scroll position. |
| Count answers default to 8 | Confirmed. Answers start unset; explicit numeric entry is required. Zero is valid, deletion can return to empty, and the next question resets. |
| `tools/tests` contains only an orphan `.pyc` | Not true of the revamp: source tests already existed, with 11 baseline tooling tests. This delivery has 14. The unrelated main-checkout orphan was left untouched. |
| Preflop placeholders waste about 40% of the screen | Subjective estimate, not independently measured. A board-space redesign is deferred to preserve spatial stability; scroll/card reachability is verified instead. |
| Range count has no explanation or tap target | Confirmed and fixed by the minimum-44pt policy-reference button. |
| Defend “근접” implies a low-cost poker mistake | Wording improved to chart match/mismatch with chosen/chart actions. Adjacency grading and progression remain unchanged; this is not an EV estimate. |

Primary code: `TableView.swift`, `TablePolicyReferenceView.swift`,
`ConceptDrillView.swift`, `PathView.swift`, `RecordsView.swift`,
`DefendGridView.swift`, `RangeGridView.swift`, `CountEntryView.swift`,
`ProgressionModel.swift`, and the unchanged Drills `Table.swift`,
`EVLoss.swift`, `Curriculum.swift`, `LegacyMigration.swift` and persistence code.

## Decisions and invariants

- Fix evidence access and explanatory honesty without changing generators,
  EV thresholds, defend scoring, curriculum IDs, or production storage semantics.
- Keep the selected-hand summary ahead of the grid rather than forcing a
  scroll-to-cell jump. The grid retains its outline and scroll access.
- Number entry is collapsed initially. An always-open keypad was rejected after
  compact screenshots showed it consuming the hero-card space. The learner opens
  it deliberately and closes it with “입력 완료”; no software-keyboard dismissal
  gesture is required.
- The Table policy reads `TableHand.policy`, not a duplicated strategy table.
  Postflop opponent folds narrow to fold buckets. **Only an opponent folding to
  a preflop 3-bet retains the preceding tracked range**; the disclosure names that
  exception. It also explains raise/stack caps and the river draw treatment.
- The late-Path fixture is DEBUG-only, requires a valid isolated `GT_TEST_STORE_ID`,
  and does not override an explicitly injected store. It exercises normal
  current-node lookup using real cleared-node state.
- Recovery retention, wholesale preflop spacing redesign, grading-policy changes,
  and release/territory decisions remain outside this delivery.

## Verification results

Environment: Xcode 27.0 (`27A266a`), iOS 26.5, compact iPhone 12 mini simulator.
The dedicated XCTest device was `GT-LearnerTrust-20`
(`6D1B0788-FC9A-4E14-BD7A-6EB9F04AC118`). Screenshot sweeps created and cleaned
their own disposable simulators. Simulator work was serialized.
The dedicated XCTest simulator was deleted after verification; its data was
test-only. Retained screenshots and xcresults are independent of that device.

| Gate | Result and exact evidence boundary |
|---|---|
| Drills | PASS — 335 tests; package source unchanged throughout this delivery. `/tmp/gt-learner-drills.log` |
| Engine Release | PASS — 91 tests; engine source unchanged. `/tmp/gt-learner-engine.log` |
| Tooling | PASS — 14 tests, including two-size capture, override validation, fresh installs, stale-build rejection and failure cleanup. `/tmp/gt-learner-tooling-final.log`; repeated after `d1bbe32`, also 14/14. |
| Full Debug app suite | PASS — 33 model + 10 accessibility + 18 learning-flow + 2 smoke/performance = 63 tests on `2ddc8f3`. No failures or skipped tests. `/tmp/gt-learner-full-test-final2.log` |
| Final policy-copy delta | PASS — focused AX policy test on `d1bbe32`, including the preflop-only exception. `/tmp/gt-learner-policy-final.log` |
| Final AX EV-row delta | PASS — focused evidence/equation and horizontal-label geometry test on `4a49997`; corrected screenshot inspected. `/tmp/gt-learner-ev-final.log` |
| Final Release smoke | PASS — 2 tests on `4a49997`, fresh install without demo hooks. `/tmp/gt-learner-release-smoke-final2.log` |
| Final Release hook scan | PASS — no `GT_DEMO_` or `GT_TEST_` strings in the Release simulator app binary. SHA-256 `f50a534b7cfc18455a90d15fa670e526f1305f9c0e7b263671c1109e53d495a7`. |
| Final screenshot refresh | PASS — 3 affected screens × 2 sizes on `4a49997`, all six inspected. `.uisweep/20260920-172111-TF4uBl`; `/tmp/gt-learner-sweep-frozen.log`. |
| Independent review | PASS — separate Standards and Spec reviews; no outstanding blocking findings on `4a49997`. Details below. |
| Physical device, full VoiceOver audio, iOS 17 runtime, signed archive and App Store | NOT PERFORMED — these remain release gates, not implied by simulator results. |

The full 63-test suite was not rerun after the final copy-only and AX-row deltas;
their focused tests, final Release build/tests and final screenshots cover those
changes. The final Release launch measurement averaged 1.662s across three runs
(RSD 10.866%); XCTest passed, but this is not evidence of a performance improvement.

Reproduction commands (choose an available compact simulator for `<simulator-id>`):

```sh
xcodegen generate
swift test --package-path GlassTableDrills
swift test -c release --package-path GlassTableEngine
python3 -m unittest discover -s tools/tests -v
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,id=<simulator-id>' \
  -derivedDataPath /tmp/gt-learner-debug-recheck CODE_SIGNING_ALLOWED=NO test
xcodebuild -project GlassTable.xcodeproj -scheme GlassTableReleaseSmoke \
  -configuration Release -destination 'platform=iOS Simulator,id=<simulator-id>' \
  -derivedDataPath /tmp/gt-learner-release-recheck CODE_SIGNING_ALLOWED=NO test \
  -only-testing:GlassTableUITests/ReleaseSmokeTests
GT_SIM='iPhone 12 mini' tools/uisweep.sh --screen table-policy \
  --screen drill-defend-reveal --screen drill-evloss-fold
```

Focused tests are
`AccessibilityFlowTests/testPolicyReferenceCaveatsRemainReachableAtAccessibilityXXXL`
and `AccessibilityFlowTests/testEVRevealLeadsWithRangeEvidenceAndLossEquationAtAccessibilityXXXL`.
Pass them to `-only-testing:GlassTableUITests/<test-name>` on the Debug command.
The tooling and screenshot scripts are committed regression infrastructure;
temporary logs/results below are local evidence, not required runtime files.

### Retained visual evidence

Final six-screen refresh: [normal](../evidence/2026-09-20-learner-trust/large/)
and [AX5](../evidence/2026-09-20-learner-trust/ax5/) `table-policy`,
`drill-defend-reveal`, and `drill-evloss-fold` PNGs are from `4a49997`.
The AX initial frames intentionally require scrolling; the interaction tests
exercise the later explanations and controls.

- [AX table cards fully above the tab bar](../evidence/2026-09-20-learner-trust/ax5/table-hole-cards.png)
- [Normal outs cards above collapsed entry](../evidence/2026-09-20-learner-trust/large/outs-hole-cards.png)
- [AX keypad expanded](../evidence/2026-09-20-learner-trust/ax5/count-keypad-expanded.png)
  and [collapsed after Done](../evidence/2026-09-20-learner-trust/ax5/count-entry-collapsed.png)
- [Final AX EV equation and horizontal action label](../evidence/2026-09-20-learner-trust/ax5/ev-loss-equation.png)

The first four interaction captures come from the green `2ddc8f3` full suite;
those screens did not change afterward. The final equation is from `4a49997`.
All retained images were inspected, not merely generated. An earlier successful
18-capture sweep (`.uisweep/20260920-164703-Ai9OuO`) also covered Table preflop,
outs, combos, Path, Records empty state and range-read comparison at both sizes.
Its policy/Defend/EV frames are superseded by the final refresh above.

Local xcresults:

- Full Debug: `/tmp/gt-learner-correction-derived/Logs/Test/Test-GlassTable-2026.09.20_17-07-56-+0900.xcresult`
- Final AX EV: `/tmp/gt-learner-ev-final.g6MQww/Logs/Test/Test-GlassTable-2026.09.20_17-18-41-+0900.xcresult`
- Final Release: `/tmp/gt-learner-release-final.TJXBwq/Logs/Test/Test-GlassTableReleaseSmoke-2026.09.20_17-19-53-+0900.xcresult`

### Review and verification lessons

**Standards review:** no hard violations. A one-shot deferred Path scroll could
theoretically race hierarchy registration; late-node opening and manual-position
preservation tests passed. Retain the implementation unless a runtime failure
reproduces that concern; no speculative lifecycle rewrite was made.

**Spec review:** found an overbroad range-narrowing statement after a preflop
3-bet fold. The first correction incorrectly generalized retention to every fold;
review against `Table.swift` distinguished postflop narrowing from the preflop
exception. The final narrowly scoped copy and AX assertion were approved.
The final AX EV-row delta was also independently approved with no findings.

**Visual inspection:** caught the initial open keypad consuming card space, an
AX duplicate hand chip, and a fixed-width EV label wrapping one syllable per line.
Corrections were rendered and rechecked. Tests proving element existence or
equation reachability alone did not catch the last defect; a geometry assertion
now protects the horizontal action label.

**Discarded runs:** early interrupted/failed runs are not passing evidence.
One completed focused run executed an older installed XCTest runner despite newer
built symbols. Uninstalling only the dedicated test device's app/runner and using
fresh derived data restored execution of the expected tests. Verify actual test
names and runner identity when logs disagree with current source; do not weaken
tests to accommodate a stale runner. The full green run used runner SHA-256
`a6f9abe88ec0f2c5e0cad359682fece8a2eb0dfaf5c3e4bc00ebfce0b0b90aa2`.
The old finite-review test also had to enter a number before Confirm; its finite
session assertions were retained. A failed early capture run and a black launch
frame were superseded by successful captures; capture success alone is not visual
approval. Keep running scripts unchanged until they exit.

## Next step

Dogfood the revamp on a physical iPhone, including spoken VoiceOver and large text.
Use the current [submission checklist](../submission.md) for minimum-OS,
signed-distribution, age-rating and territory gates. Do not reopen resolved
old-main reports without new evidence. No push, upload, recovery-file deletion,
grading migration, or production-data mutation was part of this delivery.
