# 0001 · Versioned progression.json

Date: 2026-10-16 · Status: accepted

## Decision

Any new persisted key in `progression.json`, or a new meaning for an existing key,
bumps `ProgressState.currentSchemaVersion`. On first load of an older file the store
copies it byte-for-byte to `progression.schema-<N>-<UUID>.json` before writing the
upgraded file; a failed copy aborts the upgrade and leaves the original in place.
Every shipped shape has a golden fixture in
`GlassTableDrills/Tests/GlassTableDrillsTests/Fixtures/Progression/` that must load,
validate, re-grade and save without losing a key.

Schema 3 (this decision) has the same data as schema 2. It exists to close the gap
described below for files written by builds 30 and later.

## Why

- Silent field loss on downgrade. `quickPlaySessions`, `activeQuickPlaySessionID`,
  `lessonTrend`, `basicsLessonCompleted` and `NodeRecord.best` were added under
  schema 2 and decoded with `decodeIfPresent`. A build that predates a key reads a
  newer schema-2 file as valid, ignores the key, and drops it on its next save. A
  TestFlight rollback or reinstalling an older build would erase that progress
  without any error. A version bump turns the same situation into an
  `unsupportedSchemaVersion` refusal and the recovery screen, with the file intact.
- Shapes become permanent once the App Store ships them. Every shape a user can
  have on disk must keep loading in every later build; fixtures written by the old
  builds themselves are the only check that does not depend on today's code.

## Consequences

- Builds before schema 3 (1.0 build 30 and earlier) refuse a schema-3 file. They
  show the recovery screen (`StoreRecoveryView`) instead of loading it; the file is
  not modified.
- Backup copies accumulate, one per upgrade, and are never deleted by the app.
- The downgrade gap still exists *within* one schema version: an unknown key at the
  current version is dropped on save (`ProgressionGoldenFileTests`
  `testUnknownKeyAtTheCurrentSchemaIsDroppedOnSave`). That is why the rule is
  "every new key bumps", not "unknown keys are preserved".

## Format versions inside the file

