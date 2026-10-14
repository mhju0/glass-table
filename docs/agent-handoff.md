# Agent handoff

Read this at session start. It has three parts: the current state (rewritten, not
appended), the open issues (a living list), and the last few sessions. Rules for
keeping it are in `AGENTS.md`. Older history is in `git log -- docs/agent-handoff.md`
and the frozen `docs/handoff-archive/`; neither needs reading for normal work.

## Current state (2026-10-15)

- Local CI repair is prepared on `fix/ci-drills-typecheck-20261014`, not pushed or
  merged. It preserves owner build 28, fixes the two Xcode 26.3 expression limits,
  distributes complete UI classes across three independent serial runners and
  reconciles their compiled inventories/results. All normal gates remain enabled.
  Each job now allows 130 minutes; the app step stays at 110, leaving room for setup,
  retained Release checks and evidence upload.
- The cleaned Settings harness is prepared; the instrumented two-case diagnostic
  passed on Xcode 26.3 / iOS 18.5, but the cleaned normal unit→UI path is unverified.
  The Play accessibility repair, final native checks, full CI and merge remain pending.

- GRAC application submitted by owner on 2026-10-13: receipt `TG-OM-26-01177`, screenshot state **접수대기**, candidate 1.0(22). Private local record, working form answers, screenshots and prepared artifacts: `docs/grac-submission/2026-10-13/archive-index.txt`; Downloads backup `GlassTable_GRAC_신청보관_2026-10-13.zip`. Notion 10/13 task checked. Full final portal form export and payment receipt were not captured.

