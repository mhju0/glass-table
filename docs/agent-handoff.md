# Agent handoff

Read this at session start. It has three parts: the current state (rewritten, not
appended), the open issues (a living list), and the last few sessions. Rules for
keeping it are in `AGENTS.md`. Older history is in `git log -- docs/agent-handoff.md`
and the frozen `docs/handoff-archive/`; neither needs reading for normal work.

## Current state (2026-10-13)

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
- One corner radius: `GT.Radius.control` (10) for seats, felt, bottom panel and controls.
  Nothing in the app's own shapes may follow the display curve (owner, 2026-10-13).
  Pills, playing cards and `GT.Radius.panel` cards are separate.
- Phones: iPhone 12 mini has signed 1.0 (24), fresh install; iPhone 13 mini has build
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
- `AccessibilityAuditTests/testPlayTable` (contrast, no element named) on the iPhone 12
  mini simulator: failed overnight on 2026-10-13 including on older code, passed 4/4
  that afternoon, failed again in the final run and 4/4 right after, same code. The
  audited hand is fixed (seed 97) and simulator appearance/text size match iPhone 17,
  where it passes. Unexplained; measured text contrast is at least 5.2:1.
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
- Next: owner tries build 24 on the phone.

### 2026-10-13 — GRAC gameplay recording (separate session)

- Recorded normal Release 1.0(22) UI on a dedicated fresh simulator from frozen source `4c191a690bcda0ef5d495b9730cd6a82ce2137d5`; 146 production files fingerprint `823347f2325216749d791086ee3491cf1aef499fa6ea768be769d743ae744ca6`. Production source showed no drift after capture. No demo injection or direct progress edits.
- Final video: `docs/grac-submission/2026-10-13/GlassTable_GRAC_1.0_22_2026-10-13.mp4`; identical copy in `/Users/michaelju/Downloads/GlassTable_GRAC_1.0_22_2026-10-13.mp4`. 31:01, H264, 1206×2622, 149,169,691 bytes, silent. SHA256 `4ad06ce8fea6d74acd71a4878b1c115440fb58879fd5eb24dd435b375b75c2a1`.
- Real footage covers Korean teaching and quizzes, quick 40-chip game ending at hand 3 on depletion, long 100-chip table with normal actions/payouts and visible free 100-chip replenishment at 14:26, four graded teaching hands, Records, responsible-use guidance and native version. Whole-game recap is not evidenced or claimed.
- Exact paste rows: `docs/grac-submission/2026-10-13/section-3.6.md`; provenance/timeline: `video-timeline.json`; checks and limits: `media-report.md`. Final complete VFR-aware decode exited 0 with no diagnostics; representative final frames independently accepted by root. Dedicated simulator shut down, prior three booted simulators preserved, no owned recorder/test processes remain. No upload, form submission, or commit.
