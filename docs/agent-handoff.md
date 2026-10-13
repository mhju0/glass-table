# Agent handoff

Read this at session start. It has three parts: the current state (rewritten, not
appended), the open issues (a living list), and the last few sessions. Rules for
keeping it are in `AGENTS.md`. Older history is in `git log -- docs/agent-handoff.md`
and the frozen `docs/handoff-archive/`; neither needs reading for normal work.

## Current state (2026-10-14)

- Build 25 is in `main` and on the iPhone 12 mini: the owner's build 24 lesson feedback
  (direct fixes, answer marking F2, white answer cards S1, picks 1A, 1C, 2A, 3A) and
  "a near miss is wrong". Mocks: https://claude.ai/artifact/9GBTnNb66MwufA7B19rG7e and
  https://claude.ai/artifact/8aPmc5HftjZcezcpN6TkYs. Items and limits:
  `.scratch/lesson-feedback-2026-10-13/map.md`.
- "A hand together" is rebuilt on the Play table on branch `feat/guided-hand-on-table`
  (not merged, not on a phone): one fixed two-player hand with the real action buttons,
  a coach card (Now / Look at / Think), the coach's pick marked on a button, a dimmed
  spotlight on the first steps, and a question before giving up. The owner chose "the
  mix of B and A" from https://claude.ai/artifact/45hN7vNa15ru28nfsHovcR. Notes and
  limits: `.scratch/guided-hand-2026-10-14/map.md`.
- Only an exact answer counts as correct (owner, 2026-10-14). A near miss, including an
  EV-loss choice that gave up any value, is wrong for accuracy, the miss streak, the
  lesson result, Records and sound, and is scheduled as a hard review
  (`GradeBand.counted(evLoss:)`, `RoundAnswer.countedBand`). Stored bands are unchanged,
  so saved answers still validate; counts saved by earlier builds are not recomputed.
