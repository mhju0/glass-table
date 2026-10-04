# Agent handoff

## Through 2026-09-30 — condensed 2026-10-02

Full detail: [the 10-01 archive](handoff-archive/2026-10-01-before-direction-a.md), which retains the earlier archive links and all historical entries.

- Shipped through 09-30: combined beginner release, four tabs, first-run guide and
  Hold'em basics; lessons/reveals, accessibility/Bold Text, sheets/spacing;
  policy/Range Read/locked-choice/Position fixes; full-screen free table replay/help.
- Open human/release checks: physical VoiceOver, minimum iOS 17, novice comprehension,
  signed Store/distribution validation, screenshots, age rating/territories,
  very-large-history save latency, and system permission/notification/share/review
  flows remain unverified. Enrolment, counsel and submission remain owner work;
  support/privacy pages are now queued after Direction A.
- Runtime gaps: iOS 17–18 attached sheets compile but were not observed; the iOS 27
  watchdog fix removed UIKit window reads from ActionSheet.body and needs the
  affected phone checked after install. The known AX walkthrough failure on one
  iPhone 16e simulator was not investigated; CI passed on its device. Live Bold Text
  changes reach views that redraw; reopening makes them consistent without resetting
  a hand. Shared table dimensions remain a readability tradeoff.
- Copy/audit checks: KO.wordJoined does not cover literal Text or Button/Label titles;
  recheck the reported Position intro leaks before calling them resolved. EV-loss
  range-grid labels remain about 6 pt; backup export/import is unverified. Empty
  practice-change content was a fixture artifact. Scrolled-audit screen-wide findings
  remain unexplained. The uncommitted crawler's Play steps predate the full-screen
  free table; preserve tools/uxaudit/, UXAuditCrawl.swift and .scratch/uxaudit-codex/.
- Device reset backup: .build/device-backups/20260924-before-reset/; restore by copying
  its files back. Do not reset phone progress otherwise. Archive ignored evidence
  before removing worktrees; proposal evidence is .build/archive/glass-table-proposal-uisweep.
  .scratch/pot-calculation-redesign/ remains intentionally untracked and unrelated.

## 2026-10-01 — Direction A steps 0–4, condensed 2026-10-04

Full entries: [early checkpoints](handoff-archive/2026-10-01-direction-a-early-checkpoints.md)
and [steps 2–4](handoff-archive/2026-10-02-direction-a-steps-2-to-4.md).

- feat/free-table-direction-a from 33e5384: step 0 6dc95b6, step 1 spacing 22bb963,
  step 2 a52b094 (paper hero, clockwise seats, fixed cards), step 3 dd348cb (three
  fixed slots, replay prices, stable dock), step 4 3f6b61b (gold commit, presets,
  press/hold, AX amount scrolling). The delivery spec supersedes exploration pages.
  Owner approved wrapping AX titles and native corners with a 0.765 pt exception
  (spec §13). Measurements and failed attempts: .build/direction-a/step2…step4/report.md.
- Still open: physical haptics, VoiceOver and older runtimes unverified; seat heights
  and physical readability remain a tradeoff; no product cold-launch fix claimed;
  Outs/Math level 2 and fast table deferred.

## 2026-10-02 — Direction A steps 5–8, support pages, phone install, condensed 2026-10-03

Full entries: [steps 5–8, support and phone archive](handoff-archive/2026-10-03-direction-a-steps-5-to-8-support-phone.md).

- Steps 5–8 committed locally (step 5 is 5513364), never pushed: flipping dock back
  (Math / This hand / Rules), supervised public replay with chip and card motion,
  SwiftUI sensory feedback, app-wide inset/radius/font corrections, then the full
  verification pass. All 134 tracked UI methods have a passing outcome with failure
  history kept, not one green full run. Evidence: .build/direction-a/step5…step7/
  report.md and docs/verification/2026-10-02-free-table-direction-a.md.
- Support: MJ Apps Support / mj.apps.support@gmail.com in Settings, bilingual policy,
  docs/support.html; PR 10 merged to main as 8e808ca, Pages live at
  https://mhju0.github.io/glass-table/support.html and privacy-policy.html.
  See docs/verification/2026-10-02-support-publication.md.
- Signed Release 1.0(14) installed in place on the owner's iPhone 12 mini; progress
  bytes identical before and after. Ledger: docs/verification/2026-10-02-iphone-install.md.
  Delivery report: docs/reports/2026-10-02-direction-a-delivery.html.
- Still open: physical haptics, VoiceOver and older-runtime checks on a real phone;
  no dedicated queued-cancellation unit for the serial cache; unseeded PotMath
  generated-question identity not established; no product cold-launch fix claimed;
  Math outs level 2 and fast table deferred; 14 retained 베팅 strings listed in the
  step 8 report.

## 2026-10-03 — GRAC gameplay video, condensed

