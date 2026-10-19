# Agent handoff

Read this at session start. It has three parts: the current state (rewritten, not
appended), the open issues (a living list), and the last few sessions. Rules for
keeping it are in `AGENTS.md`. Older history is in `git log -- docs/agent-handoff.md`
and the text records in `docs/records/`; neither needs reading for normal work.

## Current state (2026-10-19)

- Owner requested glossary/Settings learning-help improvements and removal of both
  terminology controls. Work is on `feat/terminology-learning-help-20261019` in
  `glass-table-terminology`, based on the unmerged PR #55 head `ebb0fae`.
  [Draft PR #56](https://github.com/mhju0/glass-table/pull/56) is stacked on #55.
  Owner now authorized full CI, ordered merges and TestFlight upload (2026-10-19).
  Build 36 is being prepared on that branch; merge/tag/upload wait for green gates.
  No phone installation or App Store review submission is included.
- Owner clarified reference learning (2026-10-19): glossary lookup and general skill
  explanations count as self-directed work with no scoring effect. Only coaching,
  hints or calculated guidance for the current decision count as assisted. See D55.
  Terminology changes, 56-entry focused/searchable glossary and seven guide topics
  are implemented. Independent review cleared final product code `5522a12`; app unit
  165, preserved-answer/Position UI and all seven AX5 guide navigation/lookup checks
  passed. KO/EN normal/AX5 search, both five-state AX dock checks and sampled layouts
  passed/inspected. Final hint copy `b8ff2cc` was rechecked; no scoring changes.
  Evidence: `docs/records/2026-10-19-terminology-learning-help.md`.
- PR #56 CI at `a61b9c2` [ran and failed](https://github.com/mhju0/glass-table/actions/runs/39190901552):
  tools, Drills, app unit and all 14 focused UI tests passed. Release smoke opened
  the guide but still expected its old headline; device Release validation was
  consequently skipped. The test now checks real topic IDs and Next navigation;
  both local Release smoke tests passed with fresh derived data on iOS 26.5.
  The corrected PR head still needs replacement CI, including device Release validation.
- PR #55's exact `ebb0fae` passed [remote CI](https://github.com/mhju0/glass-table/actions/runs/39143752775),
  including focused UI, Release smoke and unsigned device bundle checks. It remains
  a draft, unmerged and unreleased; no new full nightly or phone checks are implied.

- Independent Codex review of builds 24–35 at `ed54c2f` found open teaching and
  recovery issues; no product fixes or new release. See
  `docs/records/2026-10-18-independent-build-review.md`. Build 35's upload and CI
  succeeded, but its full GitHub UI run has one unresolved AX postflop failure.
- Owner authorized follow-up corrections and a better validation routine (2026-10-19).
  Work is on `fix/review-followups-20261019` in the isolated
  `glass-table-review-followups` worktree. R01–R04 corrections, analogous Range Read
  assumptions, focused PR CI and `docs/validation.md` are implemented. Independent
  review accepted core `116187c` and final code `66d9c22`; local checks passed.
  Sampled KO/dark and EN/light normal/AX5 frames were inspected (limits in the record).
  Owner chose **Casual / 캐주얼형** for the free-play style; behavior is unchanged.
  No new tag, upload or phone install.

- Build 35 (owner held it until all of this was in, 2026-10-18): `main` at `d910f99`
  via integration PR #53 (PRs #42–#52), tag `v1.0-35`, TestFlight upload only. Adds:
  - Steps (D53, schema 5): all 14 active track skills are dealt at Learn → Apply → Sharp
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
- Published build 35 is on `main`; current follow-up work is on its feature branch.
  The standing rule is still to work on a feature branch and not push `main`
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
  pushes/PRs on unit tests plus the Release smoke and bundle checks; the follow-up
  branch adds focused teaching/recovery UI flows. `ui-tests.yml` runs the full UI
  suite nightly in four shards; `release.yml` uploads a `v<version>-<build>` tag
  on `main` to TestFlight. Builds 31–35 have uploaded through it; setup secrets are
  present. Setup and run links: `docs/ci-cd.md`. No App Store submission is implied.
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
- Phones: the older signed-install record has 1.0 (30) on iPhone 12 mini and build
  18 on iPhone 13 mini; the later build-35 handoff reports 31 on iPhone 12 mini.
  Neither phone was inspected during the Codex review/follow-up. Build list:
  `docs/build-history.md`. The GRAC video and source freeze in
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
- Follow-up [draft PR #55](https://github.com/mhju0/glass-table/pull/55) is open.
  Remote CI passed at `ebb0fae`; keep it separate from build-35 release claims.
- Test environment: use the iPhone 17 iOS 26.5 simulator by id (the bare name picks the
  iOS 27 beta). After a rebuild, run
  `xcrun simctl uninstall <device> com.michaelju.glasstable.GlassTableUITests.xctrunner`
  before a UI run, or the simulator can run an old test bundle.

## Open issues

Review follow-ups (2026-10-19):
- PR #55 focused CI on iOS 26.2 passed at `ebb0fae`; its full UI suite remains
  unverified. PR #56 `a61b9c2` CI failed its stale Release-guide headline assertion;
  tools, packages, app unit and 14 focused UI tests passed. Both corrected Release
  smoke tests passed locally; replacement CI/device Release validation are pending.
  Build-35 failure evidence was inspected: the Call tap
  was near the bottom viewport. The helper now scrolls targets inward, retains the
  Continue assertion and adds failure attachments; exact interception cause is unknown.

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
- Build 35's full set of step screens (22 uisweep entries) was not screenshot-swept: owner asked
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
- Check Actions for the exact head before manually dispatching CI; the PR status
  list can lag a push. If no run is actually scheduled, use
  `gh workflow run ci.yml --ref <branch>`. Keep one owned run instead of duplicates.
  The `.p8` key should move into a password manager (owner reminder).
- `ui-tests.yml` is available by hand on branches. Full time-balanced run 39088052141
  passed all four shards; later build-35 run 39126165724 failed the AX postflop
  Continue assertion. The follow-up helper passed three local repetitions on iPhone
  17/iOS 26.5. A new full remote run is still required before claiming full-suite success.

Tests:
- Build 24 had only the unit tests and three hand-rank UI tests on iPhone 17, not the
  full suite.
- Intermittent: `FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable` (iPhone 17),
  `FreeDockFlowTests/testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes`.

## Recent sessions

### 2026-10-19 (Codex · build 36 release preparation)

- Owner authorized full CI followed by merges and TestFlight upload. Prepared version
  1.0 (36) on #56 over #55; no product or progress-schema changes for the build bump.
- Release gates include full CI, the four-shard UI suite and Engine release tests on
  one frozen candidate, then main CI before the matching tag/upload. All are pending.
- Release record: `docs/records/2026-10-19-build36-release.md`. Owner is signing into
  App Store Connect so processing and tester availability can be checked separately.

### 2026-10-19 (Codex · CI Release-guide assertion)

- Checked exact PR #56 head `a61b9c2`: CI ran, but its Release smoke test still
  expected the previous guide headline. Tools, packages, app unit and all 14 focused
  UI tests passed; device Release validation was skipped after the smoke failure.
- Updated the smoke test to require the real first topic and navigate to the next
  topic without demo hooks. Added the relevant Release check to `docs/validation.md`.
- Both Release smoke tests passed locally with fresh derived data and no demo hooks.
  Replacement CI/device Release validation are pending; no app code changes, merge,
  tag or installation. Evidence stays in the terminology verification record.

### 2026-10-19 (Codex · terminology and learning reference)

- Removed both terminology controls; paired real terms with plain meanings and added
  a 56-entry searchable bilingual glossary with focused lookup and seven readable
  Settings guide topics. Owner explicitly chose self-directed lookup with no scoring
  effect; only current-question coaching or calculated hints count as assistance (D55).
- Independent review found and resolved ambiguous Position street labels and missing
  LJ/UTG+1 lookup. Final product code `5522a12` passed its delta review. Saved progress,
  question identities and grading remain unchanged.
- Local guide/search/dock and normal/AX5 KO/EN render checks passed; final hint
  copy is `b8ff2cc`. PR #56 remote CI is pending. It is stacked on unmerged #55.
  Final evidence is in
  `docs/records/2026-10-19-terminology-learning-help.md`; no release or phone install.

### 2026-10-19 (Codex · review corrections and validation routine)

- Fixed R01 save-recovery gating, R02 scalable counts, R03 preflop street closure
  and R04 visible grading assumptions; applied the same premise correction to Range
  Read. Saved question indices, seeds, grades and progress schema stay unchanged.
- Focused recovery/teaching UI flows now gate PR CI. Investigated the prior AX tap
  failure instead of dismissing it as a flake; tightened scrolling and diagnostics.
- Owner chose Casual / 캐주얼형; wording only. Added `docs/validation.md` with a
  session guide for someone who knows the rules but rarely plays; no person tested yet.
- Core `116187c` and copy candidate `66d9c22` passed independent review. Drills 671,
  app unit 158, focused UI 23, separate Progress/AX checks and final setup flow passed.
  R01–R04 and documentation drift are closed locally; PR #55 remote CI later passed
  at `ebb0fae`. Full UI and physical checks remain open. Evidence: `docs/records/2026-10-19-review-followups.md`.

### 2026-10-18 (Codex · independent builds 24–35 review)

- Reviewed frozen `ed54c2f` with independent standards/persistence, teaching/spec and
  release-evidence checks. Recorded R01–R04 above; no app code changed.
- Fresh Drills 664 and Engine release 96 tests passed; simulator build passed.
  Targeted screenshot checks and their limits are in the review record.
- Next: resolve teaching/recovery findings and investigate the runner failure before
  treating Sharp and build 35 as fully verified. No new release or phone install.
