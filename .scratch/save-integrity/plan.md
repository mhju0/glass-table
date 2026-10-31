# Save-integrity plan (archive, format, session ending)

Status: in progress · Written 2026-10-31 · Owner approved steps 1, 2 and 4 (2026-10-31).

## What already holds (read 2026-10-31)

- One file, `progression.json`, written with `Data.write(options: .atomic)` (temp file +
  rename) in `ProgressionStore.write`.
- Every commit saves before the shown state changes: `ProgressionModel.commit` keeps the
  candidate as `pendingState` on failure, blocks further commits and offers `retrySave`.
- Replace/import/reset copy the old bytes to `progression.recovery-<UUID>.json` first
  (`ProgressionStore.replace`).
- Schema upgrades copy the old file to `progression.schema-<N>-<UUID>.json` first; a
  failed copy aborts the upgrade (ADR 0001).
- Inner format versions are validated per snapshot (ADR 0001 table).
- Lesson drafts are flushed when the scene leaves `.active` (`NodeSessionView`
  `onChange(of: scenePhase)`).
- Bounded logs: answers 500, `recentEvidence` 500, `recentHands` 200, finished quick-play
  sessions 20.

## Gaps found

1. **No golden fixture for schema 5.** Builds 35–37 shipped schema 5 to TestFlight
   (`096973c`, tags `v1.0-35`…`v1.0-37`), but `Fixtures/Progression/` stops at
   `schema4-build35.json`. ADR 0001 requires one per shipped shape.
2. **`dailySummaries` has no cap.** One entry per local date × concept × mode × step × format.
   Small per day, but it grows forever, and every save re-encodes the whole file.
   `recordDetailedAttempt` also finds the entry with a linear `firstIndex` scan.
3. **Backup and recovery copies are never cleaned up** (by design in ADR 0001). They are
   not visible in Settings, so a user cannot tell they exist or restore one without
   the Files app.
4. **Save latency with a full history has never been measured** (old open item):
   saves are synchronous on the main actor.
5. **Session ending outside lessons** (practice round, review, free table) was not
   checked here for the same scene-phase flush the lesson view has.

## Proposed steps (each its own PR, in order)

1. Add `schema5-build37.json`, generated from `v1.0-37` the way the fixture README
   describes. Test only; no app change.
2. Write a test that fills a state to every cap plus a year of daily summaries, then
   time `exportData` + `save`. Decide on step 3 from the number.
3. Only if step 2 is slow: cap or roll up old `dailySummaries`. That changes what a key
   means, so it bumps the schema, copies the old file and adds a fixture (ADR 0001).
4. Audit scene-phase handling in the round, review and free-table views; add the same
   flush where a typed draft can be lost, with a UI test that backgrounds mid-draft.
5. Copy cleanup: leave as is unless the owner wants a "saved copies" row in Settings
   (that is a UI change, so mockups first).

## Results (2026-10-31)

- Step 1: `schema5-build37.json` added (PR #74). The golden test now regrades saved
  answers at their stored step, as `ProgressionStore` does on load.
- Step 2: `SaveLatencyMeasurementTests` (run with `GT_MEASURE_SAVE=1 swift test -c
  release --package-path GlassTableDrills --filter SaveLatencyMeasurementTests`).
  M1 Pro, release build, median of five:

  | History | File | Save | Load |
  |---|---|---|---|
  | 1 heavy year: 10 summaries, 40 answers a day | 1.5 MB | 31 ms | 36 ms |
  | 3 years: 20 summaries, 60 answers a day | 7.9 MB | 172 ms | 199 ms |
  | 5 extreme years: 30 summaries, 100 answers a day | 20.5 MB | 468 ms | 529 ms |

  `processedAttemptIDs` is also uncapped: one ID per graded answer, forever. A year of
  heavy use saves fast, so step 3 is not needed now. Phones are slower than this Mac;
  revisit when a real file passes about 5 MB.
- Step 4: no gap. Round (`FreePlayView`), review and lesson views flush their debounced
  draft whenever the scene leaves `.active`. The free table and graded table save each
  action synchronously; the free-table replay task is visual only.

## Owner questions

- Step 5: keep copies hidden forever, or show them in Settings?
