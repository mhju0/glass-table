# Revival design audit

Baseline: `5c181d0`. Read-only source audit on 2026-09-13, before UI edits. Companion: [research foundation](2026-09-13-revamp-research.md).

## Temperature

| Signal | Score | Source evidence |
|---|---|---|
| Emotional stakes | Low | Offline study with no real-money wagering; `TableView` grades synthetic hands. |
| Data density | High | `TableView.swift:243` onward combines board, pot price, hero cards, range and action history. |
| Decision frequency | High | `ConceptDrillView.swift:272` and `TableView.swift:383` require repeated answer/action choices. |
| Domain familiarity | Low | `NodeSessionView.swift:69` introduces concepts through worked examples and guided practice; glossary is available in drills. |
| Professional context | Low | Personal skill learning, local records and review; no professional analysis workflow. |

Recommend **Warm**: friendly Korean 해요체 for explanations, direct and nonjudgmental correction, brief success acknowledgment. Preserve precision in probability and EV language. Warmth affects tone; motion remains restrained and functional. Proposed dials: energy 1, rhythm 2, motion 1. Felt and playing cards provide poker identity; neither a mascot nor casino spectacle is needed.

Temperature confirmation is pending. The user's design prompt explicitly requests this checkpoint. No interface changes have been applied.

## Violation inventory

Line references point to the baseline files under `GlassTable/Sources/`.

| Rule | Screen/file | Finding | Proposed fix |
|---|---|---|---|
| Structure 1 | `Screens/TodayView.swift:20` | Next lesson, due review, calibration and recovery compete on the daily starting screen. | **Top 1:** one recommendation; detailed records elsewhere. |
| Structure 2 | `Screens/TodayView.swift:107,142` | Main lesson CTA sits inside scrolling content, with a second prominent review action. | Pin one recommended action; one secondary choice. |
| Structure 2 | `Screens/NodeSessionView.swift:104` | Hint placement uses a fixed 250-point bottom offset independent of content and text size. | **Top 2:** unify lesson/answer layout and place help in a stable visible location. |
| Structure 3 | `Screens/ConceptDrillView.swift:194` | Point and interval-width sliders ask novices for two unfamiliar estimates together. | Introduce interval meaning with a worked example and use clear tap controls; do not remove mathematically necessary information merely to reduce input. |
| Structure 5 | `Screens/TodayView.swift:163` | Calibration appears before new learners have data or context. | Put measurement explanation and sample count in Records. |
| Structure 9 | `Screens/TableView.swift:364` | Pricing shows a spinner in place of actions. | Preserve action-region geometry while calculation is pending. |
| Behavior 1/2 | `DesignSystem/Components.swift:6` | Shared press feedback uses fixed ease timing. | **Top 3:** native spring press feedback with immediate highlight and reduced-motion alternative. |
| Behavior 1 | `Screens/WalkthroughView.swift:61`, `Screens/RootView.swift:148`, `Screens/ProgressFileFeedback.swift:15` | Several raw buttons bypass the shared style. Native buttons may still provide system feedback; verify rendered states. | Make custom button feedback consistent without overriding useful native behavior. |
| Behavior 2/5 | `Screens/WalkthroughView.swift:206` | Repeating highlight pulse and fixed-duration transitions. | Replace repeated pulse with stable emphasis; animate only a change of relationship. |
| Behavior 2 | `Screens/ConceptDrillView.swift:657,968` | Additional fixed ease animations. | Use shared motion presets and respect reduced motion. |
| Behavior 3 | `Screens/RootView.swift:66` | Sheet transitions have no explicit shared origin. | Use native navigation continuity; consider shared-origin transitions only where deployment support and simpler structure justify them. This is a brief mismatch, not evidence that native sheets are defective. |
| Behavior 6 | `DesignSystem/Components.swift:255,338`, Today/Path/Records | Repeated elevated bordered surfaces compete for hierarchy. | Flatten secondary sections; reserve depth for the active task and modal controls. The current surfaces are opaque colors, not actual stacked blur materials. |
| Behavior 7 | Components, ConceptDrillView, GlossaryView | Many one-off spacing, radius and type values. | Consolidate semantic type, spacing, radius and motion tokens. |

No custom hidden gesture handlers were found. Visible native sliders are not hidden gestures, but slider-only input conflicts with a literal reading of the brief's tap-first constraint; provide visible tap alternatives. Dynamic Type and Reduce Motion already have support. Actual large-type rendering still needs inspection; source support alone does not prove accessibility.

Poker answer choices are a deliberate exception to a literal single-primary-action reading: fold/call/raise must have equal visual weight until the learner chooses. A uniquely prominent correct answer would leak the solution. The single primary CTA applies to navigation and commitment, not to ranking possible answers.

## Learning issues discovered alongside the visual audit

- `ProgressionModel.completeNode` marks a node cleared after any finished session. This is completion, not demonstrated mastery.
- `NodeSessionView.summary` says a clean session means proficiency without deriving the actual resulting concept tier, and promises reviews in a few days without consulting the schedule.
- Guided hints drop the final worked-example beat but may still expose answer-bearing reasoning. Audit every concept's hint separately.
- `Calibration.verdict` classifies even one interval using a fixed tolerance; the comment that this protects small samples is not supported by the implementation.
- The eight-unit path teaches 17 concepts; the eighteenth, MDF, exists only in free practice. Course metadata should describe that accurately or integrate MDF with its assumptions explicitly taught.

## Verification scope

The existing sweep contains 58 named routes spanning empty/seeded home, course, records, settings, glossary, practice, reviews, teaching, answers and table states. It launches deterministic debug hooks on a disposable simulator. These are visual fixtures, not interaction tests.

Baseline drill package: 311 tests passed. Release engine package: 91 tests passed. Baseline simulator build succeeded. Inspected captures of Today (empty), Path (seeded), pot-odds question, and opponent picker. The Today capture has a system Apple Intelligence notification over the toolbar; its header is not clean visual evidence. The other three show the app unobscured. Full interaction and accessibility-size checks remain for implementation verification.

Evidence: original checkout `.uisweep/20260913-235605-7IL9zf/`; baseline test logs `/tmp/glass-table-baseline-drills.log` and `/tmp/glass-table-baseline-engine.log`. These are local verification artifacts, not committed Store assets.
