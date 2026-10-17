# Agent handoff

Read this at session start. It has three parts: the current state (rewritten, not
appended), the open issues (a living list), and the last few sessions. Rules for
keeping it are in `AGENTS.md`. Older history is in `git log -- docs/agent-handoff.md`
and the text records in `docs/records/`; neither needs reading for normal work.

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
  List and mocks: `docs/records/2026-10-14-clickable-controls.md`.
- Build 25 held the owner's build 24 lesson feedback
  (direct fixes, answer marking F2, white answer cards S1, picks 1A, 1C, 2A, 3A) and
  "a near miss is wrong". Mocks: https://claude.ai/artifact/9GBTnNb66MwufA7B19rG7e and
  https://claude.ai/artifact/8aPmc5HftjZcezcpN6TkYs. Items and limits:
  `docs/records/2026-10-13-lesson-feedback.md`.
- "A hand together" is rebuilt on the Play table (`aafc0b5`, in build 26): one fixed two-player hand with the real action buttons,
  a coach card (Now / Look at / Think), the coach's pick marked on a button, a dimmed
  spotlight on the first steps, and a question before giving up. The owner chose "the
  mix of B and A" from https://claude.ai/artifact/45hN7vNa15ru28nfsHovcR. Notes and
  limits: `docs/records/2026-10-14-guided-hand-on-table.md`.
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
  The Codex `fix/*`, `diagnostic/*` and `rollback/*` branches and PR #11 were closed and
  deleted on 2026-10-15 (`docs/records/2026-10-14-codex-ci-repair.md`).
