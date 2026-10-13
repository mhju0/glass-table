# C007 — Beginner seat terminology and meaningful teaching area

User is explicitly in new beginner mode, lesson3 Who acts first. The acting-order detail lists UTG, UTG+1, LJ, HJ, CO and similar abbreviations in the bottom panel; the learner does not know them. User requests plain-understandable teaching information in the middle and bottom area limited to Next/choices. No screenshot provided for C007 yet; keep observations attributed to the user.

Confirmed initial source: Beats.position (Beats.swift:244 onward) and EnglishBeatScript.position (:121 onward) build order detail by joining Position.rawValue with arrows. WalkthroughView.beatContent (:153 onward) renders no-graphic beats as large caption/value plus Spacers; sheet (:302 onward) contains the explanatory detail and CTA. Beginner naming used elsewhere does not automatically make this raw position chain understandable.

Proposal only: a teaching-area order sequence or seat diagram that introduces plain-language seat roles, highlights the active seat/order, and ties the order to the dealer/blinds. Keep acronyms optional/secondary and introduced before use. Bottom panel should hold only the relevant Next/choice actions. Do not fill blank space with decoration. Share a content/action separation contract with C005's cumulative pot guide and C006's reachable controls.

Validate the actual depicted seat count and preflop/postflop semantics. A full-table sequence is not a universal two-player order. Preserve stable position identifiers and saved sessions; terminology changes should be presentation-only. Compare bilingual plain-label lengths and Dynamic Type, main content/CTA reachability and VoiceOver traversal.

Background source/design audit pending; no native implementation during the ongoing phone session.

## Completed source and capture audit

Existing worked-position images (native-flow-b16/interactions/en-dark/worked-position.png and ko-light/worked-position.png) confirm the user-described layout. Center displays the headline; footer has raw order UTG → UTG+1 → LJ → HJ → CO → BTN → SB → BB with wrapping. Exact model is eight-max (`Position.swift:4–22`), not nine seats. Glossary keeps position codes Latin (`docs/glossary.md:18–22`); preserve canonical IDs/codes while making plain group labels primary for beginners.

The regular drill already supports early/middle/late/blind groups and level-aware terminology (`ConceptDrillView.swift:1087–1189`, `LearningLanguage.swift:70–83`). Reuse that understandable framing in the worked guide, where raw beat details currently bypass it. Proposed center: a structured acting-order/seat visual with before/after-flop context, a highlighted current role and short plain explanation. Introduce code meaning before showing it, or keep codes optional via terminology preference. Footer: Next/answer action only. Shared WalkthroughView changes may affect potMath, potOdds and EV; use explicit teaching-layout contracts rather than global text relocation without checking each concept.

Validate normal/AX5 KO/EN light/dark; eight-seat before/after-flop order, no incorrect generalization to two-player games, group/code reading order in VoiceOver, Back and saved showBeatIndex resume, Reduce Motion. No native edits yet.
