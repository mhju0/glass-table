# Agent handoff

## 2026-09-23 — Earlier work condensed

The complete prior handoff is preserved in
[the dated archive](handoff-archive/2026-09-23-before-combined-release.md).
It covers shared instructions, revamp/learner-trust fixes, PR #5 publication,
pot-calculation prototypes, the native amber/green appearance update, and
beginner-release mock approvals. Historical pending-native statements there
are superseded by the delivery below, not deleted.

Still open from earlier work: physical VoiceOver, minimum iOS 17, novice
comprehension, signed distribution/Store validation, current store screenshots,
and final age-rating/territory decisions. Installation does not close these.
The unrelated `.scratch/pot-calculation-redesign/` in the primary checkout and
earlier verification worktrees remain preserved. Do not reset phone progress.

## 2026-09-23 — Combined beginner native release (condensed 2026-09-24)

- Runtime `1f5cf33`: Learn / Play / Progress, 18 open concepts, optional
  placement (grants no mastery), KO/EN, resumable practice, four-player Play
  with factual reviews (no invented EV grade). Schema 2 keeps old records and
  original migration bytes. Details: [delivery report](specs/2026-09-23-beginner-native-release.md).
- Still open: the human/distribution gates above, and synchronous save latency
  for very large local histories (limits documented in the report).

## 2026-09-23: Settings in bottom navigation

- Changed: Settings is the far-right fourth tab. Removed top gear/globe shortcuts;
  language lives inside Settings. Root pages reclaim navigation-bar space while
  pushed Back and presented Close controls still work. Fixed Progress summary
  truncation at accessibility sizes during the visual check.
- Why: The owner requested fewer top controls and more space for learning content.
  Existing styling remains; no schema, engine or grading change.
- Verified: 15 interaction tests, final 6 appearance/contrast tests plus AX5 Settings
  navigation, and 2 Release smoke tests passed. Installed 1.0 (5) in place on the
  iPhone 12 mini; progress and schema-1 backup stayed byte-identical after launch.
- Evidence: Implementation `e612e66`; [delivery record](specs/2026-09-23-settings-navigation.md).
  Raw logs, screenshots and phone backups remain in `.build/settings-navigation/`.
- Open issues: Physical VoiceOver/keyboard and minimum-iOS-17 checks remain
  unverified. No push or App Store submission in this task.
- Next step: Owner tests the installed bottom-tab navigation and language setting.

## 2026-09-23: Approved learning/table consistency direction

- The owner approved both clarification rounds. Decisions and acceptance checks
  are in [the local spec](../.scratch/consistent-learning-table/spec.md).
- Agreed: full-screen learning, stable wide green table, shared table/card
  components, tap-paced replay, contribution totals behind help/reveal, assisted
  practice separate from unaided accuracy, and consistent concise answer feedback.
  Every mode needs a skippable, reopenable first-use visual explanation.
- Read-only source review confirmed sheet presentation, exposed pot contribution
  totals and separate table renderers. Intro content exists on some entry paths;
  its reachability and comprehension still need an end-to-end check.
- Documentation only. No mockups, app edits, tests, install or push in this step.
  Next: prepare the shared layout and teaching plan from the approved spec;
  preserve progress and keep four-seat Play grading separate from heads-up.

## 2026-09-23: Shared-table prototype and teaching plan

- Prepared the [all-concept teaching plan](../.scratch/consistent-learning-table/teaching-plan.md)
  and four scoped tracker issues. Built one local interactive browser prototype
  covering pot calculation, position, combos and scripted four-seat Play.
- Browser checks: eight interaction groups passed; owner checked 32 combinations
  of language, appearance, text size and mode for horizontal overflow/shared table
  height. Corrected answer leakage, hint completion, cramped labels and overlapping
  shared cards during review. [Evidence and limits](../.scratch/consistent-learning-table/verification.md).
