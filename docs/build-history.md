# Build and feedback history

Reconciled October 10, 2026 from repository records. Entries distinguish plans, builds, installation and observation; a sequential number is not proof of release. No App Store release is implied. Raw evidence can be ignored/local and historical gaps are retained.

| Build | Date2026 | Main change | Evidence/status | Record |
|---|---|---|---|---|
|1|July 23|M1 submission design|Planned; no build/install evidence found|[Record](../docs/specs/2026-07-23-m1-submission-design.md)|
|2|September 14|Course revamp and bilingual native layout|Unsigned Release and simulator evidence; no device install claim|[Record](../docs/specs/2026-09-14-revamp-delivery.md)|
|3|September 23|Pot replay, beginner pot explanation and appearance|Signed build installed in place; progress preserved|[Record](../docs/specs/2026-09-23-pot-appearance.md)|
|4|September 23|Combined beginner release: lessons, placement and four-seat Play|Installed; metadata/process and progress verified|[Record](../docs/specs/2026-09-23-beginner-native-release.md)|
|5|September 23|Settings as fourth tab, language settings and AX fixes|Installed in place; progress preserved|[Record](../docs/specs/2026-09-23-settings-navigation.md)|
|6|September 24|Delivery checkpoint bb87591 + build bump d3982dc|Install recorded; detailed raw evidence subsequently lost|[Record](records/2026-09-04-session-history.md)|
|7|September 24|Full-screen lessons and shared table surface|Installed in place; preserved progress|[Record](records/2026-09-04-session-history.md)|
|8|September 24|Exact-combo explanation before counting|Fresh install recorded at 07f9a1e; historical backup existed|[Record](records/2026-09-04-session-history.md)|
|9|September 25|Welcome/warm-up, Play modes and bottom answers checkpoint|Git build bump for intended install; outcome not located|[Record](records/2026-09-04-session-history.md)|
|10|September 26|Help, large-text headers and practice layout checkpoint|Git build bump for intended install; outcome not located|[Record](records/2026-09-04-session-history.md)|
|11|September 26|UI refinement checkpoint; detailed delta not enumerated|Device install recorded; progress preserved|[Record](records/2026-09-04-session-history.md)|
|12|September 26|Contrast changes and CI type-check fix, PR7 merged|Install requested; result not located|[Record](records/2026-09-04-session-history.md)|
|13|September 27|Question retained through reveals, foldable feedback|Branch/build checkpoint; phone install not located|[Record](records/2026-09-04-session-history.md)|
|14|October 2|Free Table Direction A; support/privacy delivery|Installed in place; preserved progress; observed Learn|[Record](records/2026-10-02-verification-reports.md)|
|15|October 4–5|Casual direction, coaching and beginner tracks|In-place then owner-requested fresh reinstall; historical crawl evidence|[Record](records/2026-09-04-session-history.md)|
|16|October 6–7|Native spacing, feedback, encouragement and Records|Fresh12mini install; subsequent13mini owner feedback28 comments|[Record](records/2026-10-02-verification-reports.md)|
|17|October 7|Welcome-first isolated candidate|Not a confirmed phone installation|[Record](records/2026-10-07-device-feedback-build16.md)|
|18|October 8|28feedback changes plus graded1v1 revamp|Fresh install12mini/13mini; metadata/launch verified, screen not observed|[Record](../docs/specs/2026-10-07-graded-table-learning.md)|
|19|October 10|Five intro comparisons, chart invitation, guided hand, restore and copy parity|Fresh12mini install; version19 and Korean welcome physically verified|[Record](../docs/specs/2026-10-10-complete-beginner-ux.md)|

|20|October 11|Experience-first teaching, optional later preference, resumable guide and bilingual native refinement|Fresh12mini install; signed version20, Korean welcome physically verified; native gates passed|[Record](../docs/specs/2026-10-11-consistent-experience-first-opening.md)|

## Feedback → change trace

