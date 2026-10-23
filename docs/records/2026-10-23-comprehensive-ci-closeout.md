# Comprehensive review: CI closeout and retained failures

- **Date:** 2026-10-23 · **Kind:** verification
- **Scope:** owner-authorized review, recommended fixes, checks, main merge and cleanup.
- **Evidence:** `/tmp/gt-fullui-*`, `/tmp/gt-guide-*`; temporary originals may not persist.
  [PR #64](https://github.com/mhju0/glass-table/pull/64) records current checks/integration.

## Accepted implementation

- Five P2 fixes and measured limits: `2026-10-22-comprehensive-code-performance-review.md`.
  App/package/configuration and production tool bytes remain accepted `06e364e`;
  subsequent implementation changes only guide UI-test readiness and observer fixtures.
- Observer source SHA `4e5f649c…` is provider-tested. Real host/runner stacks were
  retained, with earlier timeouts and capture delays; no app stack covers the failures.
  Original nightly launch cause remains unattributed; diagnostics are not a causal cure.
- Observer fixture correction separates readiness from its deliberately short timeout.
  Controlled 350ms deadline races reproduce exit 1 instead of intended 41; production
  faithfully preserves 1. Lifecycle fixtures now use the production completion budget;
  dedicated 350ms timeout starts after atomic PID readiness. Interruption, exit codes,
  output caps and descendant cleanup remain required. All 46 tools pass. The actual
  hosted child trace was discarded, so unique attribution is unproven.

## Original full UI evidence

- Run `39653967431`, attempt 1: 381 entries, 11 optional UXAuditCrawl skips, two failures.
  Reveal Next left answered callFold/1706/2 unchanged despite an accurate enabled-button
  tap; no save-error UI. Six unchanged local passes do not establish the CI cause.
- ChartFirstUse's first launch timed out after 64.589s before chart assertions. A later
  pending launch crossed the test boundary; no app stack establishes the initial cause.
- One independent-review-approved unchanged failed-shard rerun passed both original
  cases but exposed guide lookup position y509.620 versus expected548.333 (1pt tolerance).
  A matched unchanged diagnostic run `39905176112` did not reproduce that drift.
  No speculative app patch, automatic retry, assertion waiver or launch-policy change.

## Guide readiness correction and verification

- First readiness test file `754dec69…` passed standard CI `39912831403` on `088d51c`,
  including the complete LearningReferenceFlowTests class on Xcode26.3/iOS26.2.
  Identical non-documentation source `c9c317c` full run `39910661098` failed before
  baseline capture: only one full geometry observation fit; the next Close hit test
  returned false. Later hierarchy geometry matched. This is run-context divergence,
  not proof of an app movement, simulator defect or original offset cause.
- Final test SHA `941d9e94c3f485f52db0e9ddbb6bfdb2eef4ca5847b58a1640f36548d0a41061`
  reads one coherent accessibility tree per observation. It keeps two observations,
  0.25pt stability, 1pt viewport restoration, all three live hit tests and configured
  5s wait. Readiness excludes the tested term; its original 1pt position assertion,
  seven topics, identity and navigation remain. Framework query time is also recorded.
- Final native controls reject an open lookup despite the underlying heading existing;
  a wrong settled offset passes readiness then fails the original assertion by268.667pt.
  Six positives passed: 28 cycles across KO/EN normal/AX5, with D55 independent scoring
  and glossary aliases preserved. All 56 readiness gates passed in2.320–2.449s.
- Matched focused run `39923661521`, frozen probe `84f09db`, passed the original case
  in439.969s on Xcode26.3/17C529, iPhone17/iOS26.2/23C54. All14 readiness gates passed
  in2.439–2.712s; 28 snapshots took0.079–0.185s; all42 hit tests were true.
  These results verify the candidate, not a unique cause for prior failures.

## Full coverage and integration boundaries

- Original run `39910661098` remains failed: shard0 passed36 entries/11 optional skips,
  shard1 passed96 (includes AccessibilityAuditTests), shard3 passed137; shard2 had
  112 entries/one readiness failure. Earlier superseded `39908564802` stopped before
  UI in an observer fixture; its other three shards and superseded standard were canceled.
- Exact-source full affected-shard run `39925402380` uses frozen probe `84f09db`,
  production's 13 ordered shard-two selectors, 900s case allowance, 165min step/180min
  job, and unchanged observer/unit gate. Its result and latest standard CI are in PR#64.
- Independent review accepts reusing successful shards0/1/3: all executed/shared app,
  tests, packages, configuration and production workflow/tool bytes are unchanged.
  The sole code delta from `088d51c` is private LearningReferenceFlowTests readiness.
  All four production selector lists are byte-identical; proof:
  `/tmp/gt-final-ui-shard-source-proof.json`. This is combined coverage across runs,
  not a claim that the original failed workflow became green. No temporary workflow
  or diagnostic test enters main. Exact merge and post-merge checks are recorded in PR#64.
- All three isolated app/UI causes remain open. On recurrence capture actual launch/
  exit transaction and app stack, or before/after settled geometry and sheet lifecycle;
  reveal recurrence needs handler/identity/phase/refusal/save/render correlation.
  Preserve guards and privacy; no blind reruns. Wider accessibility, minimum-iOS17,
  physical-device and novice acceptance limits remain. No build bump or TestFlight release.