- Build 29 (owner asked to push `main` and install, 2026-10-15) is in `main`, pushed,
  and on the iPhone 12 mini. Over build 28 it adds animation polish (audit plans in
  `docs/records/2026-10-14-animation-plans.md`, motion tokens `GT.Motion.fade`/`.move`, near-full-size board cards, the
  skill-glyph accent) and four refactors that move rules into Drills:
  `PracticeRaiseBlock`, `BeginnerJourney` (RootView's cover order), `ConceptReveal`
  (reveal text, seat labels on `Position`) and `GradedSession` (draft/answer/next for
  rounds, reviews and lessons; no schema change).
- Lesson review for the owner (2026-10-15): https://claude.ai/artifact/1BH6g7owTwjnEjKmDfBHX1
  — every lesson in order, why, goals, and a never-played reading. Its findings are
  under Open issues.
- Merged to `main` with the owner's approval (2026-10-15): `ci/lean-pipeline-20261015`
  (PR #12) and `fix/ux-lesson-gaps-20261015` (lesson review gaps and most of the
  screenshot UX audit, `docs/records/2026-10-15-screenshot-ux-audit.md`).
- Owner decisions on the lesson review and UX audit (owner liked every suggestion in
  https://claude.ai/artifact/6gcHb6SVBTLnkBmhog7TvY, 2026-10-15) are on
  `feat/owner-decisions-20261015`: chart guide opens only the first time, a
  hand-specific chart reason (`DefendChart.reason`), a verdict-first table review with
  "Details", and a call-or-fold lesson `u2-callFold` before the price challenge.
  Merged as PR #14 and installed as build 30 on the iPhone 12 mini (owner, 2026-10-15).
- CI/CD (owner chose "simpler CI, I take over" and "TestFlight on tag"): `ci.yml` gates
  pushes/PRs on unit tests plus the Release smoke and bundle checks; `ui-tests.yml` runs
  the UI suite nightly in three shards; `release.yml` uploads a `v<version>-<build>` tag
  on `main` to TestFlight. Setup steps: `docs/ci-cd.md`. The App Store Connect API key
  is not ready yet (owner, 2026-10-15), so no secrets are set and no tag has shipped.
- Records cleanup (owner, 2026-10-15): every finished report, audit, research note,
  scratch folder, plan and old handoff is now one short text record in `docs/records/`
  (index in its README); originals are in git at `f5c5e22`. Local `.build/`, `.archive/`
  and old build folders were deleted (about 24 GB). The line-parity OCR check moved to
  `tools/line-parity/`.
- Local only, ignored: `docs/grac-submission/` (videos, forms; public repo), package
  build caches, the generated Xcode project. Nothing else is untracked.
- Decisions and evidence for the follow-ups: `docs/records/2026-10-11-audit-followups.md`.
  Report: https://claude.ai/artifact/JUwpSsMWHvXqjEsmLeHADQ. Example wording the owner
  read and accepted (bb kept in examples 8, 15, 18): https://claude.ai/artifact/Xd6qk866FFQJCbz9h5J9sH.
- One corner radius, 10, for cards, panels, seats, felt and controls (`GT.Radius.panel`
  and `.control`; owner chose "everything 10" on 2026-10-13). Nothing in the app's own
  shapes may follow the display curve. Pills and playing cards are separate.
- Phones: iPhone 12 mini has signed 1.0 (30), fresh install; iPhone 13 mini has build
  18. Build list: `docs/build-history.md`. The GRAC video and source freeze in
  `docs/grac-submission/2026-10-13/` are of 1.0 (22) at `4c191a6`; 23 differs from that
  source only by the build number and docs.
- Work only in this folder; there are no other worktrees.
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
- Outs sits second in the suggested order with no recorded
  reason (`c31a5c7`). Rules pages (pot, blinds, flow) stay optional; the glossary now
  defines those words. Chen score is never explained.
- Kept on purpose (owner, 2026-10-15): outs beginner choices can be 1 apart because
  exact counting is the skill; the starting check stays out of Settings (`7549a32`);
  audit #34/#41 compact-grid rank headers stay as they are.

Product and numbers:
- Numerical audit N08–N12 and model qualifications
  (`docs/records/2026-10-11-numerical-audit.md`). Graded-flop sampling is gone: the flop
  is exact on `feat/exact-flop-equity-20261016` (D49), once merged.
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
  counts), topic-led summary, recent-topic Records,
  versioned integrity plan for archive/format/session-ending persistence.
- (old) iOS 27 watchdog check on the affected phone; iPhone 16e AX walkthrough
  failure; live Bold Text redraw; tiny EV-loss grid labels; unseeded PotMath question
  identity; free raise 2BB presets and graded range/equity jargon.

CI/CD:
- `release.yml` has never run: it needs the paid Apple Developer membership, an App Store
  Connect app record and the four secrets in `docs/ci-cd.md`. Whether an App Manager
  API key is enough for cloud signing is unknown; the doc says Admin.
- `ui-tests.yml` can only be started by hand once it is on `main`. The full UI suite has
  not passed on a GitHub runner (see `docs/records/2026-10-14-codex-ci-repair.md`).

Tests:
- `AccessibilityAuditTests/testPlayTable` fails on `main`: 0/3 on iPhone 17 iOS 26.5 on
  2026-10-15 (contrast and partial Dynamic Type on the free-table title), also on the
  12 mini. The fixes carried from PR #11 to `fix/a11y-play-captions-20261015` make it
  pass 3/3; that PR awaits the owner (it changes the dock caption colour to `GT.ink`
  and draws captions with a UIKit label).
- Build 24 had only the unit tests and three hand-rank UI tests on iPhone 17, not the
  full suite.
- Intermittent: `FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable` (iPhone 17),
  `FreeDockFlowTests/testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes`.
- Unused code seen and left: `ProgressionModel.shouldPresentFirstPlacement`, `seatSentence`, `TodayView`, `Beat.hidden`, WalkthroughView flip code, PrimaryCTA/FeltCTA duplicate, `SolvedWithHelpLabel`, `SessionAttemptLedger`.

## Recent sessions

### 2026-10-16 (Claude · exact flop equity)

- Owner approved replacing the graded table's 200-sample flop equity with exact
  enumeration (D49). Branch `feat/exact-flop-equity-20261016` from the local
  integration commit `9bb6c66` (PRs #19-#21); PR opened, not merged.
- `exactEquitiesHeadsUp` (Engine) scores hero once per runout and shares it across the
  range; `TableHand.comboEquities()` uses it on every street. `handSeed` was removed.
  Reveal basis copy (KO/EN) no longer calls the flop a sampled estimate.
- Grading already ran off the main thread (`TableView.prepareOptions`); only the
  DEBUG `GT_DEMO_TABLE_STEP` hook grades on main (about 0.4-0.6s for its flop).
- Release per flop decision on an M1 Pro, 200 seeded decisions: p50 41ms, p95 159ms,
  max 196ms. Debug: about 1-2.5s. Not yet timed on the iPhone 12 mini.
- Next: owner reviews the PR; time a flop decision on the phone against D07's 200ms.

### 2026-10-16 (Claude · best five after answering)

- Owner approved option A (D50). Branch `feat/best-five-comparison-20261016` from the
  local integration commit `9bb6c66`; PR open, not merged.
- `BestFivePair` (Drills) and `BestFiveComparison` (app) show each player's seven
  cards with the unused two dimmed, the hand name, a count line and a ringed deciding
  card, after the answer only: "Who wins?", its restored answer, the hand review's
  ending and the Hold'em basics check. Owner then asked for the first basics check
  (flush against straight) to be dealt from seven cards as well (`HoldemBasics.firstCheck`).
- Fixed on the way: the kicker sentence compared ranks high-to-low instead of in
  evaluation order, and wrote "6라서".
- Debug hooks: `GT_DEMO_SHOWDOWN_SPOT` (every showdown spot), `GT_DEMO_BASICS_SEED`.
- The why sentence now appears once, under the rows; the "Who wins?" sheet and its
  restored sheet no longer repeat it (owner chose this, 2026-10-17).
- Next: merge PR #23.

### 2026-10-15 (Claude · records cleanup and PR #11)

- Owner asked to turn every report, audit and scratch folder into compact text, keep
  less in the repo and locally, and deal with PR #11 by Claude's judgment.
- 627 tracked originals (HTML reports, screenshots, ledgers, mocks, `.scratch/`,
  `plans/`, old handoffs) became 31 records in `docs/records/` with an index; links
  repointed. Rule added to AGENTS.md and `docs/agents/issue-tracker.md`: finished work
  becomes one record, originals are not kept. Local `.build/`, `.archive/`, old build
  folders and the untracked UX report were deleted after `2026-10-15-local-archives.md`
  captured them (about 24 GB). `docs/grac-submission/` kept: it is the filed GRAC record.
- PR #11 closed: its CI design lost to the lean CI, and its timeout fixes were already in
  `main`. Its three accessibility fixes and four UI test commits moved to
  `fix/a11y-play-captions-20261015` (testPlayTable 0/3 → 3/3 on iPhone 17). Codex's
  experiment branches deleted; their SHAs are in the record.
- Next: owner looks at the caption PR and tries build 30.

### 2026-10-15 (Claude · owner decisions)

- Owner approved every suggestion in the before/after artifact and merging PR #13
  (done once its gate passed). Branch `feat/owner-decisions-20261015`.
- Chart guide: `ChartGuideMemory` (per-store UserDefaults) opens "How to read the chart"
  only on the first chart. Chart reason: the preflop takeaway states the opener's
  range, the call and re-raise slices, and where this hand ranks by Chen combos.
- Review panel: verdict and takeaway first, then one row of outlined tiles (Details,
  chart, policy; outlined, not the mock's gold links, per the clickable-controls rule);
  prices and basis sit behind Details.
- Call-or-fold lesson: new node `u2-callFold` (after `u2-evCall`, before `u2-boss`) on
  the price track. Its questions show both shares (`callFoldLessonNumbers`); the
  challenge does not. The boss keeps `own: .callFold` so saved challenge sessions stay
  valid, so call-or-fold is the one concept taught twice. Challenge rows on the path now
  read "Mixed practice". No schema change; the new lesson shows as not started.
- Kept: outs choices, starting check, compact-grid headers (#34/#41).
- `docs/ci-cd.md` records the first nightly UI run: shard 1 failed only
  `testPlayTable`, a pre-existing failure on `main`.
- Owner asked to merge and install: PR #14 merged, build 30 installed on the iPhone 12
  mini after an uninstall (fresh data).
- Cleanup (owner, 2026-10-15): removed the `owner-decisions` and `ux-lesson-gaps`
  worktrees and the three merged branches (local and `origin`); their install and
  screenshot evidence is summarized in `docs/records/2026-10-15-local-archives.md`. Builds
  27–30 added to `docs/build-history.md`. Draft PR #11 left open: it still holds
  Play and free-table accessibility fixes not in `main`.
- Next: owner tries build 30.

### 2026-10-15 (Codex · revised screenshot UX report)

- Owner requested a thorough critique, then supplied eleven more screenshots after
  clicking and scrolling. Rebuilt the report from all fifteen images: 69 prioritized
  findings. Recommendations only; no app change or simulator verification. (Recorded
  from Codex's uncommitted edit, archived locally, since deleted.)