- Build16 owner session: all28 comments at `docs/records/2026-10-07-device-feedback-build16.md`; report `.build/device-feedback-2026-10-07/index.html`. Subsequent clarification on voice, portrait seat loop, bottom actions and language line groups is retained in delivery specs.
- Build18 reconciliation: `docs/records/2026-10-08-implementation-reconciliation.md` separates18 source-implemented comments from10 partial ones at that time; not a current completion verdict.
- Build 19 gap completion: `docs/specs/2026-10-10-complete-beginner-ux.md`, native gallery `.build/native-ux-b19/index.html`, signed-build/test evidence in sibling completion worktree. Installation evidence `.build/device-install-b19/` confirms current 1.0 (19) and Korean first-run welcome.
- Build 19 new feedback: `docs/records/2026-10-10-first-five-minutes.md` records abrupt familiarity transition, engaging-first-five-minutes request, progress/copy/buttons/color/motion exploration and traceability. `docs/records/2026-10-10-first-five-minutes.md` explores proposals; no build 20/native change is made in this research turn.
- Build 19 proposal approval and app-wide exploration: owner approved the opening proposals, then requested consistency research without building. `docs/records/2026-10-10-whole-app-consistency.md` records WAC01–06; `docs/records/2026-10-10-whole-app-consistency.md` compares their impact on lessons, practice, Free Play, Progress, Settings, tone and shared components. This is research/HTML work, not a new app version.

## Next build record format

For each subsequent candidate, append: build number/date/source commit; feedback IDs and exact change; preserved invariants; tests/capture provenance; signed/installed version; device and reset/preservation; observed first-run or flow; remaining gaps. Link proposals separately from implemented screens. Append new evidence rather than overwriting historical outcomes.

This index is newly consolidated. Earlier records remain intact; missing installation evidence for builds 9/10/12/13 and plannedbuild 1 is not reconstructed as success. New default reinstalls reset data; historical in-place installs predate that rule.


## Build 20 — approved experience-first and whole-app consistency delivery

- Implemented approved FFM01–08 and WAC01–06 recommendations: welcome and pair teaching before assessment; choice or neutral demonstration; factual two-example checkpoint; optional starting preference; stop/resume with stable cards; independent replay and separate five-example completion. Preserved native typography, adaptive palette, bottom task actions, chart/model/game meanings and help-neutral progress. Wrong-answer haptics now use quiet selection feedback.
- Source `07054d0366b88ce268ae237cc26ce73291ad8adc`; final production change `132c331906346f244fdb1dc8b963970748a56d0c`. Manual bilingual review corrected letter-helper line parity, automatic explanation visibility and paired answer-reason phrases. Normal selected English/Korean line groups match; AX text wraps naturally at word boundaries.
- Verification: 401 Drills XCTest + 75 Swift Testing, 60 progression tests, 9 opening recovery tests; EN/KO × light/dark normal/AX matrix, 16 actual accessibility routes, 4 additional Next transitions and 12 final reason-visibility entries passed. Independent final source review accepted. [Native before/after report](../.build/native-ux-b20/index.html) contains 206 native screenshots, 8 labeled historical frames, decisions, provenance and limits.
- Signed Release 1.0 (20) freshly installed after uninstall on iPhone 12 mini; metadata/ordinary launch and physical Korean welcome verified. No phone progress copied; welcome left unadvanced. [Installation record](../.build/device-install-b20/verification.json). Final signed binary SHA256 `8fb2eab8c64b03cdfd4164e80a9510f77858136a9ab511c49328c24668f092e4`; interim source802 build20 install is superseded and archived separately.
- Remaining: observed novice comprehension/retention, physical VoiceOver/thumb comfort and minimum-iOS17 runtime. No App Store release claim. Raw evidence retained in sibling `glass-table-consistent-opening/.build/consistent-opening-b20/`.


## Build 21 — numerical audit corrections, 2026-10-11

- Source `3e219db` includes N01–N07 at `21c3907`: break-even, PFR denominator, actual outs premise, excluded ties, equity pot-share wording, exact review deadlines and active streak display. Saved question identities, grades and progress schemas preserved.
- Signed Release 1.0 (21), uninstalled build 20 then freshly installed on iPhone 12 mini. Installed metadata and normal launch verified; physical Korean first-run welcome visually observed and left unadvanced. No phone progress copied. Evidence: `.build/device-install-b21/verification.json`; corrections/tests/screenshots: `.build/numerical-fixes/index.html`.
- N08–N12/model qualifications and prior novice/accessibility/minimum-iOS acceptance gaps remain open. No App Store release claim.


## Build 22 — green welcome and uninterrupted beginner guide, 2026-10-11

