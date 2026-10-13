# C021 correction — organize river-card exploration

The user discovered the existing card selection reveals both final hands. Preserve this interaction; the prior blanket missing-explanation claim is partly withdrawn.

Research direction: group equivalent outcomes to reduce repeated taps through cards of the same rank in different suits. Rank alone is insufficient: suits may change flushes, straight flushes, opponent best hand or win/tie result. Consider a representative comparison with a count and expandable individual cards, using evaluated final hands and outcome to establish groups. Determine whether exact best-five equality is unnecessarily strict for educational equivalence, while retaining all suit-specific details.

Current source audit: ConceptDrillView.swift:1513–1529 lists winning river cards and excluded cards. Components.swift:260–285 renders selected comparison. Reveal.swift:30–44 evaluates both hands; HandEvaluator.bestFiveCards can support more explanatory highlighting. Outs counts strict wins, not ties. These findings are source-derived, not a new physical-device verification.

No native changes during active testing. Grouping is a proposal pending examples and bilingual/light-dark layout review.
