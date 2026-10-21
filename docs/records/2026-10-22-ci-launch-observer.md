# Nightly launch diagnostic coverage

- **Date:** 2026-10-22 · **Kind:** verification
- **Asked by / for:** owner requested a fix after the nightly launch investigation.
- **Originals:** original run `39497368168`, local retained diagnostics under
  `/tmp/gt-nightly-39497368168`; implementation verification listed below.

## Findings and decisions

- The original runner requested launch at 21:10:28.333; host xcodebuild recorded
  receipt at 21:11:35.457, about 67 seconds later and after the runner's 60-second
  request timeout. Test-start notifications were also delayed. Source timestamps
  and asynchronous log arrival must remain separate.
- This narrows the missing evidence to host/runner launch control before app startup.
  It does not attribute the initial reported exit code 0 or exclude app involvement.
  Earlier unchanged local tests and matched CI prefix `39618848422` did not reproduce.
- No matching Apple-confirmed remedy emerged from the bounded release-note/forum
  search. Fresh-simulator, preboot, retry, timeout and app-startup patches would be
  speculative and were rejected after independent review.
- Repair the diagnostic gap: original xcodebuild output goes directly to its raw
  log; an observer captures bounded host, selected-simulator runner and app samples.
  Pending launch and runner-silence triggers are sampling heuristics, not failures.
- Preserve original assertions, simulator/runtime/toolchain selection, test order,
  timeout and exit status. Observer errors must not replace the test outcome.
  Only observer-created process groups are cleanup targets; observed simulator
  processes are never killed. No environment or app data-container snapshots.

## Outcome

- Implementation candidate `13779ff` is on `fix/ci-launch-observer-20261022`, stacked
  on documentation PR #62. All 37 tool tests passed (17 observer, 20 existing).
  Original argv, selection, runtime and allowance comparisons plus YAML/shell checks
  passed. Final log: `/tmp/gt-ci-observer-all-tool-tests-reviewed-fix.log`.
- A real macOS sample captured controlled host PID 87489; sampling completed in
  2.623s inside its 5s bound. Sampler returned 0; original command and wrapper both
  returned 23; exact source copy/hash and result are retained. Evidence: `/tmp/gt-ci-observer-reviewed-real-sample/diagnostics/`.
- Independent review found interrupted samples could bypass their size cap. Two
  causal tests reproduced the issue; shared finalization now caps both completion
  and interrupted cleanup. Both regressions and the complete tool gate passed.
- Independent read-only review accepted exact `13779ff` with no remaining blockers;
  final source hash matches the preserved real-sampling provenance.
- Diagnostic artifacts are retained on successful runs as well as failures; original
  failure logs/xcresult remain available. This is not a demonstrated launch-stall fix.
- No product source, local progress, phone installation, build number or TestFlight
  release change is included.

## Still open

- Original launch cause and initial process exit remain unresolved.
- Known material-sensitive summary contrast audit remains separate and visible.
- Initial authentic CI ran but retained no usable samples. The provider-tested repair
  and successful host/runner sampling probe are recorded in
  `2026-10-22-comprehensive-code-performance-review.md`. This does not clear the
  original nightly or establish its launch cause.
