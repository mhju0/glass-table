# Cleanup audit — 2026-09-05

Scope: current source/tests, Git history (including the replaced M1 implementation),
project generation, CI, local storage, simulator tooling, and GitHub PRs/issues.
Baseline: `61f0b51`, the head of takeover PR #3. No Claude configuration was migrated.

## Changes and evidence

- **Correctness:** award streak credit before FSRS removes a reviewed concept from the
  due queue; ask every boss concept before promotion; restrict table dealing to seats
  where hero acts after the opener on every street. New regressions failed on the old
  behavior (including 65 invalid deals across 160 seeded hands). D44 records the
  progression contract; no stored schema changed.
- **Stable questions:** freeze the node seed at session entry. Clear range-advantage
  equity when advancing and ignore cancelled computations, preventing a new question
  from being graded with the previous question's result.
- **Deletion:** remove the unused M1 generic session, grading protocol, per-drill
  writer, binary-grade wrapper, unconsumed daily-set APIs, and tests of those dead
  paths. Keep the five-file legacy decoder and migration behavior, tested with real
  JSON rather than the deleted writer. Remove the views' answer-history arrays and
  separate end-session saves. Free play now saves once per answer instead of twice.
- **Performance:** score each hand class once before sorting a shaped range; reuse
  Chen's existing ranking for plain ranges. Calculate table policy buckets once per
  pricing pass and materialize the visible board once per equity pass.
- **Verification tooling:** the screenshot sweep generates/builds this checkout,
  retains logs, propagates failures, rejects stale `--no-build` artifacts, and creates
  and deletes its own simulator. Each capture starts with a fresh app container.
  Individual screens are selectable. Startup waits are bounded with one restart on
  failure. Six failure-path tests cover boot/build/launch/capture failures, cleanup,
  artifact isolation, stale reuse and invalid screen names.
- **CI:** run the release engine gate on engine PRs, not only after merge; test the
  screenshot tool; let app tests perform the Debug build instead of building twice;
  print the complete Xcode log on failure.

## Performance measurements

Local arm64 Mac, Xcode 26.6 / Swift 6.3.3, release binaries, median of five warmed
batches. Before and after binaries ran consecutively; timings are observations,
not portable thresholds or end-to-end UI latency claims.

| Operation | Before, µs/op | After, µs/op |
| --- | ---: | ---: |
| Plain range | 109.68 | 4.68 |
| Shaped range (suited + connectors) | 152.10 | 12.32 |
| River option pricing across seeded archetypes | 540.53 | 376.01 |

All 1,616 combinations of tendency sets and integer widths produced identical
range snapshots; all sampled river EV lists matched byte-for-byte. No Monte Carlo
sample count, seed formula or grading threshold was reduced for speed.

```sh
swift run -c release --package-path GlassTableDrills DrillBenchmarks
swift run -c release --package-path GlassTableDrills DrillBenchmarks --snapshot
python3 -m unittest discover -s tools/tests
tools/uisweep.sh --list
tools/uisweep.sh --screen drill-rangeadv --screen drill-rangeadv-reveal
```

## Verification

- 311 drill tests, 91 release engine tests (including exhaustive enumeration and the
  frozen independent oracle), 12 iOS app tests, and six screenshot-tool tests pass.
- XcodeGen generation and unsigned Debug/Release simulator builds succeed.
- Native simulator interaction confirmed unit 2 starts at `1/7` and consecutive
  range-advantage questions reveal their own answers (59.1%, then 73%).
- The same 12 model tests also pass in an ephemeral macOS harness. That run exposed
  and fixed a test's assumption that equivalent temporary-file URLs compare equal
  across `/var` and `/private/var`. No second persistent test configuration was added.
- A first-boot simulator launch stalled before the app process started; rebooting
  only the disposable test device resolved it. Failed sweep logs remain available,
  and the script correctly rejects reuse after a source edit.

## Review disposition and remaining work

- **PR #3:** implementation inspected; mergeable with passing CI at audit time. It
  contains persistence safety and takeover documentation. The owner reserved its
  merge. This cleanup is a separate branch based on it.
- **Issues / stuck branches:** no open issues, other open PRs, or abandoned remote
  implementation branches were present. MDF is a deliberately parked product slice,
  not an almost-finished implementation to rescue.
- **Next:** merge verified fixes and dogfood on the owner's phone. Assess bot usefulness
  and EV-loss thresholds from actual play before adding MDF's full defense-selection
  slice. The release build and simulator cannot establish those product answers.
- **Deliberately retained:** the exhaustive evaluator gate and independent eval7
  oracle; seeded generator/property tests; recovery bytes and legacy migration;
  current offline architecture; shared SwiftUI drill layouts. Their value is concrete.
  No new dependencies, configuration framework, global instructions or services.
- **Avoided:** store submission, age-rating/legal judgments, production deployment,
  schema changes, and changes to poker policy or sampling accuracy. These need evidence
  beyond a cleanup audit. Remaining range-equity work is CPU-bound; profile on a real
  device before adding a cache or rewriting the evaluator.
- **Historical drift:** the dated handoff's three remaining-defect entries and R1's
  fixed six-question/session-completion wording are superseded by source/tests, D44
  and ROADMAP. The high-level architecture did not change, so the handoff was not
  expanded with routine implementation details.