- Owner approved option C and requested removal of experience assessment and midpoint stopping prompt. Implemented green Glass Table brand welcome with bottom Start; Start teaches a pair. Normal experience-question routes removed from opening, Learn and Settings. Direct help/terminology controls remain; saved placement is retained.
- New comparison version2 uses a seeded stable balanced winner sequence (two/three wins per side), progressive five-rule order and exactly five suited cards in flush examples. Frozen version1 questions and old responses remain unchanged; missing version decodes as1, unknown versions preserve recovery bytes. Old checkpoint/preference restore to comparison three without credit.
- Short hints fit measured content; AX hints remain large/scrollable. Centered48pt close frame keeps44pt effective target in compact native presentation. Choice subtitle now Choose this hand / 이 패 선택하기. Green welcome has light status ink, then selected guide theme. Independent review found and fixed a same-step resume history regression; Previous now returns to pair teaching.
- Final native source `113e27b4a4290b2b25a28a21c89e8e8775fef070`, independently accepted. Package420 XCTest +75 Swift Testing; model62;34 distinct relevant UI cases have successful scoped evidence. Earlier failed invocations are retained and qualified; corrected hint/equity checks passed reruns. Final66 native frames (58opening+8hint), EN/KO ×light/dark ×normal/AX, with exact normal paired heights for allfive comparisons and actual AX Help/Next routes. Capture source6480c42 differs only by the separately tested resume-history fix.
- Signed Release1.0(22) fresh installed after uninstall on physical iPhone12mini. Installed metadata/ordinary launch and green Korean first-run welcome visually verified and left unadvanced. No phone progress copied. [Before/after native report](../.build/opening-b22/report/index.html); [installation evidence](../.build/device-install-b22/verification.json). Binary SHA256 `8625f80831f8865ac890e6cf3b32095a780a52dd87bab903a840ed632c5a2eb9`.
- Remaining: novice comprehension, physical VoiceOver/thumb comfort and minimum-iOS17 runtime; other bottom-menu routes received source inventory rather than a complete fresh runtime sweep. No App Store release claim. Raw results retained in sibling glass-table-opening-b22 worktree.


## Build 23 — audit follow-ups, 2026-10-13

- Source `dd7637b` on `feat/audit-followups`: written example on every explanation page, raise panel alignment, sharper hand-ranking question, shorter English texts and Help / History / Guide tabs, one-line turn facts at accessibility sizes, and one fixed corner radius (dock buttons no longer follow the display curve). Decisions: `docs/records/2026-10-11-audit-followups.md`.
- Verification at `e3ef792` (later commits are docs and the build number): iPhone 17 iOS 26.5 simulator 238 tests, 11 skipped, 0 failed. iPhone 12 mini simulator 238 tests, 11 skipped, 1 failed: `AccessibilityAuditTests/testPlayTable` reports a contrast finding with no element; it passes on iPhone 17 and passed 4/4 on the mini the day before on the same screen. Unexplained.
- Signed Release 1.0 (23), build 22 uninstalled first, then freshly installed on the physical iPhone 12 mini. Installed metadata and normal launch verified; green Korean first-run welcome observed and left unadvanced. No phone progress copied. Evidence: `.build/device-install-b23/` (`welcome.png`, devicectl JSON). Binary SHA256 `ffa14d74f7561a22c1e33e89d0d34a4cacffe2a7c863e1c13c605d61f503c645`.
- Remaining: novice comprehension, physical VoiceOver and minimum-iOS17 runtime. No App Store release claim.


## Build 24 — hand rank list, 2026-10-13

- Source `2543ad3`: the hand rank page shows all ten hands at once, strongest first, with "1 in N hands" / "N판에 한 번" in each row (two significant figures from the engine counts) and no toggles; owner chose mock A1.
- Verification: iPhone 17 iOS 26.5 simulator, 89 unit tests and three UI tests covering the page (first lesson flow, basics close, AX5 both languages to row 10) passed. No full-suite run. Top-of-page screenshots inspected on the iPhone 12 mini simulator, Korean and English, normal and AX5.
- Signed Release 1.0 (24), build 23 uninstalled first, then freshly installed on the physical iPhone 12 mini. Installed metadata and normal launch verified; green Korean first-run welcome observed and left unadvanced. No phone progress copied. Evidence: `.build/device-install-b24/`. Binary SHA256 `d114599a0250f06352aeb2bf659add7af3a692fa08c7138a6f3a1b2a76a10e72`.

## Build 25 — lesson feedback and "a near miss is wrong", 2026-10-14

