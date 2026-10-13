# Handoff archive: 2026-10-05 to 2026-10-13

Verbatim entries moved out of `docs/agent-handoff.md` on 2026-10-13.

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

## 2026-10-05 — Build 15 report reviewed for zero-poker adults

- Assessment only: inspected retained screenshots and report controls across
  onboarding, Learn, lesson tracks, Play, Progress and Settings; no product fixes.
- Main recommendations: teach one supported hand before advanced notation/math;
  make range-overlap verdicts understandable; simplify beginner Progress; keep
  hints clear of task context and distinguish helped practice from solo results.
- Confirmed copy mismatch: free-table review pairs 33% with four wins in ten
  (`play-free-2-s18`); source rounds wins upward. Starting-check “I'm new” report
  steps show Settings/Learn rather than questions, consistent with D46 skipping
  those questions; this is report coverage/labeling, not proof of an app failure.
- Next: owner chooses remediation scope. Live novice comprehension, capture
  clipping reproduction, actual hit areas, VoiceOver and larger text are unverified
  by this review. No implementation or release authorized by this assessment.

## 2026-10-05 — Bilingual before/after proposal report

- Created `.build/uxaudit-review-b15/index.html`: 20 anchored comparisons with
  proposed KO/EN light/dark HTML screens, decisions, tradeoffs, preserve/change
  notes, beginner difficulty, source inconsistencies and a native testing plan.
- Captured and visually reviewed 152 native baseline frames on disposable
  iPhone 12 mini / iOS 26.5 simulators: four language/theme modes, normal and AX5.
  Manifest records build 15, commit/fingerprint, checksums and two clean recaptures.
  No native app source changes, installation on the owner's phone or progress access.
- Confirmed five normal-light bilingual wrapping differences; retained source
  probability-rounding and level-label mismatches. RangeRead grading/explanation
  contradiction is resolved in current source; remaining proposal is presentation.
- Browser verified direct-file opening, eight presentation combinations, 390px
  layout, anchors/images, filters and mock controls. Proposal headings/action labels
  have matching normal KO/EN line counts. HTML AX5 is only an approximation.
- Still needs native implementation and interaction/VoiceOver/novice testing;
  capture frames do not establish scroll reachability or effective tap targets.
  Next: owner reviews the HTML proposals before choosing native remediation scope.

## 2026-10-06 — Native design refinement and calm encouragement proposal

- Owner liked all 20 comparisons and requested iOS refinement plus restrained
  compliments, encouragement and visible progress, without dramatic daily rewards.
- Added `.build/uxaudit-review-b15/encouragement.html`, linked from the report:
  eight KO/EN scenarios across lesson, summary and Records, native baseline images,
  all 20 native translation notes, data rules and copy/trigger guidance.
- Design spec: `docs/specs/2026-10-06-native-refinement-and-encouragement.md`.
  Lead with distinct recorded practice dates and completed work; keep the existing
  study streak secondary and preserve its answer/due-queue credit semantics.
  Volume is not ability improvement; no new reward currency or persistence schema.
- Browser checked 64 scenario/language/theme/text combinations, compact report
  layout, native image references, anchors, hidden-before-commit and correct/miss
  interactions. All-miss summary shows 0/2 independent and one helped separately.
  Default proposal headings have KO/EN line-count parity; full native text parity
  and native Dynamic Type/VoiceOver/novice testing remain outstanding.
- No native implementation, phone installation, progress mutation or release.
  Next: carry the approved direction into existing native components, verify the
  real UI in all four modes, and preserve grading/history/help boundaries.

## 2026-10-06 — Approved direction, refined design options

- Owner approved all 20 proposals and calm encouragement; requested refined,
  consistent options with decisions inside an HTML report. Added
  `.build/uxaudit-review-b15/refinement.html`, linked from both prior reports.
- Applied design-system, prototype, Apple design and Emil design engineering.
  A Focus recommended; B Grouped and C Learning path share existing GT tokens.
  Report questions remain pending: grouping, practice-date dots/count, summary
  retry guidance inline/disclosure. Preview controls never approve choices.
- Shared 375 px content width, 18 page edge, painted strokes with 16 card inset,
  fixed card faces, concise bilingual copy; no shrinking or language-specific breaks.
  HTML: 15,684 paired text measurements/1,728 renders/72 keys passed; 537 paired
  boxes matched; 288 enlarged frames had no overflow/word split. Controls, 390 px
  report, refs and visual representatives passed. Evidence in verification/.
