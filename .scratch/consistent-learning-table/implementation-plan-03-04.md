# Implementation plan: issues 03 and 04

Date: 2026-09-25. Owner chose the full plan for both issues ("Full plan", 2026-09-25).
Issue 04 is Class 3 (persistent state and progression semantics). This plan must pass
an independent read-only review before the storage part is implemented.

## Issue 04 — help that reveals calculations counts as practice

### Current behaviour (read in this session)

- Three answer routes persist graded answers: lesson nodes (`commitNodeAnswer`),
  single-skill practice rounds (`commitRoundAnswer`) and review sessions
  (`commitReviewAnswer`), all in `GlassTable/Sources/ProgressionModel.swift`.
- `commitRoundAnswer` already takes `assisted`: it skips `ReviewQueue.recordReview`
  (FSRS, accuracy counters, miss streak) and keys daily evidence `assisted: true`.
  `commitNodeAnswer` rejects `assisted == true` outright. `commitReviewAnswer` has no
  parameter and always records review credit.
- Node completion builds `SessionEvidence` from every stored answer and requires one
  answer per scheduled entry (`SessionEvidence.validates`) before clearing the node
  and calling `Mastery.promote`.
- No native control shows the current question's calculated information before the
  learner commits. The guided "together" hint is ungraded already.

### Rule (owner-approved spec decision 7 and teaching plan)

- Revealing calculated information about the current question before committing marks
  that attempt as assisted. Replaying public actions (Back, Replay) is not help.
  Definitions and the worked example of a different spot are not help.
- An assisted attempt is practice: it appears in daily history as "with help", but
  gives no review (FSRS) credit, no accuracy/total/miss-streak change, no timing
  sample, and no mastery evidence.
- Showing the steps after committing never changes an attempt's credit.
- Existing answers are never relabelled; `nil` means unassisted.

### Storage (all additive, optional, omitted when nil)

1. `RoundAnswer.assisted: Bool?` — set to `true` only for assisted commits.
2. `PracticeRound.helpOrdinal`, `NodeSessionSnapshot.helpOrdinal`,
   `ReviewSessionSnapshot.helpOrdinal: Int?` — the ordinal whose help was opened. It
   is written the moment help is opened (before the totals render), so exit, relaunch
   and language change keep it. A different ordinal means "not assisted", so moving to
   the next question needs no clearing step, but `next…Question` clears it anyway.
3. No change to `DailyPracticeKey` (already has `assisted`), `ConceptRecord`,
   `ReviewCard`, or placement.

Synthesized `Codable` decodes a missing optional as nil and omits nil on encode, so
old files read unchanged and files written without help are byte-compatible in
shape. Tests: decode a pre-change fixture; round-trip each new field.

### Model API

- `markHelpUsed(route:sessionID:ordinal:expectedEpoch:) -> Bool`: only when the
  session is in `.question` at that ordinal; idempotent; one `commit`.
- Each commit derives `assisted = parameter || stored helpOrdinal == ordinal`, so a
  UI that forgets the flag cannot launder help into independent credit.
- `commitNodeAnswer`: drop the `!assisted` rejection; assisted skips
  `recordReview`, keys evidence assisted, records no seconds, stores
  `RoundAnswer.assisted = true`.
- `commitReviewAnswer`: same treatment. The concept is not rescheduled, so it stays
  due and returns in a later review (no credit without independent recall).
- `commitRoundAnswer`: add the stored-flag derivation and `RoundAnswer.assisted`.

### Node completion and mastery

- `SessionEvidence` gains `assisted: Int` (in-memory only). `record(spotOn:assisted:)`
  counts an assisted answer in `assisted` and not in `attempted`/`spotOn`.
- `validates` requires `attempted + assisted == scheduled count` per concept, so a
  lesson with help still finishes and the node is marked cleared (path completion is
  practice completion; the path is open-access anyway).
- `isComplete` stays `attempted > 0 …` so a concept answered only with help gets no
  promotion; `isPerfect` also requires `assisted == 0`. Proficient/mastered therefore
  need a fully independent session. Familiar comes from lifetime accuracy, which help
  never touches.
- The lesson summary counts "with help" answers separately from right and missed.

### UI (first solving hint: pot totals)

