# Save-integrity plan (archive, format, session ending)

Status: needs-triage · Written 2026-10-31 · Plan only: no code until the owner approves.

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

## Owner questions

- Approve steps 1, 2 and 4 now (test-only or a small flush)?
- Step 5: keep copies hidden forever, or show them in Settings?