- Source confirms firstText inset-role mismatches: Learn title24/semibold13,
  Hint title22/default13, skill title15/default13. Native rendered impact unmeasured;
  match role and measure visible script ink during implementation.
- No native source, progress, schema, installation or release changes. HTML AX is
  approximate; native four-mode/AX interactions, VoiceOver and novice testing open.
  Next: owner reviews report choices, then implement approved native scope using
  shared font/inset roles and preserve grading/help/history semantics.

## 2026-10-06 — Completion-first summary and quiet continuity

- Owner approved A Focus, date dots and inline short reasons. Asked to remove the
  public helped/solo distinction and considered a flame after consecutive practice.
- New report addendum: `.build/uxaudit-review-b15/completion.html`. Completion counts
  lead; help is a normal choice. Preserve committed-answer factual feedback.
- Recommend small static amber flame in today's same-size date cell after practice
  on day four onward; pending today remains outlined, gaps neutral. Qualify any
  recorded committed lesson/practice answer regardless of help/correctness.
- Native ReviewQueue currently gives helped answers study credit under due-queue
  rules, but excludes them from accuracy/review scheduling. Preserve private saved
  flags/mastery/recovery semantics; public simplification does not rewrite history.
  New calendar continuity cannot silently reuse the existing freeze-based streak.
- Spec supersession records these decisions. No native code/progress/release changes.
  Native aggregation, four-mode rendering, VoiceOver and calendar-edge tests remain
  required before implementation acceptance.
- Completion addendum browser gate: 48 combinations, normal paired heights matched,
  no report/phone overflow or premature flame; zero console errors. Root inspected
  summary and marker visuals. Evidence: verification/completion-checks.json.

## 2026-10-06 — Five-perspective critique report

- Added `.build/uxaudit-review-b15/perspectives.html`, linked from refinement and
  completion reports: 26 bilingual comments across UI/UX, hypothetical Apple
  Design Awards panel, hiring manager, recruiter and everyday novice perspectives.
- New suggestions remain unapproved: topic-led summary, recent-topic Records,
  post-commit best-five explanation. Preserve approved Focus/dots/inline/help-neutral
  completion/quiet flame. Optional decisions: first-session goal and eventual
  free-table activity-date eligibility; recommended defaults do not block work.
- Confirmed README presentation drift, with mode nuance: four visible tracks versus
  nine internal units; three-question new lessons versus five-question one-skill;
  default quick40/10 versus optional long100. Documentation fix proposed, not made.
- Root browser checked 96 combinations plus six final-copy cases; normal mock
  KO/EN line counts matched, 375 content frame/mobile scrollers, controls/refs passed.
  Evidence: verification/perspectives-checks.json. Actual panel/recruiter/user
  reactions are analytical hypotheses, not observed feedback or award predictions.
- No native implementation, progress changes or release. Next: choose new ideas,
  deliver one native learner loop, test novice transfer and record personal ownership
  and tradeoffs for a role-specific portfolio; native accessibility remains open.

## 2026-10-06 Native UX delivery
- Approved SwiftUI refinements integrated locally as `8fe0bdd`; completion-first Records, quiet fourth-day flame, native hints, bilingual action/layout fixes.
- Verified 449 Drills and 108 app unit tests; all 90 affected UI methods pass across acceptance and focused reruns, plus iOS 27 interaction checks.
- Retained 288 KO/EN light/dark normal/AX5 native frames and actual phone screenshot in `.build/native-ux-b16/index.html`; failed captures and verification limits are explicit.
- Fresh Release 1.0 (16) installed/launched on iPhone 12 mini; installed metadata and Korean first-run screen verified. No phone progress copied/backed up. Physical VoiceOver/haptics, real novices, iOS 17 and distribution remain open.

## 2026-10-07 Build 16 device flow guide
- Added `.build/native-flow-b16/index.html`: source-derived lesson, practice, table, Progress and Settings routes with controls/outcomes, alternate paths and resumable personal-device checks; a short route reduces initial testing effort.
- Exact KO/EN, light/dark and available normal/AX5 screenshots retain fixture versus actual-tap/debug-entry labels. Uncaptured system, error and completion states remain explicit; source coverage does not establish native reachability or novice comprehension.
- Root browser verification and capture manifests are retained in the report directory; native source and owner iPhone were untouched. Disposable capture simulators only; no progress imported/exported/reset on the phone.
- Next: user follows the short route on the fresh iPhone, then full flow checklists; physical VoiceOver/haptics, iOS17 and distribution gaps remain as above.
- Later on 2026-10-07: user-authorized iPhone13mini install completed; same frozen `8fe0bdd` source rebuilt Release 1.0(16) with this device provisioned. No previous Glass Table install found; installed metadata, launch and live PID verified. No uninstall/reset or phone-progress copy; evidence `.build/iphone13-install/`. Physical UI interaction remains user testing.