- Decision still needing visual feedback: prototype table is 328 x 240 at compact
  normal size and 328 x 280 with larger text, shared across table modes. This is a
  provisional readability tradeoff against the approved approximate 2:1 preference.
- Native code, saved progress and the installed iPhone app are unchanged. No push
  or commit. Next: owner reviews prototype; then implement native shell/components,
  explanations and assisted-attempt handling with the required persistence review.

## 2026-09-23: Prototype player/table border alignment

- Owner rejected inconsistent player-panel curves and offsets in a screenshot.
  Prototype now uses equal insets, concentric outside-facing corners and a single
  table border. Active highlighting retains the same border width and bounds.
- All eight browser groups passed again; inspected the cropped alignment capture
  in `.scratch/consistent-learning-table/evidence/aligned-table-corners.png`.
- Recorded geometry in the feature spec. No native edits or device install.

## 2026-09-24: Table material/polish comparison in prototype

- Owner approved a restrained polish direction: dark rail, darker seat areas,
  shadows only on cards/chips/dealer, ivory/slate fixed-height chips, one
  26 x 36 table card size, slate card backs, centred board+pot group, neutral
  folded status. Recorded in the feature spec with its purpose.
- Prototype has a Design review control (Current/Refined, `?design=refined`).
  Current is unchanged. Also fixes the "Folde/d" wrap and off-centre dealer D.
- Verification: 8 browser groups passed for both designs; refined 32-combination
  overflow/overlap/clipping check clean. Details in `verification.md`.
- Open: owner review of the refined visuals. No native edits, install, commit
  or push. Next: apply feedback, then retire Current if approved.

## 2026-09-24: Bilingual line parity rule and side-by-side compare

- Owner rule, app-wide, recorded in `DESIGN.md`: at the default size, KO and
  EN wrap to the same line count, last lines are at least half full, end widths
  are similar, and nothing breaks inside a word.
- Prototype: `compare.html` (synced Current/Refined phones); `audit-lines.cjs`
  (31 states, 513 blocks). 31 strings revised on the Refined side only. Current
  normal has 33 problems, Refined has 0. At large size, 28 reflow widows or
  mismatches remain and in-word breaks are 0.
- Verification: 8 browser groups for both designs and the 32-case matrix pass.
- Open: the owner decides whether large-text widows need copy fitting too.
  Native copy has not been audited against the rule. Needs approval and a
  native measurement check (both KO/EN catalogs, compact width).

## 2026-09-24: Native KO/EN line parity audit (read-only)

- Owner approved the native audit. Ran uisweep KO and EN on an iPhone 12 mini
  clone (default text size, light) and measured with Vision OCR; tools and
  side-by-sides are in `.scratch/consistent-learning-table/native-audit/`.
  Results in that feature's `verification.md`.
- Finding: no Korean in-word breaks natively; parity and short-last-line
  violations are widespread (54/78 screens flagged, every one of 10 inspected
  confirmed), mostly English taking an extra line.
- No Swift copy changed, nothing installed, committed or pushed.
- Open: owner decisions on large-text fitting (Q1) and the Position intro
  answer leak (Q3); native copy fitting awaits approval and should reuse the
  OCR audit as its check.
- Owner chose large-text option A and approved the Position example rewrite
  (rule, not answer). Two further leaks await review: the expanded order line
  and the highlighted button seat in the intro example table.

## 2026-09-24: Native KO/EN copy fitting (uncommitted, awaiting owner review)

- On `fix/bilingual-line-parity`: 75 string pairs in 15 Swift files, including
  all 8 learning-guide pages, plus 2 UI tests that pin copy. App suite and
  Drills tests pass. Nothing committed, installed or pushed.
- Review: `.uisweep/line-parity-review/review.html`, local and gitignored
  (before/after copy table and KO|EN screenshots). Details are in that
  feature's `verification.md`.
