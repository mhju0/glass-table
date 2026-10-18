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
| File schema | `schemaVersion` | 1…`ProgressState.currentSchemaVersion` (5); newer is refused | `ProgressionStore.decodeAndValidate` (header read before full decode) and `validate(_ ProgressState)`; upgrade in `ProgressionStore.load`/`upgrade` |
| Lesson session format | `activeNodeSession.formatVersion` | 1…`Curriculum.sessionFormat` (2); 1 = five questions, 2 = three | `ProgressionStore.validate(_ NodeSessionSnapshot)` via `Curriculum.sessionConcepts(for:seed:format:)` |
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