## 2026-10-07 Active iPhone feedback session
- User tests iPhone13mini build16 and sends comments individually. Collect/research in `.scratch/device-feedback-2026-10-07/`; deliver ONE combined HTML only after explicit testing-stop. Keep phone build stable. C001 welcome-first candidate `9075533` is worker-tested but unintegrated; C002–C028 cover terminology, teaching layouts, hint/help exits, Back navigation, chart/math scaffolding, one-tap inputs, explanatory reveals, repeat-question variety Free Play help labels and localized compact player names and ten-hand Quick Play recap/review and mid-game exit/new-game navigation and Progress/app-wide text density and compact Settings/sound/haptic preferences. C009 bounded probes did not reproduce the reported no-response; user case remains unresolved. Expanded report draft and 58 extra captures remain at `.build/native-flow-b16-comprehensive/` pending root acceptance/session-end review.

## 2026-10-07 Consolidated device-feedback report
- Testing ended; all28comments and C021 correction compiled at `.build/device-feedback-2026-10-07/index.html`, with source audits,13external references,112HTML proposal screenshots, native before views and58flow/64branch appendix.
- Browser verified390/1440xKO/ENxlight/dark,79controlsx4variants,filters/viewers/Escape,contrast pairs andzero finalconsoleerrors. Proposals remain HTML; phone16 unchanged and welcome-first17 remains unintegrated.
- Next: review proposals before native work; archive/format/session-ending persistence needs a versioned integrity plan and independent review. Native accessibility/gestures and novice comprehension remain open.

## 2026-10-07 Native feedback implementation paused
- Integrated approved native feedback through `7ca3c28`; build18 signed, Drills468 and app unit121 passed, final Settings/position/archive UI8 passed before later AX layout fixes. Independent Astra accepted exact7ca3c28. Later serial AX bounds EN/KO passed; remaining guide checks stopped at owner's explicit pause. Final screenshot matrix/report remains unfinished at sibling worktree `.build/native-ux-b18/`; do not describe interim captures as final.
- Owner requested graded1vs1 full revamp: fewer visible details, clearer learning per decision, chart access throughout; not implemented yet. Entry is PlayView→TableView; preserve preflop DefendChart/postflop checkdown grading, and decide chart access without pre-commit hand-specific recommendations. Review all KO/EN×light/dark plus AX5.
- Phone still has build16; no uninstall/reset/install or phone-data copy performed. Reinstall rule saved in AGENTS.md: fresh data unless owner explicitly asks preservation. Next after resume: graded1vs1 revamp, final native verification/gallery, then fresh install13mini. Preserve unrelated original checkout changes.

## 2026-10-08 — Native build 18 and graded practice
- Integrated through 7471843 (production49d9b01; later commits test-only): all phone-feedback changes plus graded1v1 simpler bottom choices, persistent chart reference, per-decision feedback, compact normal card context, paired KO app voice and corrected first-guide edge-back. Independent exact-head review accepted; Drills468/app121 and targeted cumulative UI gates passed, including final KOAX feedback reachability.
- Fresh18 uninstalled/reinstalled on BOTH13mini and latest-requested12mini; prelaunch containers empty of progress/preferences, version/launch/running process verified, screens not visually observed. `.build/native-ux-b18/index.html` and `graded.html`:28comments,140fixtures EN/KO×light/dark×normal/AX5,20gradedbefore frames, interactive evidence and precise provenance. Next: owner device testing; novice chart/bb comprehension, physical VoiceOver/haptics and older-iOS checks remain. Default every reinstall resets data unless explicitly preserved; no phone progress bytes copied.

