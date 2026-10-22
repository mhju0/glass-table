# Comprehensive code and performance review

- **Date:** 2026-10-22 · **Kind:** audit
- **Asked by / for:** owner authorized review, checking findings, implementing all
  recommended strong/medium fixes, verification, main merge and safe branch cleanup.
- **Originals:** `/tmp/gt-comprehensive-performance-review.md`, performance provenance,
  native `gt-comprehensive-native-*` logs/xcresults, `gt-contrast-repair-evidence.md`.
  Temporary local artifacts are not guaranteed to survive cleanup.

All five accepted findings are P2 / medium impact, with high confidence from the
recorded reproductions or measurements. No confirmed P0/P1 defect was found.

## Standards

- Reviewed recent changes from build-35 `d910f99` through `f34f537`, plus current
  package/app/tool paths. Checked documented standards independently of spec review.
- P2: Equity Sense violated D40 by generating one identical spot for multiple body
  reads. Bind it once per render; no cache, new state, changed seeds or grades.
  Matched 300-case Release harness: Apply p50 3.355→1.197ms, Sharp 3.462→1.162ms;
  checksums match. These are host CPU timings, not device frame-rate measurements.
- No other confirmed strong/medium standards defect in the inspected sources.

## Spec

- Independent review traced grading/help, completion/mastery, saved-answer regrading,
  migration backups, atomic replacement, stale session rejection and replay guards.
- P2: stale reminder work could re-add after OFF or override newer time/language.
  Delayed-client reproduction confirmed it. App-lifetime latest-intent reconciliation
  now serializes adds, rejects stale UI completions and cleans up stale additions.
  Existing keys stay unchanged; same-identifier ON requests replace without removal.
  Twelve tests / thirteen cases passed. Actual OS removal completion is asynchronous;
  fake-client ordering is not end-to-end notification-service verification.
- No other confirmed spec violation or scope creep in the reviewed production changes.

## Additional findings and decisions

- P2: native glass shadow painted over the summary heading. Containing the effect
  within its existing 10pt control shape removes that overdraw without a palette,
  layout or audit waiver. Pinned KO/light/normal strict audit reproduces red without
  the fix and passes with it. Normal/AX5/light/dark navigation and actual Reduce
  Transparency/increased-contrast controls passed; outer 44pt targets stay intact.
- P2: compact AX5 reminder time label wrapped one character per line. Give its label
  a full row above the native picker at accessibility sizes; retain normal layout,
  existing binding/identifier and localized spoken name. Final `57b1ec0` passed six
  focused native tests; KO/EN normal/AX5 images and single localized accessibility labels checked.
- P2: hosted observer capture failed despite passing process tests. Host command
  changes during exec invalidated identity; global inventory/deadlines discarded
  capture. PID/start identity and independent host capture corrected those paths;
  46 tool tests pass. First provider probe retained no stacks. Probe `39651388113`
  passed the four unchanged launch tests and retained real host/runner stacks from
  the copy removing only documented `-mayDie` symbol preloading. Earlier rounds
  still timed out; successful capture delays were 25.421/37.887s, with no app stack.
  Production now matches that exact verified copy; all 46 tool tests pass. Temporary
  provider workflow retired. This is coverage evidence, not a launch-stall remedy.
- Measured limits, no risky rewrite: authentic capped 20-game/200-hand archives cost
  about 40ms per host model save; 500-day history about 50ms p95. Dropping sorted
  JSON keys saved only 2.22ms, so serialization/persistence remain unchanged.

## Verification and outcome

- Release packages: Drills 671 and Engine 96 tests passed. Combined native candidate
  `70e92d1`: 177 app tests plus three focused UI tests passed; three temporary normal
  Settings and Apply/Sharp Equity probes passed. Release smoke 2/2 passed without
  demo hooks; responsive launch mean 1.604s over three simulator iterations.
- Independent source review accepted the app fixes; later AX layout source review
  accepted `66b507f`; its duplicate-label follow-up is exercised at `57b1ec0`.
- Independent final review accepted runtime `06e364e`. Standard CI `39653967706`
  passed; full UI `39653967431` covers all four shards of that exact runtime.
  Initial full UI had two failures; controlled verification and preserved evidence:
  `2026-10-23-comprehensive-ci-closeout.md`. Final checks/merge: [PR #64](https://github.com/mhju0/glass-table/pull/64).
  Later record updates change documentation only; use Actions for terminal results.

## Still open

- Original nightly launch cause remains unattributed; capture activity is not a cure.
- Physical-device/minimum-iOS coverage, broader audit observations and real novice
  comprehension remain separate limits. Nonfatal compiler warnings are retained
  in raw native evidence; no Swift language-mode migration was attempted.
