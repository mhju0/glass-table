# Independent review of Claude updates, builds 24–35

- **Date:** 2026-10-18 · **Kind:** audit
- **Asked by / for:** owner; independent review of recent work and product-owner decisions
- **Candidate:** `ed54c2f2e61aecf3c5aafb35fbbd98600c2b73b1`; build 35 tag/code `d910f99`
- **Baseline:** build-24 record `b260062`; reviewed subsequent product changes and release evidence
- **Originals:** package logs `/tmp/gt-review-drills.log`, `/tmp/gt-review-engine.log`; local captures `.uisweep/20261018-234113-EasLmG/`; transient local evidence, not a durable archive

## What it was

Read-only product-code review, with independent standards/persistence, spec/domain,
and release-evidence reviewers. Focus: pass rules, guided hand, refactors, exact flop,
language switching, best-five/outs feedback, Learn list, steps, Play and Progress.
This is a broad risk-based review, not proof that every changed line or route is correct.
No product fixes, device installs, release changes or external service writes.

## Standards findings

- **R01 / P2, source-confirmed:** graded-table decisions after a save failure are lost
  from recovery. `TableView.swift:798` ignores `recordTableDecision`'s Bool and continues
  the local hand. `ProgressionModel.swift:959` refuses later commits while `saveError`
  exists, retaining only the first pending state. Retry/export cannot recover later
  choices. Block further decisions until recovery or retain a recoverable queue.
  Not reproduced through a failing disk on a running app.
- **R02 / accessibility:** `ProgressSummaryView.swift:91` applies
  `minimumScaleFactor(0.6)` to scalable count text, violating AGENTS/D54. Large counts
  can shrink on narrow layouts. Accommodate the text instead; actual large-count
  truncation/shrink was not separately reproduced.
- **Maintainability heuristic:** test-only `completeNode` duplicates production
  completion/promotion, with different difficulty lookup. Prefer tests through actual
  session commands. No additional user-visible bug established from this helper.

## Spec and teaching findings

- **R03 / P2, generated reproduction:** Sharp pot math starts flop betting before
  earlier callers respond to the BB's 3-bet (`PotMath.swift:261–266`). Seed 7/index 3:
  blinds 1/2, A raises to 5, SB adds 4, BB raises to 15, A adds 10, BB bets 12,
  A calls 12. No one folds, but SB still has only 5 invested against 15. The displayed
  total 59 sums the listed actions but the street transition is invalid. Resolve all
  callers and visibly distinguish streets. Existing tests check added actions, not
  legal street closure.
- **R04 / P2, source and numerical probe:** Sharp Action Read hides both archetype
  and prior range (`ConceptDrillView.swift:2928–2956`) while grading the latent
  archetype's exact model. CO opens then checks on A♠7♥2♣: Nit 63.0%, TAG 35.7%,
  Station 61.0% pair-or-better. Same visible premise, incompatible answers under
  ±5-point correctness. Independently confirmed as underdetermined, even though
  unknown-opponent direction was approved. Disclose assumptions or grade a disclosed
  mixture/uncertainty task; an interval control alone does not fix point grading.
- **Documentation drift:** D53 describes only three stepped skills; code supports
  14 active track skills. Handoff's “every skill but MDF” also overstates coverage:
  hit frequency, range advantage and EV loss stay Learn-only. CI/CD docs still say
  the release workflow has never run end to end, contradicted by actual uploads.

## Verification and release evidence

- Fresh Drills: 561 XCTest + 103 Swift Testing tests, zero failures.
- Fresh Engine release: 96 tests, zero failures. Fresh simulator Debug build passed.
- Inspected 16 initial frames on disposable iPhone 12 mini/iOS 26.5: Learn, Play,
  Progress and five Sharp drills, normal and AX5, Korean/dark. The first normal Learn
  frame has a system notification over its header. These captures do not verify full
  scrolling, answer submission, English/light, all step routes or physical use.
- Build-35 CI passed: https://github.com/mhju0/glass-table/actions/runs/39126165684
- Build-35 archive/distributable/upload passed: https://github.com/mhju0/glass-table/actions/runs/39126186102
- Full UI run failed: https://github.com/mhju0/glass-table/actions/runs/39126165724
  `GradedLearningFlowTests.swift:151` could not find `table-continue` within 10s after
  a passive AX postflop action. Its shard had one failure and 11 skips. Prior runs
  did not show this failure; intermittent UI regression versus runner issue unresolved.
- Upload success does not establish Apple processing, tester availability, phone
  install or phone behavior. No new physical-device, VoiceOver or iOS-17 check.

## Owner assessment and next step

Strong decisions: concrete phone feedback, real-hand explanations, explicit pass
rules, automatic difficulty, simpler lesson discovery, preserved progress, and
separating TestFlight from store submission. Engineering strengths include golden
Learn fixtures, schema backups and frozen step-aware restore/regrading.

Weak decisions: broadening build 35 while cutting visual verification; treating
hidden premises as difficulty; continuing substantial polish/curriculum expansion
without observed novice comprehension. These are shared owner/agent process gaps;
Claude should challenge invalid teaching assumptions and supply evidence per claim.

Recommended next work: fix R01/R03/R04 and R02, reconcile documentation, investigate
the UI failure, then freeze one candidate for upgraded/fresh-state phone checks and
novice observation before another feature expansion. Findings remain open; no fixes
were authorized or made as part of this review.