- Open: owner approval of the copy; systemic digit–Hangul in-word break
  (proposed U+2060 word joiner, not implemented); two Position intro leaks.
- Next: on approval, commit the Swift and test files only (explicit paths).
- Update: owner asked to commit and push to main. Copy fit, feature docs and
  audit tools committed; merged worktrees/branches removed. Review page and
  screenshots moved to ignored `.uisweep/line-parity-review/`.
  `.scratch/pot-calculation-redesign/` left untracked on purpose (unrelated).

## 2026-09-24: Digit–Hangul word joiner

- `KO.wordJoined` plus a disfavoured `Text(String)` overload
  (`GlassTable/Sources/DesignSystem/WordJoinedText.swift`) stop iOS breaking
  "100 / 핸드", "9% / 를", "8 / 을". Accessibility labels keep the plain string.
- Not covered: string literals in `Text("…")`, `Button`/`Label` titles.
- CI fix pushed earlier: `PracticeTableTests` split one `#expect` that timed out
  the CI type checker (pre-existing since `0742438`).
- CI on main failed `testChartExplorerReachesOwnHandAtLargestTextSize` on the
  runner's iOS 18.5 simulator (Xcode 27 locally cannot download iOS 18). Fixed
  by deferring the chart explorer's initial scroll one main-queue turn; verified
  by a CI run on a feature branch (46/46), then merged.

## 2026-09-24: Installed 1.0 (6) on the iPhone 12 mini

- Release 1.0 (6) at `bb87591` + build bump, installed in place (no uninstall).
  `progression.json` and the schema-1 backup were copied off the phone first
  (`.build/device-backups/20260924-before-1.0.6/`) and were byte-identical after
  launch.
- Loss: the earlier worktree cleanup removed `.build/beginner-native-release/`
  and `.build/settings-navigation/` with their ignored raw evidence (logs,
  screenshots, earlier phone-backup copies), despite the note above to archive
  first. No local snapshot exists; a Time Machine disk was not mounted. Commits,
  delivery records in `docs/specs/` and on-phone progress are unaffected.

## 2026-09-24: Full-screen activities and the shared table (issue 02, part 1)

- Branch `feat/shared-learning-table` (not pushed): `1d23978` opens lessons,
  practice and review with `fullScreenCover`; `a8d5b4a` adds `TableSurface`
  (owner-picked "Refined" look) for pot counting; `717f265` moves Play onto it.
- Decisions: pot questions hide per-seat totals and start at the blind posts;
  the centre shows the total only after the answer. Play keeps stacks and the
  pot visible because they are public there. The Position 8-seat strip and the
  graded heads-up `TableView` keep their own renderers for now.
- Verified: new UI tests failed first and pass now; full app suite 48/48 UI plus
  unit tests. KO dark screenshots at large and AX5 checked.
- Open: EN/light screenshots, measured table bounds, heads-up `TableView`
  decision. Issues 03 (first-use explanations) and 04 (assisted = practice)
  are next. Record in `.scratch/consistent-learning-table/verification.md`.
- Device: Release 1.0 (7) from `95f47a1` installed in place on the iPhone 12
  mini for owner testing. Progress and the schema-1 backup were copied off first
  (`.build/device-backups/20260924-before-1.0.7/`) and were byte-identical after
  launch.

## 2026-09-24: Combo definition; phone reset at the owner's request

- `aeaedd7`: the combos walkthrough opens by defining a combo with one exact
  two-card example of the spot's class (avoiding visible cards); the intro
  "why/how" copy says the same. Beat count grew by one, which keeps saved
  walkthrough positions valid. Part of issue 03 (combos row).
- Device: owner asked to start fresh. All app data (progression, schema-1
  backup, preferences) was copied to `.build/device-backups/20260924-before-reset/`,
  then the app was uninstalled and Release 1.0 (8) from `07f9a1e` installed
  clean. The container had no progress files before first launch. Restoring
  means copying those files back into the app's data container.
