# Agent handoff

Read this at session start. It has three parts: the current state (rewritten, not
appended), the open issues (a living list), and the last few sessions. Rules for
keeping it are in `AGENTS.md`. Older history is in `git log -- docs/agent-handoff.md`
and the frozen `docs/handoff-archive/`; neither needs reading for normal work.

## Current state (2026-10-15)

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
- `main` holds all of this session's work and matches `origin/main`. The standing rule is still to work on a feature branch and not push `main`
  unasked. Merged feature branches were deleted locally and on `origin` (2026-10-14).
  The Codex `fix/*-2026101[45]` and `diagnostic/*` branches are kept for reference and
  not merged; their worktrees are gone (see the cleanup line below).
- Build 29 (owner asked to push `main` and install, 2026-10-15) is in `main`, pushed,
  and on the iPhone 12 mini. Over build 28 it adds animation polish (audit plans in
  `plans/`, motion tokens `GT.Motion.fade`/`.move`, near-full-size board cards, the
  skill-glyph accent) and four refactors that move rules into Drills:
  `PracticeRaiseBlock`, `BeginnerJourney` (RootView's cover order), `ConceptReveal`
  (reveal text, seat labels on `Position`) and `GradedSession` (draft/answer/next for
  rounds, reviews and lessons; no schema change).
- Lesson review for the owner (2026-10-15): https://claude.ai/artifact/1BH6g7owTwjnEjKmDfBHX1
  — every lesson in order, why, goals, and a never-played reading. Its findings are
  under Open issues.
- Merged to `main` with the owner's approval (2026-10-15): `ci/lean-pipeline-20261015`
  (PR #12) and `fix/ux-lesson-gaps-20261015` (lesson review gaps and most of the
  screenshot UX audit, `.scratch/screenshot-ux-audit-2026-10-15/report.html`).
- CI/CD (owner chose "simpler CI, I take over" and "TestFlight on tag"): `ci.yml` gates
  pushes/PRs on unit tests plus the Release smoke and bundle checks; `ui-tests.yml` runs
  the UI suite nightly in three shards; `release.yml` uploads a `v<version>-<build>` tag
  on `main` to TestFlight. Setup steps: `docs/ci-cd.md`. The App Store Connect API key
  is not ready yet (owner, 2026-10-15), so no secrets are set and no tag has shipped.
- Worktree cleanup (owner, 2026-10-15): all 25 `/private/tmp/glass-table-*` worktrees
  were removed; their branches remain. Uncommitted changes, untracked files and
  `.build` evidence (no caches) are in `.archive/2026-10-15-worktree-cleanup/`, with the
  Codex session's uncommitted handoff edit. No Codex process was running in this repo.
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

Lesson path (from the 2026-10-15 lesson review; owner decisions, not code bugs):
- Call or fold, the decision price-and-chance builds to, has no lesson; it is only in
  the optional u2 challenge. Outs sits second in the suggested order with no recorded
  reason (`c31a5c7`). Rules pages (pot, blinds, flow) stay optional; the glossary now
  defines those words. Chen score is never explained.
- Outs beginner choices can be 1 apart while only exact answers count (left: exact
  counting is the skill). Pot-odds/MDF choices were fixed on `fix/ux-lesson-gaps-20261015`.
- Starting check (D46 item 3) is reachable only by a DEBUG hook; Settings has no entry
  (removed on purpose in `7549a32`).

Screenshot UX audit (`.scratch/screenshot-ux-audit-2026-10-15/report.html`), left for
the owner on `fix/ux-lesson-gaps-20261015`:
- #29 fold the graded-table guide by default (conflicts with the remembered-collapse
  test and its decision); #52 hand-specific chart reason wording; #34/#41 visible rank
  headers on the compact grid; taste items (container weight, gutters, palette).

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

CI/CD:
- `release.yml` has never run: it needs the paid Apple Developer membership, an App Store
  Connect app record and the four secrets in `docs/ci-cd.md`. Whether an App Manager
  API key is enough for cloud signing is unknown; the doc says Admin.
- `ui-tests.yml` can only be started by hand once it is on `main`. The full UI suite has
  not passed on a GitHub runner; the Codex diagnostic runs (2026-10-14/15) failed
  accessibility audits there.

Tests:
- `AccessibilityAuditTests/testPlayTable` (and `testPlayTableScrolled` once, 2026-10-13
  night) (contrast, no element named) on the iPhone 12
  mini simulator: failed overnight on 2026-10-13 including on older code, passed 4/4
  that afternoon, failed again in the final run and 4/4 right after, same code. The
  audited hand is fixed (seed 97) and simulator appearance/text size match iPhone 17,
  where it passes. Unexplained; measured text contrast is at least 5.2:1.
  On 2026-10-15 both failed on unchanged `main` 467864a on the 12 mini simulator too
  (Dynamic Type partial, potentially inaccessible text).
- Build 24 had only the unit tests and three hand-rank UI tests on iPhone 17, not the
  full suite.
- Intermittent: `FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable` (iPhone 17),
  `FreeDockFlowTests/testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes`.
