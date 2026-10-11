# Brand welcome and uninterrupted beginner guide — build 22

Owner feedback on build21: adopt welcome optionC; remove poker-experience question, midpoint suggestion to stop, repetitive hero wins and six-suited-card flush; inspect spacing in bottom panels and help sheets. Native implementation authorized with a fresh iPhone12mini installation.

## Accepted behavior

- First-run brand welcome: fixed native table-green background, quiet card/spade emblem, GlassTable title and one bottom Start action. Guide pages use existing adaptive paper/charcoal background. Welcome replaces old readiness preamble; Start teaches a pair immediately. No timed splash or repeated welcome on ordinary resume/replay. A transient view flag makes status-bar ink light only while the fixed-green welcome is visible; guide/theme preference remains adaptive and is not persisted or replaced.
- Remove the experience self-report from normal opening, Learn and Settings routes. It formerly affected lesson suggestions, beginner question forms, initial hints and term-led wording; no mastery or completion was awarded. New learners use the current beginner defaults; existing placement evidence is retained. Direct lesson choice and explicit help/terminology controls stay available.
- All five guide comparisons remain required and follow progressive teaching order. Continue directly after the second example. Remove midpoint finish-for-now and optional experience interruption, while keeping ordinary Back/Skip controls.
- New guide visits use a seeded stable permutation of winners: two or three wins for each side in five comparisons. Cards, grades and reveals must agree. A new flush example has exactly five suited cards across all nine visible cards, with legal unique cards and evaluator-confirmed hand categories.
- Keep normal English/Korean semantic groups paired; no clipping/shrinking to force line parity. Larger text can naturally wrap and scroll. Bottom action areas reserve their own layout space; help sheets must expose readable content and reachable dismissal/actions. Short hints measure content height; AX uses a large scrollable sheet. The centered close control uses48pt source geometry so the compact system presentation retains at least44pt effective target.

## Persistence invariants — Class 3

Content changes use snapshot-local comparisonVersion. Missing JSON key is legacy1; new snapshots use2. Existing schema2 remains unchanged. Legacy bank, seed mapping, responses and optional pages stay identical. Raw checkpoint/preference step identifiers remain decodable but render as comparison three without adding responses. Retired pages do not appear in new navigation history. Save rejects a changed version as it rejects a changed seed. Unknown versions preserve recovery bytes. Completion still requires all five responses and wrapUp; welcome/skip provide no graded or mastery credit.

## Acceptance evidence

Record final frozen-source independent review, package and app tests, actual new and legacy route interactions, English/Korean × light/dark normal and accessibility captures, signed build metadata and physical fresh first-run welcome before claiming delivery. A simulator capture alone does not establish VoiceOver, novice learning or minimum-iOS17 runtime. Device reinstall uninstalls first; no phone progress is copied.

- Answer-choice subtitle: “Choose this hand” / “이 패 선택하기” replaces “This hand is stronger” on both choices, avoiding an apparent conflicting app assertion before a response.
