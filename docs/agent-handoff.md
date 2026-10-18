# Agent handoff

Read this at session start. It has three parts: the current state (rewritten, not
appended), the open issues (a living list), and the last few sessions. Rules for
keeping it are in `AGENTS.md`. Older history is in `git log -- docs/agent-handoff.md`
and the text records in `docs/records/`; neither needs reading for normal work.

## Current state (2026-10-18)

- Build 35 (owner held it until all of this was in, 2026-10-18): `main` at `d910f99`
  via integration PR #53 (PRs #42–#52), tag `v1.0-35`, TestFlight upload only. Adds:
  - Steps (D53, schema 5): every skill but MDF is dealt at Learn → Apply → Sharp
    (`DrillLevel`, nodes `<id>.2/.3`); Strong needs a perfect Apply/Sharp session,
    Mastered a perfect Sharp challenge. Learn spots are byte-identical (golden tests).
    Go deeper has a challenge (`deeper-boss`). Graded 1:1 decisions are saved as daily
    mode "table". Golden fixture `schema4-build35.json`.
  - Learn mark follows the learner (D52, schema 4, `lastNodeID`); Chen card opens by default.
  - Play tab as a list (P2·A, `PlayView`, `PlayGlyph`); Progress tab rebuilt around
    numbers that only grow (`ProgressOverview`, `ProgressSummaryView`; no goal picker,
    no badges; `PracticeActivityOverview` deleted).
  - Largest text (D54): dense table parts stop at AX3 via `gtTablePartTextCap()`. Its
    press-and-hold Large Content Viewer was removed at the build gate: it swallowed
    scroll drags at AX sizes (11 UI failures).
  - EV call answer no longer always the middle choice; UI shards balanced by minutes.
- Owner rule (2026-10-18): keep the app simple and automatic; no pickers or settings.
- Left out on purpose: free-table "hands played" milestone (needs a new key); a
  separate Sharp segment on the Progress stage bars (tiers already follow steps).

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
- TestFlight (2026-10-17): builds 31–34 shipped by `v1.0-<build>` tags through
  `release.yml`; the four App Store Connect secrets are set. Build 34 = `main` at
  `f7f4ab4` (PRs #23–#35: best five, live language switch, help tiles at AX, lowercase
  English hand names, concentric sheet corners, a finished lesson no longer blocks
  others, outs answer as hand-type rows with inset gold strokes, the kicker as the third
  basics check, Learn as the lesson list (D51, `PathView` gone), 원 페어/투 페어 spaced).
  ASC app name "Glass Table", age rating and English localization are set; category and
  stale metadata are not. Upload only; no App Store review submission (D23).
- Unconfirmed whether the owner has added themselves as an internal tester (App Store
  Connect → TestFlight → Internal Testing; no invite code is needed).
- No open PRs after build 35.
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

Owner checks pending on build 35 (2026-10-18): update the iPhone 12 mini from
TestFlight (it is on build 31); try steps, Play and Progress on the phone. Whether the
step content change needs a GRAC notice is unknown.
- Build 35's step screens (22 uisweep entries) were never screenshot-swept: owner asked
  for a lean finish. Only targeted UI classes and the merged suite's failures were run.

Lesson path (from the 2026-10-15 lesson review; owner decisions, not code bugs):
- Outs sits second in the suggested order with no recorded
  reason (`c31a5c7`). Rules pages (pot, blinds, flow) stay optional; the glossary now
  defines those words.
- Kept on purpose (owner, 2026-10-15): outs beginner choices can be 1 apart because
  exact counting is the skill; the starting check stays out of Settings (`7549a32`);
  audit #34/#41 compact-grid rank headers stay as they are.