- Build 27 is in `main` (pushed with the owner's approval, 2026-10-14) and on the iPhone
  12 mini. It adds the clickable-controls look and the lesson pass mark to build 26.
- Build 28 (owner approved merge and install, 2026-10-14) is in `main`, pushed, and on
  the iPhone 12 mini. It holds the owner's build 27 notes: the "Who wins?" worked example opens with every card face up, then my hand,
  the opponent's hand and the winner (4 steps; the turn-then-river replay is gone);
  Hold'em basics hides the lone Previous before the answer; the "A hand together"
  invitation has 10pt corners, an outline, one fill and more room above the title; and
  swiping that invitation away no longer starts the next lesson.
- Lesson pass mark (owner, 2026-10-14, D47): a lesson or challenge is passed with two in
  three questions, rounded up, answered alone and exactly right (`PassMark`); only that
  clears it, and a clear is never taken back. Not passed: retry with new cards, the
  explanation, go on anyway, Done; the path shows "Not passed · best R/Q"
  (`NodeRecord.best`, optional, no schema bump). Records says "passed". The result screen
  now shows the score and which question had the hint, which amends D08.
- Clickable controls (in build 27): tappable
  things look tappable (owner, 2026-10-14). Rule 1: the top-left control always leaves
  the screen, and Previous sits beside the bottom action (`GTStepRow`). Look 2: every ✕,
  ‹, ••• and text action is an outlined rounded square with a grey border
  (`GTControlBackground`, `ChromeGlyph`, `GTOutlinedAction`). Gold stays for main buttons
  and things that need attention. Content under a top bar starts about 15pt lower.
  List and mocks: `.scratch/clickable-controls-2026-10-14/map.md`.
- Build 25 held the owner's build 24 lesson feedback
  (direct fixes, answer marking F2, white answer cards S1, picks 1A, 1C, 2A, 3A) and
  "a near miss is wrong". Mocks: https://claude.ai/artifact/9GBTnNb66MwufA7B19rG7e and
  https://claude.ai/artifact/8aPmc5HftjZcezcpN6TkYs. Items and limits:
  `.scratch/lesson-feedback-2026-10-13/map.md`.
- "A hand together" is rebuilt on the Play table (`aafc0b5`, in build 26): one fixed two-player hand with the real action buttons,
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
- `main` holds all work and matches `origin/main` (owner asked to push and sync,
  2026-10-14). The standing rule is still to work on a feature branch and not push `main`
  unasked. Merged feature branches were deleted locally and on `origin` (2026-10-14).
  `fix/ci-drills-typecheck-20261014`, `fix/a11y-playtable-20261014` and
  `diagnostic/a11y-playtable-20261014` belong to a separate session (worktrees in
  `/private/tmp/`) and are not merged.
- Local only, ignored: `docs/grac-submission/` (videos, forms; public repo), tool
  caches, compiled probe output. Nothing else is untracked.
- Decisions and evidence for the follow-ups: `.scratch/audit-followups-2026-10-11/map.md`.
  Report: https://claude.ai/artifact/JUwpSsMWHvXqjEsmLeHADQ. Example wording the owner
  read and accepted (bb kept in examples 8, 15, 18): https://claude.ai/artifact/Xd6qk866FFQJCbz9h5J9sH.
- One corner radius, 10, for cards, panels, seats, felt and controls (`GT.Radius.panel`
  and `.control`; owner chose "everything 10" on 2026-10-13). Nothing in the app's own
  shapes may follow the display curve. Pills and playing cards are separate.
- Phones: iPhone 12 mini has signed 1.0 (28), fresh install; iPhone 13 mini has build
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
- GRAC: owner submitted 1.0(22), now awaiting processing, any corrections, rating and RCN. Reviewer installation is unverified: development IPA permits only two registered devices; TestFlight upload/invite not performed. Confirm delivery with GRAC if needed. Video/simulator acceptance and statutory Annex 2(8) final selection remain unverified; working answers are not a final portal export.

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
- Clickable controls (not yet raised with the owner): the Play top-bar title stops
  growing at the first accessibility size, so the AX dock keeps its height. The walkthrough,
  hand review and learning guide keep equal-width Previous/Next; the guide and Hold'em
  basics use the 36/64 `GTStepRow`.
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
- Build 24 had only the unit tests and three hand-rank UI tests on iPhone 17, not the
  full suite.
- Intermittent: `FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable` (iPhone 17),
  `FreeDockFlowTests/testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes`.
- Unused code seen and left: `ProgressionModel.shouldPresentFirstPlacement`, `seatSentence`.

## Recent sessions

### 2026-10-15 (Codex · CI repairs, local integration)

- Five owner-notification runs share the quick-game `#expect` compile timeout.
  Split its integer sums and the walkthrough header calculations without changing
  assertions, arithmetic order, displayed text or accessibility labels.
- Full run `38550187331` hit the 110-minute app limit: 98 XCTest and 46 Swift Testing
  app tests passed; 96 UI tests passed and the Play audit failed contrast/Dynamic
  Type before timeout. Retained xcresult is incomplete; raw log preserves the batch.
- Accepted CI commits `83475d4`, `c2704f4`, `9c07d40` now distribute complete classes
  across three serial runners and reconcile method/argument inventories and only
  the existing opt-in crawler skips. No tests are removed from the normal gate.
- Settings diagnostic `38583124780` passed 2/2, including single-tap changes, relaunch
  persistence and both language choices. Cleaned test-only `90c05bf` is integrated
  locally; this does not prove the original activation flake's cause or that waiting
  fixed it. Normal unit→UI validation is still required.
- Scoped protocol `38581110047` at reviewed source `afe4042` completed successfully,
  including strict result reconciliation, Release launch and device contents checks.
  It does not establish the full three-shard/native candidate; artifact counts and
  detailed durations await readback. Measured setup was about 3 minutes and retained
  post-app Release/device work exceeded 11, so accepted `2c6bcca` raises only the job
  budget from 120 to 130 minutes; app testing remains capped at 110.
- Local checks on the integrated source: screenshot tool 20 and CI helper 23 tests
  pass; Drills 427 XCTest plus 75 Swift Testing pass; Engine Release 96 XCTest pass.
  Workflow YAML/shell syntax passes. These are local Xcode 27 checks, not final CI
  or native verification. Raw logs: `/tmp/glass-table-ci-evidence-20261014/`.
- Integrated only remote main `9664c0a` handoff cleanup. The owner's architecture
  branch `d2e1092` remains unmerged and untouched. No diagnostic workflows or proposed
  renderer changes are integrated. Next: accepted Play repair, frozen final review,
  native/full CI validation, then root delivery decision.


### 2026-10-14 (Claude · build 27 feedback)

- Owner on build 27: the "Who wins?" example starting on the turn was confusing; the
  lone "이전" on the basics check page looked stray; the invitation sheet's corners and
  tight top did not match the app. Also: after basics, closing the invitation still
  opened a lesson. Cause: the sheet's `onDismiss` treated a swipe-down like "Continue
  lessons"; now only the button continues. The turn-first order came from `acc6f17`
  ("teaches the reading"), before the beginner direction.
- On `fix/build27-feedback`. Drills 427 XCTest + 75 Swift Testing pass (two turn/river
  tests replaced by one face-up test). New UI test
  `testKoreanSwipingTheInvitationAwayStaysOnLearn` failed on the old code and passes now;
  invitation, learning, first-lesson, accessibility flow, presentation and welcome UI
  classes pass on two 12 mini simulators. Screens checked in Korean dark and English
  light at normal and AX5. The sweep's showdown frames are now beats 0, 1, 3, plus a
  `guided-invitation` entry.
- Owner approved merge and install, then asked to push `main` and sync; both pushed.
  Build 28: build 27 uninstalled, fresh install on the iPhone 12 mini,
  welcome seen, no progress copied (`.build/device-install-b28/`).
- Next: owner tries build 28.

### 2026-10-14 (Claude · lesson pass mark, build 27)

- Owner took all four pass-mark picks (D47) and approved merge, push and install. Built
  `PassMark`, `NodeRecord.best`, the passed / not-passed result screen with per-question
  marks and retry, the path's "Not passed · best R/Q" and "passed" in Records (`bb852ee`).
  Two tests were renamed on purpose: an all-wrong or help-only lesson no longer clears.
  The mark rows use the light `GT.glass` fill: on the felt panel tint the green measured
  4.46:1 and failed the summary contrast audit.
- Tests: Drills 428, app 98 unit; full UI suite on two 12 mini simulators, 228 tests,
  3 failed: the summary audit (fixed, passed on the rebuild) and the two known Play table
  audits. The new retry and not-passed UI tests pass. Screens checked in Korean dark and
  English light at normal and AX5.
- Merged by fast-forward to `main` (`10744ab`) and pushed with the branches. Build 27:
  build 26 uninstalled, fresh install on the iPhone 12 mini, welcome seen, no progress
  copied (`.build/device-install-b27/`). The GRAC handoff notes from the other session
  were committed separately (`46f29ab`), so receipt TG-OM-26-01177 is now in the public repo.
- Next: owner tries build 27.

### 2026-10-14 (Claude · clickable controls)

- Owner chose Rule 1 and then Look 2 with the grey outline (mocks
  https://claude.ai/artifact/Tb5PRceX4YUUPoTJwAffKr and
  https://claude.ai/artifact/BdUFji5QcrzLN9K16YKDJY). Built on
  `feat/guide-clickable-controls`, not merged or installed. The guide and Hold'em basics
  lost their top-left Previous; the lesson's leftover 8pt top padding was dropped.
- To keep the AX dock tests passing, the Play top-bar title stops growing at the first
  accessibility size. The shared AX test helper `scrollUntilFullyVisible` now ends with
  short drags, because one swipe threw the hero cards past the top.
- 12 mini simulators: unit tests and every UI class ran across three builds. Only the
  two known contrast audits failed. Two other failures were fixed and passed on the final
  build: the hero test (helper) and the lesson-title gap. The final build itself ran 16
  UI classes plus the unit tests, with no failures. Screens checked in both languages at
  normal and AX5.
- Next: owner looks at the branch and decides on merge and install.

### 2026-10-13 (Codex · GRAC submission archive)

- Preserved owner submission screenshot and receipt TG-OM-26-01177 (접수대기), refund terms, working form answers, version-22 video/timestamps, PDFs, IPA and upload ZIP. Re-fetched Notion and confirmed completed 10/13 checkbox. Archive CRC and file hashes checked; no rating approval, payment receipt, reviewer install or final portal field export claimed. Next: GRAC response and installation support if requested.
