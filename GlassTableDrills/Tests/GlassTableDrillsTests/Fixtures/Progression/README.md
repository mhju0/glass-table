# progression.json golden fixtures

Each file was written by the shipped build's own `ProgressionStore.save`, not by
today's code. Content is synthetic: fixed dates around 2026-09-13 / 2026-09-25,
seeds and `fixture-*` IDs. No real phone progress is included.

| File | Build | Source commit | Shape |
|---|---|---|---|
| `schema1-build3.json` | 1.0 (3) | `b8fe193` | schema 1: concepts, nodes, streak, answers, `firstLessonCompleted` |
| `schema2-build16.json` | 1.0 (16) | `8fe0bdd` | schema 2 before quick play: summaries, evidence, placement, lesson/round/review snapshots with graded answers and a draft, open-table hand, recent hands, `lessonTrend`, `basicsLessonCompleted` |
| `schema2-build22.json` | 1.0 (22) | `113e27b` | build 16 plus `quickPlaySessions` (one finished, one active), `activeQuickPlaySessionID`, `pendingFirstLesson` |
| `schema2-build30.json` | 1.0 (30) | `5c040c1` | build 22 plus `NodeRecord.best` |
| `schema3-build34.json` | 1.0 (34) | `v1.0-34` | schema 3, the last shape before `lastNodeID` (schema 4): build 34 loaded `schema2-build30.json`, upgraded it and saved it |

Build commits come from `docs/build-history.md` and the `CFBundleVersion` bumps in
`project.yml`.

## How they were made (2026-10-16)

1. `git archive <commit> GlassTableDrills GlassTableEngine | tar -x -C <tmp>/bN`
   into a directory outside the repository.
2. Add a one-off XCTest `GoldenFixtureGenerator` to that copy's
   `GlassTableDrillsTests`. It builds a `ProgressState` through that build's APIs
   (`ReviewQueue.recordReview`, `recordDetailedAttempt`, `gradeShowdown`,
   `gradeEVCall`, `PracticeTableState` play-through, `captureQuickPlay` /
   `finishQuickPlay`), saves it with `ProgressionStore(url:).save`, and checks that
   the same build loads it back.
3. `GT_FIXTURE_OUT=<file> swift test --package-path <tmp>/bN/GlassTableDrills
   --filter GoldenFixtureGenerator`, then copy the JSON here.

For `schema3-build34.json` (2026-10-18) the generator loaded `schema2-build30.json`
through build 34's `ProgressionStore.load` (which upgrades to schema 3) and saved the
result with build 34's `save`; schema 3 has schema 2's data, so no new content was
needed.

The generator was not committed; only its output was. Do not hand-edit these files.
When the schema changes, add a fixture written by the last build of the old schema
in the same way, and add it to `ProgressionGoldenFileTests.fixtures`.