- Owner approved XCTest interaction; real Release 1.0(14) at f3bb670 recorded in an
  isolated simulator, no debug fixtures or product changes. Final local MP4:
  docs/grac-submission/2026-10-03/GlassTable_GRAC_1.0_14.mp4 (404 s, 1206x2622,
  H.264, no audio) with Korean optional descriptions and a scene timeline. Tooling
  is under .build/grac-video-2026-10-03.
- Open: site format/size and simulator acceptance unconfirmed; no upload, payment
  or submission done; the first statutory compliance radio (whether an offline App
  Store app falls under decree Annex 2(8)) is unresolved.

## 2026-10-03 — Friendly/casual redesign: built on feat/friendly-casual (not pushed)

- Goal changed from "become a pro" to casual, mainstream, heavily guided (D46 in
  docs/decisions.md; CONTEXT.md and the product brief carry it). Proposal with
  before/after mockups: https://claude.ai/artifact/QnD5ia4AoS8wj44R2eznkA. Owner
  approved every recommendation and delegated all seven decisions.
- Free table: no empty seat at 2–3 players, quick game default (40 chips AND 10
  hands; simulation showed stack size alone cannot give five minutes), casual
  "Just for fun" opponents (Mina/Joon/Sora; `.casual` is left out of
  `Archetype.allCases` so seeded drills do not change), full-screen step-by-step
  hand review with beginner-chart verdicts and bluff callouts, "Hint" tab with an
  opt-in "What would the beginner chart do?" (same rules as the review; no FSRS
  credit). The dock back was kept rather than a new sheet so the pill stays one word.
- Learning structure: four tracks plus "Go deeper" (LearningTrack.swift), poker-term
  tags, a heads-up and never a lock when skipping ahead, "try the lesson before"
  after missing more than half, illustrated skill cards, milestone card names the
  track. Hidden lessons keep their records but are not offered.
- Lesson shape, session format 2: three saved questions; after the guided question
  the first is marked helped (`helpOrdinal = 0`), so it is practice, not a grade.
  "Proficient" still needs a perfect unaided run, so it comes on a second visit.
  Format-1 sessions still load; the validator accepts formats 1...2. Track
  challenges mix only their own track's skills.