| Version | Field | Accepted values | Checked in |
|---|---|---|---|
| File schema | `schemaVersion` | 1…`ProgressState.currentSchemaVersion` (13). Newer files are refused. | `ProgressionStore.decodeAndValidate` (header read before full decode), `validate(_ ProgressState)` and `load`/`upgrade` |
| Lesson session format | `activeNodeSession.formatVersion` | 1…`Curriculum.sessionFormat` (2); 1 = five questions, 2 = three | `ProgressionStore.validate(_ NodeSessionSnapshot)` via `Curriculum.sessionConcepts(for:seed:format:)` |
| Pair lesson content | `pairLesson.contentVersion` | Exactly 1 when `pairLesson` is present | `ProgressionStore.validate(_ ProgressState)` via `PairLessonProgress.isValid` |
| Pair lesson follow-up | `pairLessonFollowUp.contentVersion` | Exactly 1 when `pairLessonFollowUp` is present | `ProgressionStore.validate(_ ProgressState)` via `PairLessonFollowUpProgress.isValid` |
| Unit A content | `unitA.contentVersion` | Exactly 1 when `unitA` is present | `ProgressionStore.validate(_ ProgressState)` via `UnitAProgress.isValid` |
| Unit B content | `unitB.contentVersion` | Exactly 1 when `unitB` is present | `ProgressionStore.validate(_ ProgressState)` via `UnitBProgress.isValid` |
| On-demand course review | `courseReview.contentVersion` | Exactly 1 when present | `CourseReviewSession.isValid(in:)` |
| Table course content | `tableCourse.*.contentVersion` | Exactly 1 for each present unit | `TableCourseProgress.isValid` |
| Practice round format | `activeRound.formatVersion` | 1 (no `level`) or 2 (optional `level` 2…the skill's highest step, D53), with `questionCount` 5 | `ProgressionStore.validate(_ PracticeRound)` |
| Review session format | `activeReviewSession.formatVersion` | exactly 1; optional `levels`, one step (1…3, within the skill's highest) per question (D53) | `ProgressionStore.validate(_ ReviewSessionSnapshot)` |
| Daily-summary format | `dailySummaries[].key.formatVersion`, `recentEvidence[].key.formatVersion` | 1…1,000,000, kept as written; Records compares only equal versions. Optional `key.level` 2…3 (D53); mode and concept "table" for table decisions | `ProgressionStore.validate(_ DailyPracticeSummary)`; `RecordsView` |
| Saved reveal | `reveal.version` inside saved answers | exactly 1 | `SavedDrillReveal.isValid` |
| Opening guide | `pendingFirstLesson.comparisonVersion` | 1…`FirstLesson.currentComparisonVersion` (2); missing reads as 1 | `FirstLessonSnapshot.init(from:)` / `isValid` |
| Placement | `placement.assessmentVersion` | exactly `PlacementGuide.version` (1) | `ProgressionStore.validate(_ PlacementState)` |
| Table rules / bot policy | `tableState.storedRulesVersion`, `storedPolicyVersion`; `recentHands[].rulesVersion`, `policyVersion` | equal to `PracticeTableState.rulesVersion` / `policyVersion` (1) | `PracticeTableState.validate`; style report filters other versions out |

A new inner version value is a new meaning for an existing key, so it bumps the
schema too. The inner checks stay: they are what rejects an impossible combination
inside an otherwise valid file.

## Schema 6 · Pair lesson pilot

The optional `pairLesson` stores the pilot lesson's question schedule, answers,
draft and retry position. Schema 5 files upgrade with this field absent. A file
that carries the key under an older schema is refused before migration.
Existing format-1 and format-2 lesson sessions keep their saved questions and
grading. The standard pre-upgrade byte copy also applies to schema 5.

## Schema 7 · Pair lesson follow-up

The optional `pairLessonFollowUp` stores the extra hands, their answers and the
scheduled review day. It requires a completed pair lesson run. A replay can
retain follow-up from a previous run. Schema 6 files retain the original
lesson and upgrade with no follow-up state. A finished schema 6 lesson has no
completion date, so follow-up begins with the next completed run. The standard
pre-upgrade copy preserves the schema 6 file byte-for-byte. A file carrying the
new key under an older schema is refused.

## Schema 8 · Unit A

The optional `unitA` stores progress through the five introductory lessons,
including the mixed checkpoint. Old saves upgrade with no Unit A activity and
retain earlier lesson, review and table state. The standard pre-upgrade copy
preserves the schema 7 file byte-for-byte. A file carrying `unitA` under an
older schema is refused.


## Schema 9 · Unit B

The optional `unitB` stores showdown lesson progress, including best-five drafts,
comparison answers, exact corrections and earlier scores. Earlier files upgrade
without Unit B activity. The standard pre-upgrade copy preserves their original
bytes. Passing the existing one-pair lesson can advance B2, and the stored B2
score must be supported by the original lesson record. Fresh practice and due
review stay in the original pair follow-up state.


## Schema 10 · On-demand course review

The optional `courseReview` stores one active lesson, unit or cumulative review.
It holds the scope, seeded activity identities, set cursor, draft, first answers
and exact correction progress. Answer coverage is frozen for the current pass.
Schema 9 upgrades preserve the original bytes before writing the new format.
New review commits use the same atomic save path as lessons and do not update
course clears, mastery or due-review timing.


## Schema 11 · Turns, chips and starting hands

The optional `tableCourse` records a separate cursor, draft, answers and
corrections for each new unit and the guided practice hand. Keys must match their
unit. The guided hand requires a finished chip unit. Each save uses the existing
atomic write path. Files from schema 10 retain their original review state and
receive a byte-for-byte pre-upgrade backup. The new held-out exercises extend the
review catalog while preserving every existing question and seed.


## Schema 12 · Expanded core course and combinations

Schema 12 extends the accepted `tableCourse` units through the capstone and the
combinations elective. It also admits review scopes and skills for those units.
The existing fields and content IDs retain their meaning. The normal upgrade
backs up the schema 11 bytes before writing schema 12, preserving prior unit
drafts and the frozen review. Older schemas cannot contain a new unit or scope.


## Schema 13 · Expected value and board patterns

Schema 13 admits two more `tableCourse` units and their review scopes and
skills. Earlier unit cursors and frozen review activities keep their exact
meaning. An upgrade copies the schema 12 bytes before writing the new
schema. A file with a new elective under an older schema is rejected.
