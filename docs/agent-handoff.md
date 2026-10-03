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

## 2026-10-01 — Direction A early checkpoints, condensed

Full exploration, step1 candidate/approval and step2 pause details remain in
[the early-checkpoint archive](handoff-archive/2026-10-01-direction-a-early-checkpoints.md).

- Created feat/free-table-direction-a from 33e5384; step 0 is 6dc95b6 and step 1
  spacing is 22bb963. No push. The delivery spec supersedes all exploration pages.
- Step 1 passed 61 app units, 19 UI checks and 394 Drills tests. Dock visible normal
  top/left/right/bottom: 25.67/21.67/20.33/20.33 → 20.33/21.67/20/20 pt;
  AX5 bottom 64 → 20 pt. Title ink retains normal 1.67/AX 3.33 pt glyph bearings.
- Owner approved wrapping exact AX titles and native corners with 0.765 pt minimum
  clearance exception. Recorded in spec §13; no custom corner curve.
- Owner paused during step 2, then resumed; source/evidence survived. The old
  50-minute target expired with that pause. Current verified step 2 entry follows.
- Outs/Math level 2 and fast-table remain deferred. Support work stays strictly
  after Direction A. Engine, progression, settings and excluded audit paths remain
  outside scope. Physical haptics, VoiceOver and older-runtime checks remain open.

## 2026-10-01 — Direction A steps 2–4, condensed 2026-10-02

Full entries: [steps 2–4 archive](handoff-archive/2026-10-02-direction-a-steps-2-to-4.md).

- Step2 a52b094: paper hero, clockwise seats,8pt felt edges, fixed36/43pt cards.
  Revised AX scroll proof excludes chrome-covered names; six KO/EN2/3/4 seat
  checks pass. Seat heights differ by at most0.667pt; physical readability remains
  a tradeoff. Step3 dd348cb: three fixed slots, public replay prices, warnings,
  Skip×3 and stable tallest-face dock. Full all-face sizing later passesStep5.
- Step4 3f6b61b: gold commit, presets, one-chip native press/hold, limit dimming
  without haptic, AX amount/preset scrolling. Real pan-from-key bug fixed;8 unique
  UI methods passed. Normal dock315pt; amount top20.333/control left20.667/right20/
  bottom20.333pt; native corner exception stays within approved tolerance.
- Builds/units/Drills and inspected KO/ENlarge/AX gates passed for each step.
  Commands, every failed attempt, measurements and captures: .build/direction-a/
  step2/report.md, step3/report.md, step4/report.md. Rejected cold EN landing
  captures were replaced with identified warm/native evidence; no product cold
  launch fix claimed. Step5 restores Rules reopening and verifies all dock faces.
- Physical haptics/VoiceOver/older runtimes remain unverified. No Engine/
  progression/new saved setting/excluded audit-path edits or push. Outs and fast
  table remain deferred; support/privacy/Pages work follows Direction A.

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

## 2026-10-03 — GRAC video preparation

- Owner requested actual submission gameplay video and Korean optional descriptions.
  Added local drafts under docs/grac-submission/2026-10-03; current3.6 is a scene
  timestamp table, not the upload page. No application mutation/upload/submission.
- Release1.0(14) at HEADf3bb670 built and installed on a separate owned simulator;
  recording runner/tooling is isolated under .build/grac-video-2026-10-03. No product
  edits or user's existing progress changes. Actual video is NOT recorded yet.
- Device Hub CUA selection repeatedly timed out. User was asked to explicitly
  authorize XCTest UI interaction as an alternative under computer tool policy;
  response pending. Do not execute runner until that answer arrives.
- Resume with real manual/automated Release UI capture, include standard table,
  payout, normal zero-stack refill and separate graded betting lesson. Verify
  final video frames and actual timestamps, then supply3.6 rows. Format/size and
  simulator acceptance remain unconfirmed; no requirement inferred from guide.
- First statutory compliance radio remains unresolved: repo function evidence
  does not establish whether offline App Store app is subject to decree Annex2(8).

## 2026-10-03 — GRAC gameplay video recorded

- User explicitly approved XCTest interaction. Real Release1.0(14) at f3bb670 was
  recorded in isolated simulator, with no debug fixtures/progress injection/product
  changes. Retained rejected takes; assembled valid real-screen clips only.
- Final local MP4: docs/grac-submission/2026-10-03/GlassTable_GRAC_1.0_14.mp4;
  404seconds,1206x2622,H.264,39,200,330bytes,no audio. Root inspected exact final
  frames covering launch/learning,betting,payout,zero stacks,normal100chip refill,
  separate graded lesson,responsible guidance and version1.0(14).
- Korean optional descriptions and scene timeline accompany video. Actual site
  format/size and simulator acceptance remain unconfirmed. No upload/payment/
  application submission. Statutory applicability question remains unresolved.

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
- Verified: Drills 384 + 49, app units 67, full UI run 131 of 139, then the eight
  failures fixed and rerun green (not one green full run). GT_TEST_PATH_CURRENT_NODE
  now leaves the target track's challenge uncleared so the lesson is still suggested.
- Open: explanation text from the drills package still uses seat codes, "bb" and
  "3벳" for beginners (reveal sentences, range-read and action-read action lines);
  drill header titles are still the terms; Today is Korean-only as before; lessons
  on "Go deeper" keep the old wording. Real-phone check of all of the above.
- Not mine, left untracked and untouched: GlassTable/UITests/UXAuditCrawl.swift
  (looks for `placement-row`, "Computer" names and "길로 돌아가기", so it fails until
  its owner updates it), tools/uxaudit/, .scratch/uxaudit-codex/, docs/grac-submission/.