- Hand rank page shows all ten hands with "1 in N hands" / "N판에 한 번" and no toggles
  (owner chose mock A1, https://claude.ai/artifact/MiZkf88JjGtZdwF9Bjxsiy); in `main`
  and in build 24.
- `main` is the only branch, local and on `origin`, and both hold all work through the
  audit follow-ups (owner approved that one push of `main` on 2026-10-13; the standing
  rule is still to work on a feature branch and not push `main` unasked). Old branches
  were deleted; their history is in `main` or in the bundle under `.archive/`.
- Local only, ignored: `docs/grac-submission/` (videos, forms; public repo), tool
  caches, compiled probe output. Nothing else is untracked.
- Decisions and evidence for the follow-ups: `.scratch/audit-followups-2026-10-11/map.md`.
  Report: https://claude.ai/artifact/JUwpSsMWHvXqjEsmLeHADQ. Example wording the owner
  read and accepted (bb kept in examples 8, 15, 18): https://claude.ai/artifact/Xd6qk866FFQJCbz9h5J9sH.
- One corner radius, 10, for cards, panels, seats, felt and controls (`GT.Radius.panel`
  and `.control`; owner chose "everything 10" on 2026-10-13). Nothing in the app's own
  shapes may follow the display curve. Pills and playing cards are separate.
- Phones: iPhone 12 mini has signed 1.0 (25), fresh install; iPhone 13 mini has build
  18. Build list: `docs/build-history.md`. The GRAC video and source freeze in
  `docs/grac-submission/2026-10-13/` are of 1.0 (22) at `4c191a6`; 23 differs from that
  source only by the build number and docs.
- Old sibling worktrees are archived at `.archive/2026-10-11-workspace-cleanup/`
  (`docs/workspace-cleanup.md`). Work only in this folder.
- Test environment: use the iPhone 17 iOS 26.5 simulator by id (the bare name picks the
  iOS 27 beta). After a rebuild, run
  `xcrun simctl uninstall <device> com.michaelju.glasstable.GlassTableUITests.xctrunner`
  before a UI run, or the simulator can run an old test bundle.

## Open issues

Owner decision:
- A lesson is marked cleared once every question is answered, right or wrong
  (`ProgressionModel.commitNodeAnswer`). The owner said only correct answers should
  count toward clearing; no pass mark is chosen, so the rule is unchanged.

Remove a line when it is resolved and say so in the session entry. Lines marked
(old) come from before 2026-10-05 and have not been re-checked since.

Never verified with people or hardware:
- Real novice comprehension; physical VoiceOver and haptics; minimum iOS 17 runtime;
  AX5 full scroll reachability on every route.
- (old) Store validation, metadata, rating, territories; system permission,
  notification, share and review flows; backup export/import; huge-history save latency.
- (old) GRAC: video format/size/simulator acceptance and the statutory Annex 2(8)
  radio; enrolment, counsel and submission are owner work.

Product and numbers:
- Numerical audit N08–N12 and model qualifications; graded-flop sampling sensitivity
  against the 0.5/2bb thresholds is not bounded (`docs/audits/2026-10-11-numerical/`).
- Build 15 crawl candidates never verified: short tap heights on ‘설명 접기’,
  ‘안내 건너뛰기’, ‘계산 보기’, ‘전체 차트 보기’, ‘크게 보고 핸드 찾기’; unlabelled buttons
  on free-table setup. Free-table review once paired 33% with "four wins in ten".
- Free-table dock/seat layout at 2–3 players: not confirmed closed; check `map.md`.
- At AX5 in English the "Decision help" pill is clipped in the raise header; the
  Korean AX5 raise title is cut inside its scroll box.
- iOS 27 beta only: Settings language switch does not re-render the screen.
- Proposed, never approved: README drift fix (four tracks vs nine units, question
  counts), topic-led summary, recent-topic Records, post-commit best-five explanation,
  versioned integrity plan for archive/format/session-ending persistence.
- (old) iOS 27 watchdog check on the affected phone; iPhone 16e AX walkthrough
  failure; live Bold Text redraw; tiny EV-loss grid labels; unseeded PotMath question
  identity; free raise 2BB presets and graded range/equity jargon.

Tests:
- `AccessibilityAuditTests/testPlayTable` (and `testPlayTableScrolled` once, 2026-10-13
  night) (contrast, no element named) on the iPhone 12
  mini simulator: failed overnight on 2026-10-13 including on older code, passed 4/4
  that afternoon, failed again in the final run and 4/4 right after, same code. The
  audited hand is fixed (seed 97) and simulator appearance/text size match iPhone 17,
  where it passes. Unexplained; measured text contrast is at least 5.2:1.
- `FreeDockFlowTests/testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes` fails
  on the iPhone 12 mini simulator on `main` (build 25) as well as on the guided-hand
  branch, three runs: the result text sits 1.5pt above its scroll area (line 160). It
  passed on iPhone 17 at `a469449`. Not investigated; first seen 2026-10-14.
- Build 24 had only the unit tests and three hand-rank UI tests on iPhone 17, not the
  full suite.
- Intermittent: `FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable` (iPhone 17),
  `FreeDockFlowTests/testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes`.
- Unused code seen and left: `ProgressionModel.shouldPresentFirstPlacement`, `seatSentence`.

## Recent sessions

### 2026-10-13 (Claude)

- Finished the audit follow-ups with the owner one by one: written example on every
  explanation page (`fcc1a78`), raise panel alignment (`c66a8d8`), hand-ranking
  question, shorter English, "Help / History / Guide" tabs, one-line turn facts at
  accessibility sizes (`7e9ac4b`), dock buttons no longer follow the display curve
  (`89a55c3`), store screenshots retaken (`9a1822f`, `4c191a6`).
- Full UI suite on iPhone 12 mini and iPhone 17 at `9a1822f`: 238 tests, 11 skipped,
  1 failed (the contrast audit). Final full run at `e3ef792`: iPhone 17 238 tests, 11
  skipped, 0 failed; iPhone 12 mini 1 failed (the contrast audit, see Open issues).
- Reorganized this file and the handoff rules in `AGENTS.md`; the archive is frozen.
- Build 23 (`dd7637b`): signed Release, build 22 uninstalled first, fresh install on
  the physical iPhone 12 mini, Korean first-run welcome seen and left unadvanced, no
  progress copied. Evidence in `.build/device-install-b23/`.
- Repository tidy-up at the owner's request: committed the October audits, reports,
  research, issue records and the UX crawler; ignored the GRAC packages; merged to
  `main`, pushed it, deleted the other branches.
- Hand rank page rebuilt (`170e2f0`), merged and pushed to `main` with the owner's
  approval; build 24 fresh installed on the iPhone 12 mini, welcome seen, no progress
  copied (`.build/device-install-b24/`).
- Lesson feedback from build 24 on `feat/lesson-feedback-clarity`: best five and hole
  cards strongest first, open river-card groups, rule of 2 explained, hint padding, then
  F2 and S1, then 1A, 1C, 2A, 3A (all owner's picks). Unit tests and the guided hand,
  restored-answer and accessibility-audit UI tests pass on iPhone 17; the full suite on
  the final commit was started and its result not read. On `a3a4d16` a partial 12 mini
  run failed `AccessibilityAuditTests/testPlayTable` and `testPlayTableScrolled`.

### 2026-10-14 (Claude)

- Owner: a near miss is wrong; only correct answers count. Applied to accuracy, miss
  streak, review rating, lesson result, Records ("exact N%") and sound (`a31472e`).
  Drills 425 + 75, app 91 unit tests and 57 UI tests (records, graded and learning
  flows, restored answers, smoke) passed on the 12 mini simulator. The full suite was
  not run on this commit; a full run of the previous commit on iPhone 17 was still
  going, no failures in the first 158 tests.
- Merged to `main` and pushed with the owner's approval. Build 25: build 24 uninstalled,
  fresh install on the iPhone 12 mini, welcome seen, no progress copied
  (`.build/device-install-b25/`).
- Next: owner tries build 25 and decides whether clearing a lesson needs a pass mark.
- Owner found "A hand together" stiff (wrapped button text, no freedom, question hard
  to find) and chose the mix of mocks B and A. Rebuilt `GuidedHandView` on
  `TableSurface` (new `spotlight` and `ringed`); the quiz, Previous, the "less help"
  replay and the seeded alternate deals are gone. Unit tests (93) and the four guided-hand UI
  tests pass (12 mini and iPhone 17 simulators); screens checked in both languages at
  normal size and samples at AX5. Full 12 mini run on `aafc0b5`: 317 passed, 3
  failed, none in the guided hand: the two Play table contrast audits (both pass on
  iPhone 17 with the table change) and the Play result scroll test below.
- A full run of `a469449` on iPhone 17 had 203 passed, then one failure
  (`FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable`, passed on a re-run),
  before a second run on the same simulator spoiled the rest. Do not run two test
  sessions on one simulator.
- Next: owner looks at the rebuilt hand and says whether to merge and install it.

### 2026-10-13 — GRAC gameplay recording (separate session)

- Recorded normal Release 1.0(22) UI on a dedicated fresh simulator from frozen source `4c191a690bcda0ef5d495b9730cd6a82ce2137d5`; 146 production files fingerprint `823347f2325216749d791086ee3491cf1aef499fa6ea768be769d743ae744ca6`. Production source showed no drift after capture. No demo injection or direct progress edits.
- Final video: `docs/grac-submission/2026-10-13/GlassTable_GRAC_1.0_22_2026-10-13.mp4`; identical copy in `/Users/michaelju/Downloads/GlassTable_GRAC_1.0_22_2026-10-13.mp4`. 31:01, H264, 1206×2622, 149,169,691 bytes, silent. SHA256 `4ad06ce8fea6d74acd71a4878b1c115440fb58879fd5eb24dd435b375b75c2a1`.
- Real footage covers Korean teaching and quizzes, quick 40-chip game ending at hand 3 on depletion, long 100-chip table with normal actions/payouts and visible free 100-chip replenishment at 14:26, four graded teaching hands, Records, responsible-use guidance and native version. Whole-game recap is not evidenced or claimed.
- Exact paste rows: `docs/grac-submission/2026-10-13/section-3.6.md`; provenance/timeline: `video-timeline.json`; checks and limits: `media-report.md`. Final complete VFR-aware decode exited 0 with no diagnostics; representative final frames independently accepted by root. Dedicated simulator shut down, prior three booted simulators preserved, no owned recorder/test processes remain. No upload, form submission, or commit.
