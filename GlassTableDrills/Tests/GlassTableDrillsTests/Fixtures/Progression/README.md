# progression.json golden fixtures

Each file was written by the corresponding build's `ProgressionStore.save`.
Content is synthetic and uses fixed dates, seeds and IDs.

| File | Build | Source commit | Shape |
|---|---|---|---|
| `schema1-build3.json` | 1.0 (3) | `b8fe193` | schema 1: concepts, nodes, streak, answers, `firstLessonCompleted` |
| `schema2-build16.json` | 1.0 (16) | `8fe0bdd` | schema 2 before quick play: summaries, evidence, placement, lesson/round/review snapshots with graded answers and a draft, open-table hand, recent hands, `lessonTrend`, `basicsLessonCompleted` |
| `schema2-build22.json` | 1.0 (22) | `113e27b` | build 16 plus `quickPlaySessions` (one finished, one active), `activeQuickPlaySessionID`, `pendingFirstLesson` |
| `schema2-build30.json` | 1.0 (30) | `5c040c1` | build 22 plus `NodeRecord.best` |
| `schema3-build34.json` | 1.0 (34) | `v1.0-34` | schema 3, the last shape before `lastNodeID` (schema 4): build 34 loaded `schema2-build30.json`, upgraded it and saved it |
| `schema5-build37.json` | 1.0 (37) | `v1.0-37` | schema 5, steps (D53): `schema4-build35.json` upgraded, plus a pot-counting practice round at step 3 (format 2) with one answer and a step-2 daily summary |
| `schema4-build35.json` | 1.0 (35), not shipped | `ceb0ea8` (PR #43 branch) | schema 4, the last shape before steps (schema 5): `schema3-build34.json` upgraded, with showdown at 능숙, potOdds at 숙달 and `lastNodeID` `u1-potMath` |
| `schema6-pair-retry.json` | B2 pilot, not shipped | `feat/warm-native-ui` pilot | schema 6, with pair lesson seed 0, one guided and one solo miss, the first retry answered and the second retry's draft saved |
| `schema7-pair-follow-up.json` | B2 follow-up, not shipped | `feat/warm-native-ui` Phase 01 | schema 7, with a completed pair lesson, fresh hand at feedback and the scheduled review hand with a draft selection |
| `schema8-unit-a-reveal.json` | Unit A, not shipped | `feat/warm-native-ui` Phase 03 | schema 8, with the schema 7 pair follow-up and Unit A's first retrieval at feedback |

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

For `schema4-build35.json` (2026-10-18) the generator ran on the PR #43 branch
(schema 4, which shipped in no build): it loaded `schema3-build34.json`, set
showdown to proficient (2026-09-25), potOdds to mastered 13 h later and
`lastNodeID`, saved with that branch's `save`, and checked the reload was equal.

For `schema5-build37.json` (2026-10-31) `GlassTableDrills/Sources` was unchanged from
`v1.0-37`, so the generator ran on `main` (`608f813`): it loaded `schema4-build35.json`
(which upgrades to schema 5), added the round and summary above, saved, and checked the
reload was equal. Schema 5 shipped in builds 35–37 to TestFlight.

For `schema6-pair-retry.json` a one-off XCTest advanced the seeded pair lesson
through the worked example and ten questions, then saved the second retry draft
through `ProgressionStore.save`.

For `schema7-pair-follow-up.json` a one-off XCTest completed pair lesson seed 0
with a hint on the first solo hand, then captured follow-up scheduled at
2026-11-23 23:00 UTC. It submitted an incorrect answer on the fresh hand and
selected the correct side of the review hand on its due day. The test saved
with `ProgressionStore.save` and checked that the readback was equal.

For `schema8-unit-a-reveal.json` a one-off XCTest loaded the schema 7 fixture,
advanced Unit A to its first question, selected the second answer and
submitted it. It saved both progress records through `ProgressionStore.save`
and checked that the readback was equal.

Keep the fixtures as written by their respective encoders. When the schema
changes, capture any missing shape from the preceding schema and add a current
fixture to `ProgressionGoldenFileTests.fixtures`.

- `schema9-unit-b-draft.json` was written by the schema 9 encoder. It extends the
  schema 8 fixture with completed showdown lessons B1–B9 and a two-card draft in
  the first independent best-five comparison. Its copied B2 result comes from
  the existing PairLesson record.

- `schema10-course-review-correction.json` is a schema 10 encoder export. It
  extends the schema 9 draft with a cumulative review after five answers and
  one revealed exact correction. Both paused lesson states and the existing
  scheduled one-pair follow-up are preserved.
- `schema11-table-course-drafts.json` is a schema 11 encoder export. It keeps the
  schema 10 review correction and adds one unsubmitted first-question selection
  in each of the turns, chips and starting-hands units.
- `schema12-expanded-course.json` is an encoder export. It adds an unsubmitted
  Capstone choice and a revealed elective answer to the schema 11 table-course
  drafts and retains the existing frozen review correction.
- `schema13-elective-drafts.json` is an encoder export. It preserves the schema
  12 contents and adds a staged EV choice and a revealed board-pattern answer.