- Levels: the level IS `placement.selfReport` (no new type). Set by the first-launch
  check or by the "My level" chip on Learn, which writes a skipped placement. It
  moves only the suggestion (`Curriculum.suggestedLesson` starts at the check result
  or the level's first lesson, then returns to earlier ones), the default help, and
  which words lead. New optional `lessonTrend` in progression.json (no schema bump,
  old files read nil, range-checked ±9): two rough lessons in a row put the hint
  back on question one even on a revisit; three clean ones offer "Skip ahead with a
  quick challenge", and a passed track challenge drops that track from suggestions
  without marking its lessons done. "Plays sometimes" answers question one alone.
- "Use poker terms" (Settings, `glassTable.pokerTerms` in UserDefaults, unset means
  the level decides): swaps which of plain title / term leads in lesson rows and
  skill cards, and shows seat codes instead of early/middle/late/blinds.
- Simpler questions below "Plays sometimes" (`\.simpleQuestions`). Decision: graders,
  generators and saved input types are untouched, because the store re-grades saved
  answers on load; only the asking changed. Position groups seats and marks "You" /
  A / B (codes appear in the reveal); opening hands show always / play late / fold
  from `RFIChart.group` with the chart behind "See the full chart", same for
  defend (the hand's own verdict card stays visible); estimates hide the 90% range
  but still save the default-width one, because the store rejects an estimate
  without it, so those answers count in the Records calibration figure; range read asks
  strong / decent / anything first, then the existing fine controls; action read
  asks in words in steps of ten ("Often · 7 in 10"), which keeps every truth within
  the on-target band of some choice; pot odds leads with "1 in 4" and says chips.
  `GT_DEMO_LEVEL` shows a level's screens without writing a placement.
- Verified first pass: Drills 384 + 49, app units 67, full UI run 131 of 139, then the eight
  failures fixed and rerun green (not one green full run). GT_TEST_PATH_CURRENT_NODE
  now leaves the target track's challenge uncleared so the lesson is still suggested.
- Screens inspected after the fixes: Korean light and English dark, large and AX5,
  for Learn, starting check, All lessons, Settings, table setup, summary, milestone,
  first launch and the nine drill frames (.uisweep/20261003-203051-H0x60G,
  -203847-LtopIw, -204807-gZSj62). The Position seat strip (group names, "You")
  stays about 10 pt at AX5; the question sentence carries the seat in words.
- Second pass, same day: drill headers use plain names until poker terms are on
  (자리와 순서 / 이길 확률 / 먼저 올리기 / 상대 패 읽기 / 행동 읽기 / 올린 상대에 맞서기;
  English "Facing a raise"). Drills-package explanations and range-read / action-read
  lines now lead with `Position.plainName` and keep the term beside it ("빅 블라인드
  3개(3bb)", "다시 올리고(3벳)") for every level, per the glossary's bilingual-first
  rule. Hidden-range estimates no longer write a calibration record: the reveal
  bytes keep the range (the store needs it), the `interval:` argument is nil.
  At accessibility sizes the Position strip becomes a sentence
  (`position-seat-sentence`) before the answer; after the answer, and with poker
  terms on, it is still the capped one-row strip.
  Verified on that code: Drills 385 + 49, and one clean full run of 69 app units
  and 139 UI tests (.build/friendly-ui.xcresult).
- Hand-review fix: a draw that missed by the river now counts as nothing in
  `PracticeHandCoach` (review, hint and the bluff callout share it); before, the
  river step still advised "call a draw when cheap" and called a busted-draw bet
  real. Failing test first; Drills 385 + 50, app units 69 and
  FreeTableBackFlowTests pass after it. The full UI suite was not rerun for this.
- Open: real-phone check of all of the above (see the 10-04 entry for what closed).

## 2026-10-04 — Friendly/casual leftovers, build 15 on the phone (not pushed)

- Today: nothing to translate. `TodayView` is never created and the "today" demo
  tab opens Learn (RootView.swift). The file is unused old code, left in place.
- "Go deeper" lessons below "Plays sometimes": plain headers (가능한 두 장 조합 /
  핸드 줄임 표기 / 콜의 평균 손익), questions say "두 장 조합(콤보)" and "평균 몇 bb…
  (EV)", the EV drill says "내가 이길 확률" and explains 1bb. Graders untouched.
- Table text: `TableEvent.text(in:plain:)` (default unchanged, so saved history is the
  same) names the seat in words and says "3bb로 먼저 올림" / "다시 올림(3벳)"; the graded
  table uses it until poker terms are on. Free table says 스몰/빅 블라인드 +N and
  "빅 블라인드 N개". Still codes: the free-table raise presets ("2BB"), and the graded
  table's "레인지 160콤보" and "필요 에퀴티" lines.
- Position at accessibility sizes: the seat sentence now also shows the action
  order after the answer and with poker terms on (UI test added; it was written
  after the change, so it was not seen failing first).
- Release build was broken on this branch: FreeTableView used the DEBUG-only
  `demoTable` outside its guard. Now `presentationTable`. Debug behaviour is the same.
- Verified: Drills 385 + 50; one clean full run of 69 + 38 app units and 140 UI tests
  (.build/friendly-ui2.xcresult), taken before the one-line Release fix and the
  build bump. Signed Release 1.0 (15) installed in place on the iPhone 12 mini;
  progression.json byte-identical before and after (.build/friendly-casual/iphone-install).
  The phone was locked, so the app was not launched or looked at on it.
- UXAuditCrawl.swift and tools/uxaudit/report.py (still untracked, the owner has not
  said to commit them) now follow the new app: level question at first launch, the
  starting check from Settings, the full-screen free table by identifier, five
  tracks instead of nine units, "완료" on the summary. A saved English setting on a
  simulator makes the whole crawl miss; tools/uxaudit/run.sh clears it, a bare
  xcodebuild does not. `-only-testing:…/UXAuditCrawl` alone ran zero tests here;
  name the methods.
- Crawler result (sim, Korean, normal text): every flow now runs to the end —
  test01, 03, 04, 05, 06 and test10–14 pass on the final code or on a run after
  which only other flows' code changed; test02Learn passed once, before the later
  recorder edits, and was not rerun. No full single-pass run of all flows on the
  final file. Only remaining notes: range-read questions (u4-rangeRead-b,
  u4-boss-b) where the second attempt cannot produce the opposite grade — a
  crawler limit, not an app fault. Settings share sheet is still closed by swipe.
- Next: owner looks at build 15 on the phone; decide whether to commit the crawler.

## 2026-10-05 — Clean phone install, full crawl report for build 15

- Owner asked for a clean start: app removed and build 15 reinstalled on the
  iPhone 12 mini, progress gone on purpose. All Mac-side progress copies deleted
  at the owner's request; do not pull progress off the phone unless asked.
- Full crawler pass on three iPhone 12 mini simulators (two created for this:
  "GT audit mini B/C"), one run, 11 tests, 0 failures, 51 flows / 931 screenshots.
  Report: `.build/uxaudit-report-b15/index.html` (built without the stale
  `tools/uxaudit/notes.json`). Korean, light, default text only.
- Unverified candidates from the report's automatic flags: short tap heights on
  ‘설명 접기’ (24pt), ‘안내 건너뛰기’ (17pt), ‘계산 보기’ (26pt), ‘전체 차트 보기’
  (28pt), ‘크게 보고 핸드 찾기’ (17pt); unlabelled buttons on free-table setup.
  These are accessibility frames, not proven hit areas.
- Next: owner scrolls the report and marks what to fix; crawler still uncommitted.