## 2026-10-08 — Implementation reconciliation after intro complaint
- Read-only source audit at7471843/production49d9b01 corrected the previous blanket completion claim. Report: `docs/audits/2026-10-08-implementation-reconciliation/index.html`; machine-readable ledger alongside it and `.scratch/implementation-reconciliation-2026-10-08/`. Accounts for28device comments(18source-implemented,10partial),20earlier decisions and26perspective recommendations, with28historical EN/KO/light/dark native screenshots. Report checked390/1440,filters,images/links andzero console errors after favicon fix; no native tests/builds/device operations this audit.
- Confirmed gaps: main intro stilltwo pair questions withtrips/straight/flush optional atwrap-up; some repeatguides remainfixed/suit-swapped; first-use chart/terms incomplete ondirect routes; restored position acronyms/text-sizecap, range missing/extra evidence andouts grouping lag live UI; equity question/KO guide/restored context still conflateequity withwins despite tie-sharegrading. Many back/help routes exist butfull route acceptance isnot established. Progress flame isimplemented inRecords; unused TodayView isnot auser-facing regression.
- Preserve approved bottom actions,help-neutral public summaries,voluntary chart access,compact reopenable hints,portrait seatloop,factual recap,actual progress andcompact settings. Next: closeledger source gaps andverify default/direct/restored beginner routes beforeclaiming nextversion complete; thenfresh reinstall onlywhen requested. Novice research,physical VoiceOver/haptics/minimum-iOS andportfolio walkthrough remain evidence work,not fulfilled byHTML. No phone data read/copied/reset.

## 2026-10-10 — Approved beginner completion, build 19
- Adopted all three remaining recommendations and integrated locally through 65faf87 (source a3db5fc): five required intro comparisons/varied banks, optional chart invitation after 3 correct saved decisions, optional guided hand after basics/replay. Closed restored position/range/outs presentation and equity tie-share copy gaps; retained grades, seeds, schemas and public help neutrality.
- Drills 471/app 125 tests pass; 17 distinct targeted UI cases pass across candidates, final guided header cases 2 pass, plus an explicit normal-text guided run. Independent a3db5fc review accepted; signed Release 1.0(19) verified. `.build/native-ux-b19/index.html` contains 88 native EN/KO light/dark normal/selected AX5 fixtures with per-frame provenance, before/after, decisions and limits; mobile/desktop filter/image checks pass.
- iPhone 12 mini remains paired but disconnected/locked. No uninstall/install or phone progress copying; accepted signed build is ready for fresh installation when connected. Real novices, VoiceOver/haptics/minimum iOS 17 remain open. Preserve original unrelated dirty/untracked work and sibling completion worktree/evidence until install handoff completes.

## 2026-10-10 — Fresh iPhone 12 mini installation
- Uninstalled existing Glass Table, installed signed Release 1.0 (19), verified installed metadata and launched normally without test hooks. Physical Korean first-run welcome visually verified; left it at Start for owner testing. Evidence: `.build/device-install-b19/` (uninstall/install/launch/app JSON and stable welcome screenshot). No phone progress copied. Prior installation blocker resolved; real novice, VoiceOver/haptics and minimum-iOS evidence remain open.


## 2026-10-10 — First-five-minute research and opening exploration
- Recorded build 19 owner feedback as FFM01–08 in `.scratch/first-five-minutes/feedback.md`; consolidated builds 1–19, changes and installation-evidence gaps in `docs/build-history.md`.
- Delivered primary-source learning/engagement research and three interactive openings in `docs/reports/2026-10-10-first-five-minutes/index.html`. Recommend experience-first B; familiarity becomes an optional later preference. Preserve help-neutral progress, warm palette and native button/motion baseline; alternatives are trials, not retention claims.
- Report includes 68 HTML proposal screenshots across EN/KO and light/dark, separately labeled native before evidence, 64 browser-flow assertions, paired normal line counts, 200% natural reflow/action reachability, contrast and 390/1440 report checks. These do not establish native accessibility, novice comprehension or retention.
- Research/prototypes only: native source and installed Release 1.0 (19) unchanged. Next: owner reviews alternatives, then observed beginner testing/native implementation of the selected opening. Preserve unrelated dirty files and sibling completion worktree.


## 2026-10-10 — Approved opening, whole-app consistency exploration
- Owner approved the first-five-minute proposals, then explicitly requested further exploration without building. WAC01–06 recorded in `.scratch/whole-app-consistency/feedback.md`; linked from build history. No Swift/app build, simulator launch, phone operation or saved-data change.
- Delivered `docs/reports/2026-10-10-whole-app-consistency/index.html` and primary-source research. Recommend native-aligned opening: retain Pretendard/warm amber/native button roles; share feedback/help/navigation grammar across modes, preserve chart/model/game meanings, chip-based four-seat Free Play and existing progress definitions. Two-example exposure remains distinct from five-guide completion.
- 80 HTML proposal screenshots + 32 historical native frames with provenance; final normal EN/KO line groups match, 100 browser flow assertions pass, 44 large-text renders have reachable actions, 390/1440 report filters/images/links pass with zero final console errors. HTML is not native/novice acceptance; installed 1.0 (19) unchanged.
- Next: owner reviews app-wide compromises; observed beginner and physical mini-device tests before selected native work. No new preference decision required by this study. Preserve unrelated dirty/untracked work, historical evidence and sibling completion worktree.