- Unused code seen and left: `ProgressionModel.shouldPresentFirstPlacement`, `seatSentence`, `TodayView`, `Beat.hidden`, WalkthroughView flip code, PrimaryCTA/FeltCTA duplicate, `SolvedWithHelpLabel`, `SessionAttemptLedger`.

## Recent sessions

### 2026-10-15 (Codex · revised screenshot UX report)

- Owner requested a thorough critique, then supplied eleven more screenshots after
  clicking and scrolling. Rebuilt the report from all fifteen images: 69 prioritized
  findings. Recommendations only; no app change or simulator verification. (Recorded
  from Codex's uncommitted edit, archived in `.archive/2026-10-15-worktree-cleanup/`.)

### 2026-10-15 (Claude · lesson and UX audit gaps)

- Owner asked to fix the gaps in the lesson review and the screenshot UX audit, after
  re-auditing the latter. Branch `fix/ux-lesson-gaps-20261015`, two commits.
- Lesson grading: a lesson's defend question now starts with the chart folded
  (`chartStartsFolded`), so it can be answered alone under D47; opening the chart still
  marks help. Pot-odds/MDF beginner choices now sit at least 15 points apart
  (`BeginnerQuestionChoices.shares`), so only one grades right. Both had failing tests
  first (UI test and Drills test).
- Copy and screens: 플롭 → 플랍; glossary adds pot, blinds, dealer button, position,
  actions, streets and showdown; equity and range-read how-lines match their questions;
  the table review names the street it grades, the call price and the chart scope; a
  finished hand shows only dealt cards; setup has a back button, "me + N computers",
  and plainer length and style copy; the chart marks your own hand apart from the one
  being inspected, explains T, and shows the plain hand name.
- Verified: Drills tests, 85 UI tests on two 12 mini simulators, and a uisweep of 11
  changed screens at large and AX5. The two play-table audit failures also fail on
  unchanged `main`.
- Left for the owner: see Open issues (audit #29/#52/#34/#41, call-or-fold lesson,
  starting check, outs choices).
- Owner approved merging both branches; done via PR #12 and the fix branch PR.
- Next: owner decides the items left open; before/after mocks were published.

### 2026-10-15 (Claude · lean CI and TestFlight)

- Owner asked for proper CI/CD and chose a lean pipeline over the Codex 3×130-minute
  shard work. Ported Codex's two Xcode 26.3 type-check splits (`WalkthroughView`
  header, `PracticeTableQuickGameTests`) without its handoff edits; main CI had failed on
  them. Push CI now runs unit tests only; the UI suite moved to a nightly workflow;
  tags ship to TestFlight.
- Verification: Drills tests and the app build pass locally; CI run 38591907357 passed on
  the branch in 22 minutes (unit tests 5, Release smoke 12, device Release build 3).
- Next: owner merges the branch, stops the Codex CI session, then does the one-time
  TestFlight setup in `docs/ci-cd.md` and pushes the first tag.

### 2026-10-15 (Claude · build 29, lesson review)

- Owner asked to push `main`, install, and keep only `main`. Main fast-forwarded to the
  refactor stack and the animation commits were replayed on top (no conflicts), build
  number 29. On the combined source: Drills 427 + 95, app 97 unit, 128 UI tests on two
  12 mini simulators (Play table, raise, motion, guided hand, invitation, graded and
  learning flows, beginner release, restored presentation, welcome), no failures.
  Build 28 uninstalled, fresh install of 1.0 (29), welcome seen, no progress copied
  (`.build/device-install-b29/`).
- Branch cleanup: this session's branches and its animation worktree were removed. The
  other session's a11y/CI diagnostic branches and `/private/tmp` worktrees were left:
  a Codex session was still using them (live `gh run watch`, fresh edits).
- Owner asked for a review of every lesson from a never-played view; published above.
  The defend finding was checked by reading the code myself.
- Next: owner tries build 29, reads the lesson review, and decides what to fix.

### 2026-10-14 (Claude · animation fixes and architecture refactors)

- Owner asked for all three animation audit fixes, then every Strong candidate of the
  architecture review. Animation plans were executed by a subagent in a worktree and
  reviewed; four refactors each move a rule from app views or the model into Drills,
  with Drills tests. Branches are listed under Current state; none is merged.
- Behaviour kept: the raise reasons were checked against the old view logic on 400
  random hands; the reveal text against the old builder in 95,360 cases (temporary
  test, not kept). The live drill's fallback reveal strings were never shown and are
  gone. A corrupt out-of-range review or lesson ordinal now returns false instead of
  crashing.
- Tests: Drills 427 XCTest + 95 Swift Testing; app 97 unit. UI on 12 mini simulators,
  no failures: guided hand, invitation, welcome, beginner release, restored parity
  (journey); restored presentation, numerical reveal, bilingual B20, learning (reveal);
  graded learning/dock, learning, device-feedback lesson, numerical records (graded);
  free raise and dock (raise); guided-hand flow, invitation, free dock (animation).
  No full suite and no screenshot sweep; no layout changed except the animations.
- Left: PlayView's setup↔table loop was not moved; worktree
  `.claude/worktrees/agent-ab78e6dade09f5213` still exists.
- Next: owner reviews the branches and decides on merge and install (done 2026-10-15).
