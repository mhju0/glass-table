# Comprehensive review: CI closeout and retained failures

- **Date:** 2026-10-23 · **Kind:** verification
- **Asked by / for:** owner resumed review, fixes, full checks, main merge and cleanup.
- **Originals:** `/tmp/gt-fullui-39653967431-*`, `/tmp/gt-reveal-regression-*`;
  run/attempt/job/artifact metadata retained in `attempt1-provenance`. Temporary
  local evidence is not guaranteed to survive cleanup. No phone data is included.

## Verified candidate

- Runtime `06e364e`, documentation-only head `f1d5a50`: independent review accepted;
  all non-documentation bytes match. Standard CI `39653967706` and `39662695264`
  passed tools, packages, app/focused UI, Release smoke and device bundle checks.
- Full UI `39653967431` first attempt: 381 executed, 11 optional UXAuditCrawl skips,
  two failures. Shards 1 and 3 passed 96 and 137 tests respectively. The former
  includes AccessibilityAuditTests; the latter includes AccessibilityFlowTests.
- Production observer source hash `4e5f649c…` matches the provider-tested copy.
  Shard 1 retained real host/runner call graphs in its second capture round, after
  delays of 28.280/43.487s; its first round timed out. No app stack was retained.

## Failures and judgment

- Shard 0: NumericalRevealFlowTests.testKoreanLightReveals line 53. After Next,
  the original answered callFold/1706/2 (1/5) remained. Down/up was inside the
  enabled completion button; no save-error UI appeared. This does not establish
  handler execution or a refused transition. No definite causal code fix emerged.
- The unchanged local case passed once plus five bounded repetitions on Xcode27.1 /
  iOS26.5; hosted failure used Xcode26.3 / iOS26.2. Quiet video and no helper swipe
  weaken the scroll-motion hypothesis. Green local execution does not cure the CI failure.
- Shard 2: ChartFirstUseFlowTests.testBeginnerLessonQuestionStartsWithChartFoldedSoItCanBeAnsweredAlone
  failed at app.launch() after 64.589s, before chart assertions. Later launches passed.
  The launch activity reached observer output late; no app identity/stack covers
  the failure window. Neither provider nor latent app startup cause is established.
- Independent review recommended no speculative app, sleep, timeout or retry-policy
  patch. Initial logs, both xcresults and bounded observer artifacts were retained.
  One controlled rerun of both complete failed shards preserves the same source,
  ordering, assertions and deadlines. A green attempt is verification, not a causal fix.

## Controlled rerun and guide readiness

- Attempt 2 passed shard 0, including the original reveal case. Shard 2's original
  chart launch passed, but LearningReferenceFlowTests' seven-topic EN/AX5 guide
  case failed at its unchanged one-point reading-position assertion: expected
  y548.333, observed y509.620 after closing a lookup. No second blind rerun.
- The old precondition checked only an underlying heading's existence; native
  controls confirmed that heading can exist while the lookup is still open.
  A matched Xcode26.3/iOS26.2 diagnostic run `39905176112` passed the unchanged
  original case and a separate geometry probe. All sampled positions were stable;
  it did not reproduce or explain the original 38.713-point shift.
- A UI-test-only candidate establishes child dismissal, interactive stable viewport
  geometry and temporal stability of an independent paragraph before retaining
  the same one-point term-position assertion. It never waits for the tested term
  to regain its expected position. Native negative controls rejected an open
  lookup and accepted a deliberately wrong settled offset, where the original
  strict assertion still failed by 269 points. Final positive/provider checks and
  exact integration remain pending in PR #64. No product scroll patch is justified.

## Outcome and next evidence

- Exact attempt outcomes and integration are recorded in
  [run 39653967431](https://github.com/mhju0/glass-table/actions/runs/39653967431) and
  [PR #64](https://github.com/mhju0/glass-table/pull/64). App/package/configuration/tool bytes remain frozen; the guide
  readiness candidate changes UI-test preconditions only. The five confirmed P2 fixes are described in
  `2026-10-22-comprehensive-code-performance-review.md`.
- If the reveal failure repeats, capture passive completion-handler entry, captured
  versus current identity/phase, transition refusal/save outcome and rendered identity;
  preserve guards and omit learner data. Repeated launch failure needs its actual
  launch/exit transaction and app stack. Do not automatically rerun again.
- All three isolated failure causes, wider accessibility/device/minimum-OS and novice
  acceptance remain open. No build bump, TestFlight upload or phone action.