## 2026-10-11 — Build 20 native opening and fresh installation
- Implemented approved experience-first/whole-app consistency decisions at `07054d0` (final production `132c331`): teach before optional familiarity, neutral Show me, two-example checkpoint, persistent stop/resume and independent replay; preserved native component roles and grading semantics.
- Final bilingual review corrected paired helper/reason lines and automatic explanation visibility. Drills401+75, progression60, opening9 and EN/KO light/dark normal/AX gates passed; 16 AX routes, 4 Next transitions and 12 final reason entries passed. Independent frozen-source review accepted.
- `.build/native-ux-b20/index.html`: 206 current native images + labeled historical before/physical welcome, decisions/provenance/limits. Signed1.0(20) uninstalled/reinstalled fresh on iPhone12mini; physical Korean welcome observed and left unadvanced; `.build/device-install-b20/verification.json`.
- Retain sibling worktree/raw proof and unrelated original work. Next: owner device feedback; novice comprehension, physical VoiceOver/thumb comfort and iOS17 runtime remain unresolved human/runtime checks.

## 2026-10-11 — Numerical/data audit of build 20
- Audited frozen07054d0; production Swift hashes unchanged, no phone/data/build-version change. `docs/audits/2026-10-11-numerical/index.html` contains full169×8chart data, actual weighted widths, primary sources, findings and reproducible evidence.
- Engine Release93 + Drills401+75 pass. Independent all2,598,960five-card/all133,784,560seven-card classifications, representative equity, blocker/formula and1250table-hand conservation checks agree.
- Open correctionsN01–N07: zeroEV described as losing in both walkthroughs/KOreveal; KoreanPFR denominator; outs currently-ahead/tied premise; tied excluded cards described as losing; ENequity called winning chance; premature review-now label; stale detailed streak. N08–N12 clarify targets, sample uncertainty, Chen provenance/tie ranking and zero-entry ratios. Two latent weighted/continuation risks separated from current policies.
- No fixes applied. Next: correction pass with semantic/date regressions, preserve grades/chart policy/help-neutral summary/data. Graded-flop sampling sensitivity against0.5/2bb thresholds is not bounded by this audit; do not claim every borderline grade is stable. Earlier human/runtime/release gates remain open.


### 2026-10-11 — Numerical audit main corrections

- Integrated N01–N07 at `21c3907`: EV equality, PFR denominator, actual outs starting state, river tie/loss explanation, equity including ties, exact review deadlines, and active streak display. Saved seed mapping, schemas and grading remain unchanged.
- Verification: Engine release 95; Drills 415 XCTest + 75 Swift Testing; app 87 XCTest + 46 Swift Testing. Records UI 4/4 completed successfully; actual feedback UI 4/4 assertions and Next transitions passed, but result finalization stalled. Independent frozen-source review accepted `64f39fd`; integrated tracked tree is identical.
- Report: `.build/numerical-fixes/index.html`, 48 native screenshots; EN/KO × light/dark, representative normal/AX5 captures. No phone installation or reset. N08–N12/model qualifications, physical VoiceOver/minimum-iOS/novice checks and AX5 full scroll reachability remain separate work.


## 2026-10-11 — Fresh build 21 device installation
- Bumped project.yml to1.0(21) at3e219db; signed Release build verified. Uninstalled existing build20 and installed21 on owner iPhone12mini; app metadata/normal launch and physical Korean welcome verified, left unadvanced. Fresh local data; no progress copied. Evidence `.build/device-install-b21/verification.json` and welcome.png. Build history appended; numerical correction report retained.


## 2026-10-11 — Brand welcome exploration, build21 feedback
- Owner wants a distinct green Glass Table/Start welcome before the guide. Delivered `docs/reports/2026-10-11-brand-welcome/index.html`: three clickable HTML compositions,36 EN/KO light/dark normal/large proposal frames plus physical build21 before. Recommend A minimalbrand; replace old guidepreamble with pairteaching to avoid an extra reading page. Keep bottomactions/native palette, explicitguideheader, skip/resume and savedstates.
- Browser24 flow combinations pass; normal heading/body/note lineparity2/2,2/2,1/1; report390/1440 overflow/images/filter/anchors checked, nofinalconsoleerrors. 165% browsertextisnotnativeDynamicType proof. Native source/phone remains1.0(21), unchanged. Next: ownerselects design before Swiftimplementation; no newinstallauthorizedbythisexploration.


