# Nightly launch failure investigation

- **Date:** 2026-10-21 · **Kind:** audit
- **Asked by / for:** owner requested investigation of the subsequent nightly failures.
- **Originals:** run `39497368168` on released `be1c839`; shard-3 artifact retained
  under `/tmp/gt-nightly-39497368168`, local reproduction under `/tmp/gt-nightly-local-*`.
  Temporary local artifacts are not tracked or guaranteed to survive cleanup.

## Findings and decisions

- Shard 3 used Xcode 26.3 (17C529), macOS 15.7.9, iPhone 17 / iOS 26.2 (23C54),
  with test parallelization disabled. Final result: 135 passed, 2 failed / 137 tests.
- Its first four methods were CountKeypad, DefendReveal, EquityAnswer and EVReveal
  in `AccessibilityFlowTests`, with no preceding test class. The first three had
  launch-failure events at the shared `app.launch()` helper, before product assertions.
  Count failed after 74.119s; Defend after 900.847s. Equity's first attempt failed
  after 61.582s, then passed in 21.002s following XCTest's automatic runner restart.
  Three failure events must not be described as three final failed tests.
- Original Xcode session log `Session-GlassTableUITests-2026-10-20_210715-oo1SNB.log`
  lines 3177–3197 maps PID 7239 to GlassTable, immediately sees it dead, and reports
  exit code 0 / no signal. Replacement PID 7247 launched and reached foreground;
  lines 3296–3304 and 3610–3620 show foreground/SwiftUI ViewDidAppear while XCTest
  still waited for launch progress. Signal 9 at the later timeout is consistent with
  timeout cleanup; it does not establish a preceding app crash.
- The 900s spindump is for the UI-test runner. No app stack sample or app crash report
  was captured in the exported diagnostics; first-PID app output is missing. These
  limits prevent attributing the initial exit or excluding an app-triggered problem.
  This is a stalled launch/progress transaction, not a demonstrated app main-thread hang.
- Local unchanged released-source reproduction: three original tests passed twice,
  54.340s and 46.110s (six test executions). No assertion, source, retry, timeout or
  launch-synchronization changes. Xcode 27.1 / iOS 26.5 differs from CI; local green
  cannot clear the CI-specific failure. Source/build manifest verifies 66 inspected
  files against `be1c839` and the actual installed Debug code image.
- Independent review selected the original four-test prefix for a matched CI probe,
  retaining EVReveal at the runner-recovery boundary. Probe `39618848422` at
  `2bcb4029dd1aec0185102dd36e7feeebb1c0e7fb` changes only a temporary workflow;
  its app/test/package/config diff guard against `be1c839` passed. It preserves
  Xcode 26.3, iOS 26.2, iPhone 17, build-and-test lifecycle and 900s allowance,
  with no added preboot, sleep or retry. Matched macOS 15.7.9 / Xcode 26.3 (17C529)
  / iOS 26.2 (23C54) probe passed all four in original order: 45.085s, 19.396s,
  18.918s and 23.740s; total 107.140s, zero failures. Logs/xcresult/provenance are
  retained at `/tmp/gt-nightly-launch-prefix-39618848422`. This is matched-config
  non-reproduction, not a fix or proof that the original failure was harmless.
- Leading explanation is a failed/stale launch-control session; the initial reported exit code 0 and stuck transaction remain unattributed. No speculative app-startup,
  persistence, palette, timeout or retry fix is justified by the current evidence.

- Independent read-only review verified the matched source/configuration and four
  single-attempt passes; accepted bounded non-reproduction with cause still unresolved.
- No app/test/package/config changes were made, and no new build or release was
  prepared. The owned local simulator was deleted; raw evidence/derived data retained.
  The temporary CI workflow is retired after the probe; it is not a product fix.

## Still open

- Original nightly remains failed. Initial process exit and launch-transaction cause
  remain unresolved; targeted green does not clear the whole nightly suite.
- The known material-sensitive summary contrast audit remains red and separate;
  see `2026-10-20-accessibility-audit-followup.md`.
- If launch failures recur, obtain the live app stack and correlate its launch/exit
  transaction before timeout cleanup; the original runner-only sample cannot do this.
