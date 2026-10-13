# Friendly/casual checkpoints archived 2026-10-06

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

