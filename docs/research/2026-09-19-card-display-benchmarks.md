# Mobile poker card display benchmarks

Reviewed 2026-09-19. Research only; no app changes.

Evidence: directly inspected official App Store screenshot assets in a browser for Apple Texas Hold’em, Poker Heat, Zynga Poker and Poker Trainer. Inspected the official GTO Wizard trainer theme animation. Store screenshots are published marketing examples, not verification of every current in-app theme. These five patterns overlap; they are not an exhaustive or mutually exclusive industry taxonomy.

| Pattern | Example and primary source | Observed treatment | Assessment for Glass Table |
| --- | --- | --- | --- |
| Traditional illustrated card face | [Apple Texas Hold’em](https://apps.apple.com/us/app/texas-holdem/id284602850) | Corner indices, large suit marks, illustrated court cards, opposing indices; number-card interiors are simplified rather than literal pip counts. | Strong familiar visual vocabulary; use upright flat cards for instruction instead of perspective. |
| Jumbo corner index and dominant suit | [Poker Heat](https://apps.apple.com/us/app/poker-heat-texas-holdem-games/id480523695) | Large top-left rank, small suit below, large central/lower suit; hero cards are partly overlapped. | Strong small-screen readability reference. |
| Fanned, partly exposed hole cards | [Zynga Poker](https://apps.apple.com/us/app/zynga-poker-texas-holdem/id354902315) | Hole cards fan around the player seat and expose rank/suit prominently; the board remains a separate row. | Useful for table simulation, weaker for beginner comparison exercises because of overlap/perspective. |
| Centered rank above suit | [Poker Trainer](https://apps.apple.com/us/app/poker-trainer-learn-poker/id6478522482) | White upright cards with rank above a large suit; the pictured diamonds are blue. | Efficient minimal option; vertical stacking uses card height much better than our current short horizontal pair. |
| Color-backed compact rank tiles | [GTO Wizard trainer guide](https://help.gtowizard.com/how-to-use-the-trainer/) | Theme animation shows short colored tiles, large ranks, faint suit artwork and T for ten in a dense multi-table training view. | Appropriate secondary notation for histories/range work; weaker default for newcomers learning physical cards. This evidence is a web trainer screenshot, not native iOS. |

## Inspected images

- Apple: https://is1-ssl.mzstatic.com/image/thumb/Purple113/v4/a9/bf/ba/a9bfba0f-fafd-6a5a-f882-04839e91c383/pr_source.png/600x1300bb.jpg
- Poker Heat: https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/a2/b2/16/a2b2165d-6ba8-65c6-873a-b2f3d201cd36/3657adb9-46d8-442b-a24e-d9c4a0b90b15_1242_U04452688_06.png/600x1300bb.jpg
- Zynga: https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/f4/56/f5/f456f5b2-9871-6fba-0a51-449ef08c5256/Poker_ASO_2606_IOSScreenshotUpdate_2688x1242.png/600x1300bb.jpg
- Poker Trainer: https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/92/17/75/921775ba-40b3-1d32-dc34-563b1d6a83a0/Preflop.png/600x1300bb.jpg
- GTO Wizard: https://help.gtowizard.com/wp-content/uploads/2022/12/gto-wizard-tips-and-tricks-image-30.gif

## Additional corroboration

[PokerStars appearance help](https://www.pokerstars.com/help/articles/table-appearance-feature/) documents card design, four-colour deck and larger opponent-card options. This supports treating color, scale and face design as separate choices. It does not establish a particular mobile default or a specific suit-color mapping.

## Recommendation (design judgment, not measured usability evidence)

Keep full upright cards for lessons and showdown. Prototype a familiar traditional face with large corner rank/suit indices, central pips on number cards and court artwork on J/Q/K. Use original or licensed artwork. Compare it at actual iPhone 12 mini size with a jumbo-index simplified variant. Keep five board cards visible, identical geometry across the three regions, readable 10 without shrink-to-fit, and no card overlap in lessons. Two-color suits are a familiar starting point; optional four-color suits are independent of this decision.

The current component leaves most of a tall card empty around a small horizontal rank/suit pair. Centering fixes alignment, but not the imbalance between card area and useful content. The next design should change that hierarchy, not merely adjust alignment again. No evidence here proves a single most common industry-wide deck; the recommendation combines directly observed conventions with the app’s beginner-teaching purpose.