### 2026-10-11 — build22 opening delivery

- Integrated independently accepted native source113e27b: OptionC green brand welcome, no normal experience question or midpoint stop, versioned balanced natural five-comparison bank, compact measured hints, paired EN/KO copy and correct resume→Previous history. Legacy saved identity/schema/recovery/credit rules preserved.
- Verified420+75 package,62model,34 distinct successful scoped UI cases; final66 EN/KO/light/dark/normal/AX frames. Earlier failed jobs remain qualified; targeted fixes passed. Report: `.build/opening-b22/report/index.html`; raw logs retained in sibling worktree.
- Signed1.0(22) uninstalled/reinstalled fresh on iPhone12mini, metadata and physical Korean green welcome verified; left unadvanced, no phone progress copied. Evidence `.build/device-install-b22/verification.json`. Remaining novice, physical VoiceOver and iOS17 checks; other menu spacing source inventory only. Next: owner tests build22 and records specific route/screenshot feedback.


### 2026-10-11 — workspace folder consolidation

- Owner requested cleanup of all Glass Table sibling folders. Archived all seven historical worktrees, including source/index/status/patches, reports/screenshots/82xcresults/signedapps, with per-file SHA256 verification; generated compilation caches excluded. Removed seven checkouts through Git; only canonical glass-table remains registered. All519 tracked files and every branch ref preserved during removal; reclaimed5.21GiB.
- Durable archive `.archive/2026-10-11-workspace-cleanup/` includes verified all-ref Git bundle and path map. Current build22 report and device-install evidence stay canonical; install verification now also points to archived signedbinary (SHA matches). Local report servers moved to canonical paths. See `docs/workspace-cleanup.md`.
- App code and phone install unchanged. Continue all new development in canonical folder; preserve archived history and other projects.


### 2026-10-11 — audit fix pass on main (Claude)