- Pot questions get a "합계 보기 / Show totals" control beside the existing "How to
  count" guide. The first tap asks for confirmation: "이 문제는 도움 받은 연습으로
  기록돼요. / This question will count as practice with help." Confirming calls
  `markHelpUsed` and only then shows each seat's paid total on the table.
- The result sheet for an assisted attempt leads with "도움을 받아 풀었어요 /
  Solved with help" and keeps the same geometry as correct/incorrect results.
- Restored questions read the stored flag, so totals stay visible after relaunch.

### Verification

- Drills: decode old JSON; `SessionEvidence` validation/promotion with help.
- App model: per route, help then commit gives assisted evidence, no FSRS/accuracy
  change, no timing; exit/relaunch (reload store) keeps the flag; repeating the
  commit does not double count; help after commit is refused; node with help clears
  but does not promote; review with help stays due.
- UI: pot help flow at normal and AX5; relaunch keeps totals and assisted result.

## Issue 03 — first-use explanations and contextual help

### Entry routes to cover (per concept checklist in `entry-routes.md`)

1. Lesson node, first exposure: worked example → try together → questions.
2. Lesson node, returning: questions directly (example skipped automatically).
3. Single-skill practice round: its own intro phase.
4. Review session: mixed concepts, no onboarding.
5. Records "천천히" replay of a concept's worked example.
6. Resume/restore after exit or relaunch.
7. Play four-seat table; 8. graded heads-up exercise; 9. placement check.

### Changes

- Purpose line: the worked example's first step shows the concept's one-sentence
  `why` under the header.
- One learner action per worked example: the first step whose payload is a value is
  covered by "눌러서 계산해 보기 / Tap to work it out"; Next stays disabled until the
  learner taps it, and the caption names what was just revealed. Applies to all 18
  concepts because every script derives from its spot.
- Reopen control: every graded question (lesson, practice, review, restored) has a
  "설명 / Explain" control that opens the concept's title, why, how, a notation note
  where relevant, and "예시 다시 보기 / Watch an example" (a different spot). It is
  a definition, not a solving hint, so it never marks help.
- Position: add the approved rule example (before shared cards BB acts last; after
  them play goes clockwise from SB) to its explanation; no answer seat is outlined.
- Play: a short first-visit guide (your cards, hidden opponent cards, shared cards,
  the pot, whose turn, what each action costs), reopenable from the table.
- Language/appearance changes never restart an introduction (saved show step).

### Verification

- UI tests: explain control present on each route; worked example requires the tap;
  Play guide shows once and reopens; language switch keeps the step.
- Screens: uisweep at large and AX5, KO/EN, one new screen per new surface; line
  parity at the default size on the 12 mini.

## Independent review (2026-09-26): approve with changes

A read-only reviewer checked the issue 04 plan against the code. Changes adopted:

1. **Seeds must move after help.** Every route seeds new spots from `record.total`,
   which assisted answers do not change, so help → abandon → restart would replay the
   same spot for full credit. New seeds add the concept's assisted attempt count from
   `dailySummaries` (retained forever). Without help the seed is unchanged. Test: help,
   abandon, restart gives a different spot in each route.
2. **Evidence.** `validates` checks `attempted + assisted == count` and no longer
   requires `isComplete`; the inline completion in `commitNodeAnswer` reads
   `answer.assisted`; the promote loop skips concepts with `attempted == 0` so no empty
   `ConceptRecord` is written; `SessionEvidence.init` keeps its existing signature
   with `assisted` defaulting to 0.
3. **Rounds in their "together" step refuse `markHelpUsed`** (`introPhase == nil`
   required); guided steps may show totals without marking. The UI reveals totals only
   when `markHelpUsed` returns true (a pending save error refuses writes).
4. **Every summary counts help separately:** lesson restore/summary, round summary,
   review summary. Copy that promises a review date is not shown for concepts answered
   only with help.
5. **Streak (decision):** help is practice, so an assisted answer still records the
   day's session for the streak. Accuracy, FSRS, timing and mastery stay untouched.
6. **Validation:** `helpOrdinal` must be in range and not ahead of `ordinal`; a guided
   answer is never assisted; `assisted` is encoded only when true. An older build would
   drop the new keys on its next save; acceptable for a pre-release build.
7. Review route cannot loop; the assisted concept stays due and returns first.
8. Records prefers the independent lane when both exist on the same day.