- Source `a31472e` plus the build bump: answers marked in place with a green or red panel, white answer cards, amber near-best in the EV-loss lesson, one corner radius of 10, hole cards high card first, and only exact answers count as correct (accuracy, miss streak, lesson result, Records, sound).
- Verification: Drills 425 XCTest + 75 Swift Testing, 91 app unit tests and 57 UI tests (records, graded and learning flows, restored answers, release smoke) passed on the iPhone 12 mini iOS 26.5 simulator. No full-suite run on this source.
- Signed Release 1.0 (25), build 24 uninstalled first, then freshly installed on the physical iPhone 12 mini. Installed metadata and normal launch verified; green Korean first-run welcome observed and left unadvanced. No phone progress copied. Evidence: `.build/device-install-b25/`. Binary SHA256 `65af94ba95edf3f98887e62d56ba106f278fd38cd4d4b0642f81de32f6e4ea4d`.

## Build 26 — "A hand together" on the Play table, 2026-10-14

- Source `f4d1fe9` plus the build bump: "A hand together" rebuilt as one real two-player hand on the Play table with a coach card (Now / Look at / Think), the coach's pick marked, a spotlight on the first steps and a question before giving up (owner chose the mix of mocks B and A). The Play result buttons stack at accessibility sizes, which fixes the last button being 2pt taller than its panel on the 12 mini since build 24.
- Verification, iPhone 12 mini iOS 26.5 simulator: full suite on `aafc0b5` 317 passed, 3 failed (two Play table contrast audits, known; the result scroll test, fixed in `f4d1fe9`). On `f4d1fe9`: 93 unit tests and 90 UI tests (Play dock, raise, motion, help, graded dock, accessibility flows, native refinement, beginner release, guided hand) passed, 0 failed. No full-suite run on the final source.
- Signed Release 1.0 (26), build 25 uninstalled first, then freshly installed on the physical iPhone 12 mini. Installed metadata and normal launch verified; green Korean first-run welcome observed and left unadvanced. No phone progress copied. Evidence: `.build/device-install-b26/`. Binary SHA256 `32c242ba5ed20aab9ea1576ec7278e5adc99d9ab3e0ffcded9cee78fe031af42`.

## Build 27 — clickable controls and the lesson pass mark, 2026-10-14

- Source `10744ab`: tappable things look tappable (outlined ✕, ‹, ••• and text actions; Previous beside the bottom action) and a lesson or challenge passes with two in three questions answered alone and exactly right.
- Verification: Drills 428, 98 app unit tests and the full UI suite on two iPhone 12 mini simulators (228 tests), per the handoff of `82d82a7`.
- Signed Release 1.0 (27), fresh install on the physical iPhone 12 mini; first-run welcome seen. Evidence: `.build/device-install-b27/` (`build.log`, `welcome.png`). No binary SHA256 was recorded.

## Build 28 — build 27 feedback, 2026-10-14

- Source `170fba1`: the "Who wins?" worked example opens with every card face up, Hold'em basics hides the lone Previous before the answer, a reworked "A hand together" invitation, and swiping it away no longer starts the next lesson.
- Build 27 uninstalled, fresh install on the physical iPhone 12 mini, per the handoff of `9eaac48`. No evidence files or binary SHA256 kept.

## Build 29 — animation polish and Drills refactors, 2026-10-15

- Source `5de390c`: motion tokens and animation fixes, near-full-size board cards, and rules moved into Drills (`PracticeRaiseBlock`, `BeginnerJourney`, `ConceptReveal`, `GradedSession`; no schema change).
- Verification: Drills 427 XCTest + 95 Swift Testing, 97 app unit tests and 128 UI tests on two simulators, per the handoff of `467864a`.
- Build 28 uninstalled, fresh install of 1.0 (29) on the physical iPhone 12 mini; welcome seen, no progress copied. No evidence files or binary SHA256 kept.

## Build 30 — owner decisions, 2026-10-15