- Owner asked to drop the feature branch and work on `main`: merged `origin/main` (support contact page) into `feat/friendly-casual`, fast-forwarded local `main`, deleted the branch. Nothing pushed.
- Fixed most findings of the build-22 audit (https://claude.ai/code/artifact/1aad40ec-49c6-437d-b7a0-49c73efd6387). Opening guide: body copy wraps naturally instead of `LessonPairedText` forced breaks; "see the explanation first" offered once; optional pages labelled "테이블 규칙 n/4"; SB/BB explained. Free table: "팟 N칩", winner seat shows hand net, blind labels, kicker reason, raise presets in chips + multiples, two new table-guide entries. Lessons: showdown hands side by side, pot counting shows each seat's separate additions, next-lesson button on the summary, 선별형/공격형, chips in the pot-odds example. Also hand-ranks retry, lesson-list status words, glossary in -해요 and beginner-first, Play tab copy, friendly dates in Records.
- Decision: EN/KO equal-height parity is kept for opening headings only. Body parity was what forced the hand-placed breaks the owner keeps reporting, so `BilingualConsistencyB20Tests` no longer asserts it for `firstLesson.rule`/`.question`/teach-pair body.
- UI suite on iPhone 17: 67 of 238 failed with these changes; 16 are the Bilingual suite (needs a 375-pt phone), and 48 of the other 51 fail identically on the unmodified commit `19f2d10` (stale expectations such as the pre-b22 welcome sentence). The three caused by this pass were fixed. The stale 48 are an open issue, not addressed here.
- Not done: free-table dock/seat layout at 2–3 players, graded vs free table look, range-advantage 59.6/59.1 mismatch, opening-guide card-to-choices gap, hint entry points, AX5 opening header, Skip on the brand screen, study-guide length, worked-example emptiness, tab bar translucency, store screenshots.
- Next: owner picks which deferred layout items to take; triage the 48 stale UI tests.

### 2026-10-11 — audit follow-ups: decide first, implement at the end (Claude)

- Owner approved all "after" changes in `2c6047b` and `cbeadfe` for now. Bilingual suite on iPhone 12 mini: 16/16.
- New working mode: investigate each remaining audit item one at a time, record the decision, implement all together at the end. Map, queue and per-item findings: `.scratch/audit-followups-2026-10-11/map.md`.
- Awaiting owner decisions: 01 Korean/English line parity, 02 free-table empty space. Items 3–14 not yet investigated.
- Next report must use larger screenshots (at most two phones per image).

### 2026-10-12 — audit follow-ups decided and implementation started (Claude)

- All queue items decided by the owner; 16 decisions with evidence in `.scratch/audit-followups-2026-10-11/map.md` and `issues/`. Mock technique: throwaway `git archive` copy with env-gated variants, real sweep renders.
- Implementing on local branch `feat/audit-followups` (off `main` at `cbeadfe`, not pushed), one commit per item: panel corner 34 (`21e7408`), range-advantage answer label (`e424755`), single lesson help row (`19548fe`), brand-screen Skip under Start + header cap + two-sentence rules (`5f22fbc`), one bb sentence (`29262b3`), graded table on felt (`820536e`), free table fills the band + price/pot on your turn (`da8b0cb`), four-page study guide with numbered lists (`f45ecb6`). Each verified by build, `GlassTableTests` (89 pass) and light Korean screenshots at normal and AX5; UI tests not yet repaired.
- Choices made without a separate owner answer: study guide header uses the existing Settings row name "공부 방법 / How learning works" rather than the proposed "공부하는 법"; graded answer screen got extra padding so cards sit inside the felt; the doubled hand-ranking question is untouched.
- Found already in place: Learn tab bottom space under the tab bar (`LearnView.swift:60`).
- Open: 12b worked example on the explanation page is not started (the example is a full interactive `WalkthroughView`, so inlining it is a redesign that needs a mock); UI test repair (41 outdated + those broken by this pass, both phones); one-line-tolerance bilingual test; full English sweep at both sizes; store screenshots and `CONTEXT.md:143` / `docs/submission.md` recipe; before/after report with at most two phones per image.
- Next: read the full UI suite result on iPhone 17 (`scratchpad/ui17.log` this session), repair tests by group.

### 2026-10-12 — audit follow-ups implemented and gated (Claude)

- Branch `feat/audit-followups` (local, not pushed) now also has: dock heading above the help pill at accessibility sizes (`4dba696`), UI tests brought up to the current app (`f16a10e`), store screenshots retaken in Korean and English with the recipe in `docs/submission.md` (`d7681ef`), Bilingual suite no longer tied to a 375 pt phone (`6252289`).
- Gate, both phones on iOS 26.5: iPhone 12 mini full UI suite 238 tests, 0 failed, 11 skipped. iPhone 17 full run 221 passed; the 16 Bilingual tests were stopped by the width check and pass 16/16 once it is removed; `FreeTableBackFlowTests/testAXKOExpandedPolicyEndReachable` passed 3 of 4 runs unchanged (intermittent, cause not found). No single all-green iPhone 17 run was made after `6252289`.
- Line parity (sweeps `.uisweep/20261012-163710-LxHMDA` ko, `.uisweep/20261012-154235-eeHlNY` en; `.scratch/consistent-learning-table/native-audit/match.py`): normal size 402 pairs, none differ by more than one line. AX5: two differ by two lines (`HoldemBasicsView.swift:241`, `LessonLearningUI.swift:334`), left for the owner.
- Report with two-phone images: https://claude.ai/artifact/JUwpSsMWHvXqjEsmLeHADQ
- Test environment notes: use the iPhone 17 iOS 26.5 simulator by id, the bare name picks the iOS 27 beta. A leftover `outs-progress.json` in that simulator's app container made a fresh-store test fail; it was moved out, not deleted. Twice a run on iPhone 17 executed a stale installed test bundle right after a rebuild; a re-run with `test-without-building` used the new one.
- Open for the owner: 12b worked example (needs a mock), study guide name, doubled hand-ranking question, the two AX5 two-line differences, tight English help tabs on the hand review, AX5 free-table actions pushed lower by the price/pot facts, whether to push. iOS 27 beta only: Settings language switch does not re-render the screen; play-table contrast audit fails.
- Unused code seen and left: `ProgressionModel.shouldPresentFirstPlacement`, `seatSentence`.
- This file carries an older uncommitted rewrite from before this session; it is still uncommitted.
- Later the same day, owner request: one corner radius. `GT.Radius.control` is now 10 and is used for every seat corner, the felt (`TableSurface.radius`), the floating bottom panel and controls; this supersedes the fixed 34 pt panel corner. Pills, playing cards and `GT.Radius.panel` cards unchanged. Checked on screenshots in both languages and at AX5; unit tests 89/89, `BottomPanelB22Tests` 8/8, `FreeDockFlowTests` 7/7 on re-run (`testResultProseScrollsWithoutMovingActionsAtNormalAndAXSizes` failed once in three runs). Full UI suite not re-run after this change. Owner decides the seven open items next.

### 2026-10-13 — raise panel, written examples, store screenshots (Claude)

- Owner approved every implemented decision in the report and asked for them finalized with the single corner radius. Still local on `feat/audit-followups`, not pushed.
- Raise panel (`c66a8d8`): title centred on the back arrow and help pill; minus/plus buttons match the raise button's height; the edge-attached bottom panel uses `GT.Radius.control`; unused `GT.Radius.sheet` removed.
- 12b decided as option A (`fcc1a78`): every explanation page ends with a written "예시 / Example" box for all 18 concepts; the "예시 보기" button and its walkthrough step are gone from that page. The step-by-step walkthrough is still reached on first exposure in a lesson, from Records replay and from the retry sheet. Wording table is in the report for the owner to read; not yet confirmed line by line.
- Store screenshots retaken in both languages with the new corners (`9a1822f`).
- Test environment: the simulator can keep running an old installed UI test runner after a rebuild. `xcrun simctl uninstall <device> com.michaelju.glasstable.GlassTableUITests.xctrunner` before the run fixes it; this explains the earlier "stale bundle" runs.
- Verification so far: unit tests 89/89; on iPhone 12 mini `DeviceFeedbackLessonTests` 2/2, `LearningFlowTests/testGradedQuestionReopensTheExplanationWithItsExample`, and two Bilingual AX5 interaction tests pass. Full UI suite on both phones started after `9a1822f`; result not yet recorded here.
- Open for the owner, one by one: study guide name, doubled hand-ranking question, the two AX5 two-line English texts, tight English help tabs on the hand review (visible on the Pro Max store screenshot too), AX5 free-table actions, whether to push.
- Later 2026-10-13: owner decided the rest. Study guide name kept. `7e9ac4b`: hand-ranking panel question "가장 좋은 다섯 장으로 누가 이길까요?", shorter English in `HoldemBasicsView` and `LessonLearningUI`, hand review English tabs "Help / History / Guide", turn facts on one line each at accessibility sizes. Branch pushed to `origin/feat/audit-followups` (owner delegated the push decision); `main` not pushed.
- Gate at `9a1822f`, iOS 26.5: iPhone 12 mini and iPhone 17 each 238 tests, 11 skipped, 1 failed: `AccessibilityAuditTests/testPlayTable` "Contrast failed" with no element, 3 of 3 on re-run. It also fails on a `git archive` copy of `6252289` (before the corner change), where it passed on 2026-10-12, so it is not caused by this branch's later commits; cause unknown. After `7e9ac4b`: unit 89/89 and `FreeDockFlowTests`, `FreeTableBackFlowTests`, `FreeRaiseFlowTests`, `BilingualConsistencyB20Tests` 42/42 on iPhone 12 mini; full suite not repeated.
- Open: the play-table contrast audit; this file's older uncommitted rewrite is still uncommitted.
- 2026-10-13 afternoon: `AccessibilityAuditTests/testPlayTable` on unchanged `7e9ac4b` passes 4 of 4 on iPhone 12 mini and fails 4 of 4 on iPhone 17 (both iOS 26.5, light, normal text, `appAppearance` = system). Detail on failure: "Contrast failed for SwiftUI.AccessibilityNode", no frame. Text contrast measured from the mini light screenshot is 5.2:1 or higher everywhere. Cause still unknown; not tied to this branch's commits. Owner asked whether to delete this file; it was not deleted because the uncommitted version is the current record (entries from 2026-10-05 on), not an old one. Awaiting the owner's word on committing it.
- 2026-10-13 15:30: owner noticed large bottom corners on the fold/raise buttons on iPhone 17 and asked that no corner depend on the display curve. Cause: `GTDockControlBackground` used `ConcentricRectangle` with `.concentric` outer bottom corners. `89a55c3` replaces it with a fixed `GT.Radius.control` rounded rectangle and removes `GTCornerSide`, `cornerSide`, and the `floatingDock` environment key. Checked on iPhone 17 Pro Max, 17, 15 Pro, 16e, 12 mini screenshots (play-hand, play-raise, table-preflop). iPhone 17: unit 89/89 plus `AccessibilityAuditTests`, `FreeDockFlowTests`, `FreeRaiseFlowTests`, `BottomPanelB22Tests` 27/27; `testPlayTable` then passed 4 of 4 on iPhone 17 where it had failed 4 of 4 before the fix. The overnight iPhone 12 mini failures remain unexplained. Store screenshots 03-play (ko, en) and en-04-review retaken (`4c191a6`); branch pushed. Full UI suite not repeated after `89a55c3`.
- Open with the owner: bb or chips in examples 8, 15 (and 18); whether to commit this file.