Product and numbers:
- Numerical audit N08–N12 and model qualifications
  (`docs/records/2026-10-11-numerical-audit.md`). Graded-flop sampling is gone: the flop
  is exact (D49, PR #22).
- Build 15 crawl candidates never verified: short tap heights on ‘설명 접기’,
  ‘안내 건너뛰기’, ‘계산 보기’, ‘전체 차트 보기’, ‘크게 보고 핸드 찾기’; unlabelled buttons
  on free-table setup. Free-table review once paired 33% with "four wins in ten".
- Free-table dock/seat layout at 2–3 players: not confirmed closed; check `map.md`.
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
- Push-triggered CI does not always start; dispatch it with
  `gh workflow run ci.yml --ref <branch>`. The `.p8` key should move into a password
  manager (owner reminder).
- `ui-tests.yml` can only be started by hand once it is on `main`. The full UI suite has
  not passed on a GitHub runner (see `docs/records/2026-10-14-codex-ci-repair.md`).

Tests:
- Build 24 had only the unit tests and three hand-rank UI tests on iPhone 17, not the
  full suite.
- Intermittent: `FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable` (iPhone 17),
  `FreeDockFlowTests/testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes`.

## Recent sessions

### 2026-10-18 (Claude · build 35: steps, Play, Progress)

- Merged PRs #37–#41, then built and merged through #53: steps for all skills (D53,
  schema 5), Learn mark follows the learner (D52), Play list, Progress tab, largest text
  (D54), Chen card open, EV call spread, Help scroll fix, UI shards by time.
- Integration conflicts: union of step lists; D52/D54 renumber; kept #49's deletions.
  The final UI run failed 11 AX tests; cause was the Large Content Viewer on capped
  parts, removed (D54 updated); all 11 then passed locally, unit CI green.
- Tagged `v1.0-35`. Next: owner installs from TestFlight and checks steps on the phone.

### 2026-10-17 (Claude · TestFlight builds 31–34 and owner's phone feedback)

- Shipped builds 31–34 to TestFlight by tag. Owner feedback from the phone, each with
  exploration artifacts and owner picks: concentric bottom corners (iOS 26
  `ConcentricRectangle`, PR #28); outs answer as hand-type rows with 1.5pt inset gold
  strokes and no outer ring (1A + V1, PR #31); kicker as basics check 3 with a duel panel
  (2A + K2, PR #32); Learn as list A2 with no question count and the marker = open lesson
  else suggestion (D51, PR #33); lowercase English hand names (PR #27); a finished lesson
  closed with ✕ no longer blocks others (PR #30); 원 페어/투 페어 spaced (PR #34).
- One simulator job at a time throughout (owner's Mac-load rule).
- Next: owner adds themselves as an internal tester and checks build 34 on the phone.

### 2026-10-17 (Claude · kicker duel scroll and Learn list)

- PR #32: merged `origin/main` (#31's inset strokes reach the D50 rows; the duel's A♠
  already strokes inside the card, and #31 has no shared stroke helper). The kicker
  duel now scrolls into view above the answer sheet when the pick is committed, without
  animation under Reduce Motion. Two UI tests in BestFiveComparisonTests (KO/EN).
- Learn redesign, variant A2 (owner, D51), on `feat/learn-diagram-list-20261017`: Drills
  `Curriculum.markedLesson` picks the one marked row (8 unit tests first);
  `LearnView` is the list; `PathView` and its sheet are gone; a passed lesson's 연습
  opens `FreePlayView(startConcept:)` straight into that skill's round, through its own
  item-based cover (a shared `isPresented` cover showed the picker with a stale
  concept). Records/activity copy says 연습. New `LearnListTests` (9); repaired tests
  that used `learn-path` or the old resume labels; UXAuditCrawl follows the list.
- No schema change. Next: owner reviews both PRs.

### 2026-10-17 (Claude · live language switch)

- Cause, from logging on clones: on iOS 27 the App body re-ran with the new
  `AppStorage` language, but the open WindowGroup kept its old environment, so RootView
  never re-rendered; iOS 26.5 re-renders it. Fix: an `@Observable` `LanguageSettings`
  owned by RootView as `@State` injects the language and locale, and Settings writes
  through it (no `.id`, so progress and navigation survive). The toggle failure blamed on
  bc53bdc was a flake: it also happened once on unfixed code.
- DeviceFeedbackSettingsTests now assert the tab bar, Settings and Learn in both
  directions without a relaunch. PR open; next: owner review, then merge.

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