- Source `5c040c1`, merged to `main` as `0d8708c` (PR #14, same tree): the chart guide opens only the first time, a hand-specific chart reason, a verdict-first table review with Details, and a call-or-fold lesson `u2-callFold` before the price challenge.
- Verification: Drills 432 XCTest + 96 Swift Testing, 97 app unit tests and 78 UI tests (graded, chart first use, beginner release, learning flows) on a simulator; `ci.yml` passed on GitHub.
- Signed Release 1.0 (30), build 29 uninstalled first, then freshly installed on the physical iPhone 12 mini. Green Korean first-run welcome observed and left unadvanced. No phone progress copied. Evidence: `.archive/2026-10-15-owner-decisions-cleanup/owner-decisions/device-install-b30/`. Binary SHA256 `dc33b61bebe63a9bfe1344c1725cbe00b370fdab38de0eb889fa5ced56fb51a7`.

## Build 31 — first TestFlight upload, 2026-10-16

- Source `cc64042` (PR #17: scalable free-table captions and title) plus the build bump. First run of `release.yml` on a `v1.0-31` tag; App Store Connect record renamed to "Glass Table" the same day.

## Build 35 — fifth TestFlight build, 2026-10-18

- Source: `main` after PRs #37–#52 (steps: each skill dealt harder as the learner goes, schema 5; Learn mark follows the learner; Play tab as a list; Progress tab around numbers that only grow; Graded 1:1 decisions counted; largest text option B; Chen card open; EV call choices varied; Help scroll fix; UI shards by time), plus the build bump. Tag `v1.0-35`.

## Build 34 — fourth TestFlight build, 2026-10-17

- Source: `main` after PRs #30–#34 (a finished lesson no longer blocks other lessons, winning river cards as hand-type rows with inset gold strokes, the kicker as the third Hold'em basics check, Learn as the lesson list with one marked row, 원 페어/투 페어 spelled with a space), plus the build bump. Tag `v1.0-34`.

## Build 33 — third TestFlight build, 2026-10-17

- Source: `main` after PRs #27–#28 (lowercase English hand names in sentences, floating sheet's bottom corners concentric with the display), plus the build bump. Tag `v1.0-33`.

## Build 32 — second TestFlight build, 2026-10-17

- Source: `main` after PRs #18–#25 (progress schema 3, learning order and Chen score, known problems, exact flop equity, live language switch, best-five comparison with the why sentence said once, whole help tiles at AX sizes on small phones), plus the build bump. Tag `v1.0-32`; first build the owner installs from TestFlight.


## Build 36 — review corrections and self-directed reference learning, 2026-10-19

- Released 1.0 (36) from `6ea894f`, tag `v1.0-36`, after PRs #55 and #56. Full tree
  equals tested `bb65365`. Complete CI, Engine release and all four UI shards passed;
  main CI passed before the tag. Signed archive, bundle verification and upload passed.
- Includes recoverable graded-table gating, scalable counts, explicit grading premises,
  corrected preflop closure, Casual / 캐주얼형 wording, real terms with explanations,
  searchable bilingual glossary and readable Settings learning guide. Reference lookup
  counts as independent learning; current-question coaching counts as assisted.
- Progress schema and stored question identities are unchanged. Apple processing and
  assignment to existing internal group Me (one tester) verified; bilingual What to Test
  notes saved. No phone installation or App Store review submission was requested.
- Evidence: [release record](records/2026-10-19-build36-release.md).

## Local scope-4 candidate — October 20 (no new build number)

- Development-signed Release 1.0 (36), stacked above PR #59 (`c6ec416`), installed
  on the connected iPhone 12 mini / iOS 27.0.1. The owner explicitly selected an
  in-place update preserving progress. No uninstall or progress-file export/copy;
  the original in-progress lesson remained visible in the settled final launch.
- Three accessibility fixes: decorative glossary icon, VoiceOver focus return to
  the Settings invoker and English adjustment labels. Local Release binary SHA256
  `8ab27635cafefc1d5d0e947edaf335e0f837daa0e96faeb9915e185bc1254a0b`.
- Ten physical Debug interaction/VoiceOver checks and real Release four-cycle
  navigation passed. Full evidence and explicit audit/gesture/performance limits:
  [scope-4 record](records/2026-10-20-interaction-accessibility.md).
- This local artifact differs from distributed TestFlight build 36 at `6ea894f`.
  No tag, build-number bump, merge, TestFlight upload or App Store submission.

## 1.0 (37) — October 20

- Owner requested a new TestFlight build, then parallel delivery. PR #61 integrates
  scopes 1–4; build number is the only configuration change after reviewed `e9c8fb6`.
- Exact candidate `edd0daf` passed CI `39378993484` and independent review. Merge
  `be1c839` has the identical tree; `v1.0-37` tags that exact merge. Main CI and
  signed upload ran concurrently; archive/bundle/upload passed in `39383694571`.
  Apple processing completed; existing Me internal group (one tester) assignment
  verified. Main CI `39383668606` passed all gates on the exact merge SHA;
  owner installation is not yet verified. Bilingual What to Test notes saved.
- Native strict audit limitation remains open. No new phone installation or App Store
  review submission. [Release record](records/2026-10-20-build37-release.md).
