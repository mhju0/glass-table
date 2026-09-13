# Glass Table: research foundation for the revival

Research date: 2026-09-13. Baseline: `5c181d0`. This document records the research and proposed design that preceded implementation. Warm and autonomous implementation were approved on 2026-09-14. The user will test the revamp before Store submission; implementation evidence belongs in the delivery report.

## Product judgment

Build a Korean-first, offline poker learning app around a repeated learning cycle: understand one idea, try it with support, retrieve it independently, receive an explanation, revisit it after a delay, then apply it among other decisions. Retain the deterministic engine, transparent chart/policy assumptions, and all 18 existing concepts. Teach increasingly serious study habits without claiming that course completion establishes professional competence.

The current product already includes worked examples, independent questions, mixed checkpoints, FSRS, and interval scoring. The revamp should make these mechanisms coherent and useful rather than adding a second learning system beside them.

## Learning evidence and implementation implications

| Evidence | Finding and limitation | Proposed application |
|---|---|---|
| [Roediger & Karpicke, 2006](https://pubmed.ncbi.nlm.nih.gov/16507066/) | Testing improves delayed retention relative to repeated study in prose-learning experiments. This is not a poker trial. | Require an answer before revealing the solution; keep worked-example exposures distinct from assessed attempts. |
| [Cepeda et al., 2006](https://doi.org/10.1037/0033-2909.132.3.354) | Distributed practice supports retention; useful spacing depends on the retention interval. | Make due reviews the recommended short session. Keep FSRS, but describe its scheduling as a product mechanism, not validated poker pedagogy. |
| [IES practice guide](https://ies.ed.gov/ncee/WWC/Docs/PracticeGuide/20072004.pdf) | Recommends spaced learning, quizzes, integration of graphics and verbal explanations, and alternating worked examples with problems. | Put the relevant cards/price/range beside the explanation. Introduce jargon at the moment it is needed. |
| [Kornell & Bjork, 2008](https://pubmed.ncbi.nlm.nih.gov/18578849/) | Interleaved examples improved category induction despite learner preference for blocked practice. | Start with focused practice, then mix related skills so the learner identifies the applicable rule. |
| [Rohrer et al., interleaved mathematics practice](https://pubmed.ncbi.nlm.nih.gov/24578089/) | Supports delayed strategy-selection benefits in mathematics; transfer to poker remains an inference. | Balance and seed-shuffle checkpoints rather than cycling in a predictable concept order. |
| [Renkl, Atkinson & Große, 2004](https://doi.org/10.1023/B:TRUC.0000021815.74806.F6) | Fading solution steps supports transition from examples to independent problem solving. | Replace answer-bearing hints with a method cue and a missing step. Use a different seeded spot for independent assessment. |
| [Hattie & Timperley, 2007](https://doi.org/10.3102/003465430298487) | Feedback should clarify the goal, present performance, and next action; effects depend on feedback type. | Explain the mistake and suggest a concrete retry or concept review. Avoid generic praise and unsupported mastery claims. |
| [Calibration feedback study](https://pubmed.ncbi.nlm.nih.gov/37329493/) | Feedback improved confidence–accuracy calibration in medical education; domain and experience limit generalization. | Show sample size and descriptive interval coverage; avoid diagnosing confidence from one response. |
| [Gneiting & Raftery, 2007](https://doi.org/10.1198/016214506000001437) | Proper scoring rules support honest probabilistic reporting under their mathematical assumptions. | Preserve interval scoring, distinguish it from point accuracy, and do not treat the scoring rule itself as evidence of learning efficacy. |

Five repetitions, six-question checkpoints, a 70% familiarity threshold, and a 12-hour cooldown are existing product heuristics. None of these exact values is established by the cited research as a poker mastery standard. Completing questions, performing accurately, and retaining skills after a delay must remain separate claims.

## Poker study progression

The following is a curriculum synthesis, not a scientifically established universal path to becoming a professional.

1. **Read the game.** Hand rankings, showdown, pot accounting, action order and position. Use the existing showdown, potMath and position drills with a concise beginner orientation.
2. **Explain a price.** Pot odds, clean outs, approximate equity, and call EV. Connect the price to the decision instead of teaching formulas in isolation.
3. **Think in ranges.** Combos/blockers, notation, position-aware opening and response to an open. Keep the declared training chart visibly distinct from an optimal strategy.
4. **Read the board and action.** Hit frequency, range advantage, range reads and action reads. Ask what changed in the range and why.
5. **Choose and review.** EV loss, call/fold, MDF assumptions, and a hand against a declared opponent. Compare decision quality with realized result.
6. **Develop serious study habits.** Predict an adjustment, inspect assumptions, review a counterexample, and revisit the error later. Explain what richer study must add: stack/rake/sizing sensitivity, multi-street play, population evidence and variance.

First-party poker sources:

- [PokerStars: starting hands](https://www.pokerstars.com/poker/learn/lesson/poker-starting-hands/) and [opening the pot](https://www.pokerstars.com/poker/learn/lesson/opening-the-pot/) support introducing position and opening ranges early, with reasons beyond chart memorization.
- [PokerStars: thinking in ranges](https://www.pokerstars.com/poker/learn/strategies/thinking-in-ranges/) supports reasoning over possible holdings instead of assigning a single hand.
- [GTO Wizard: how solvers work](https://blog.gtowizard.com/how-solvers-work/) explains why game-tree and input assumptions determine the answer.
- [GTO Wizard: subsets and abstractions](https://blog.gtowizard.com/poker-subsets-and-abstractions/) explains restricted subgames and the limitations of treating an abstracted solution as the full game.
- [GTO Wizard: study analyzed hands](https://help.gtowizard.com/tips-and-tricks-to-study-analyzed-hands/) motivates controlled comparisons and recurring patterns rather than memorizing individual outputs.
- [GTO Wizard: professional exploit study](https://blog.gtowizard.com/how_pros_use_solvers_to_crush_pool_leaks/) motivates explicit hypotheses, sensitivity checks, and separating assumptions from evidence.
- [PokerStars: bad beats and variance](https://www.pokerstars.com/poker/learn/lesson/bad-beats-and-variance/) motivates separating a good decision from a favorable outcome.

These providers publish practitioner guidance and sell or operate poker-related services. Their curricula are useful first-party references, not independent efficacy trials. Do not copy their proprietary charts or assets.

## Changes motivated by the baseline source

- `TodayView`: replace competing next-step, review, calibration and stuck-concept panels with one recommended learning action; move detailed measurements to records.
- `PathView`: make units legible as capabilities; disclose lesson detail on demand rather than presenting the entire dense rail at once. Preserve stable node identifiers and existing progress.
- `NodeSessionView`: preserve show/together/solo separation; use hints that do not expose the answer; make summaries accurately describe the session and its next step.
- `RootView` review flow: replace a concept picker and unlimited repetition with a bounded, automatically sequenced due review session.
- `Calibration` presentation: show observation count, avoid categorical judgments from tiny samples, and avoid pooling unlike score units without explanation.
- `TableView`: use one decision at a time, progressive disclosure of the declared model, and a hand review that prioritizes the reasoning behind the most costly decision.
- Shared UI: larger readable type, consistent spacing/radii, pinned primary actions, native press feedback, visible alternatives to slider-only input, and reduced-motion support.

## Implementation and verification constraints

Use the isolated `codex/research-led-revamp` worktree. Keep the pure Swift package boundary and deterministic seeds. Never highlight the correct action before commitment. Preserve local progress, imports, exports and recovery bytes. Any persistence or important progression-integrity changes require Astra planning and an independent review of the frozen candidate, with old-record compatibility and failure-path tests.

Verify the pure Swift behavior, release engine tests, simulator build and app tests. Inspect actual rendered screens at ordinary and accessibility text sizes. Exercise learning, review, table and recovery flows; screenshot launch hooks prove rendering only, not interactive behavior. Record all remaining gaps before handing over for user testing.

## App Store preparation

Apple's [age-rating questionnaire](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating) explicitly includes simulated gambling. The practice table means an educational purpose alone cannot determine the answers. Reassess the final build's questionnaire and [regional definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions), including Korea, before submission. Do not reuse historical age-rating claims.

Follow current [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) and prepare accurate screenshots, model descriptions, privacy/support links, version/build values and signing configuration. Submission is a later delivery stage after the user's requested testing; this research does not claim App Review approval or distribution readiness.

Apple's [buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [motion](https://developer.apple.com/design/human-interface-guidelines/motion), and [accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) guidance supports native interaction states, coherent feedback, Dynamic Type, reduced motion and visible alternatives to gestures. The user's Toss/Apple prompt remains the design brief, subject to its requested temperature checkpoint.
