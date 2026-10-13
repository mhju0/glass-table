# Poker number audit: primary sources and definitions

Date: 2026-10-11  
Scope: source-backed numerical definitions for the existing Glass Table engine and drills. This is research only; no product behavior was changed.

## Findings at a glance

- Five-card frequencies describe the ranking of one five-card hand. Hold’em showdowns choose the best five cards from seven, so five-card frequencies are not the distribution of a Hold’em final hand.
- `HandFrequency`'s 133,784,560 seven-card total and all nine category counts match Noga Alon's published exact table. The app's category 8 combines royal and non-royal straight flushes; it separately reports the 4,324 royal-flush cases.
- A 52-card deck has `C(52,2) = 1,326` concrete hole-card pairs. The 169 display classes are suit-equivalence groups: 13 pairs + 78 suited non-pairs + 78 offsuit non-pairs. Their concrete multiplicities are 6, 4, and 12, respectively. A range percentage must therefore be combo-weighted; `HandRange.percent` does this.
- A “winning out” depends on the known villain hand, board, and endpoint being evaluated. `countOuts` is specifically turn-to-river: among 44 unseen cards after 2+2 hole cards and four board cards are known, it counts rivers on which hero wins outright. It excludes ties. `ruleOf2or4` is explicitly an estimate, not exact equity.
- Heads-up equity correctly treats a tie as half a pot (`wins + ties/2`). `exactEquityHeadsUp` enumerates all legal board completions; this is stronger evidence than an out-count approximation. Multiway tie shares are not represented by this API.
- `requiredEquity` and `callEV` are correct under the stated pot convention: the pot argument contains the opponent's bet and excludes the hero's call. The formula assumes a rake-free, terminal call-vs-fold comparison and equity as expected pot share. The current call/fold drills use a turn board against a fully shown opponent, so there is one river to come.
- MDF `P/(P+B)` is the complement of the break-even fold frequency for a zero-showdown-value bluff risking `B` to win the existing pot `P`. It is an aggregate range-defense benchmark under that simplified one-bet model, not a hand-specific calling threshold or a general solver prescription.
- Chen score and the app's position widths are heuristics. They do not solve a game or establish a universal optimal preflop strategy. The implementation's half-point behavior does not match a 2013 University of Porto academic reproduction that says its Chen function returns an integer. The exact original book pages were not accessible, so “ported verbatim” and the 2006 attribution remain unverified.

## Exact five-card and best-of-seven frequencies

The University of Utah combinatorics handout enumerates five-card hands from a 52-card deck and gives the exact disjoint category counts. It treats royal flush as separate, and its straight-flush/flush/straight counts exclude overlapping higher categories.

| Best five-card category | Count out of 2,598,960 | Probability |
|---|---:|---:|
| Royal flush | 4 | 0.000154% |
| Straight flush, excluding royal | 36 | 0.001385% |
| Four of a kind | 624 | 0.024010% |
| Full house | 3,744 | 0.144058% |
| Flush, excluding straight flush | 5,108 | 0.196540% |
| Straight, excluding straight flush | 10,200 | 0.392465% |
| Three of a kind | 54,912 | 2.112845% |
| Two pair | 123,552 | 4.753902% |
| One pair | 1,098,240 | 42.256903% |
| High card | 1,302,540 | 50.117739% |

These counts sum to 2,598,960 = `C(52,5)`. Source: [University of Utah, Neil E. Cotter, “Probability / Combinatorics, Example 15”](https://ctools.ece.utah.edu/Probability/Combinatorics/ProbCombEx15.pdf), pp. 1–5. The handout explicitly assumes a 52-card deck and explains the category counts combinatorially.

For Hold’em, the relevant distribution is the best five-card hand available from seven. Alon's paper defines Hold’em showdown that way and tabulates exact counts over `C(52,7) = 133,784,560` seven-card sets:

| Best five of seven | Count out of 133,784,560 | Probability |
|---|---:|---:|
| High card | 23,294,460 | 17.411920% |
| One pair | 58,627,800 | 43.822546% |
| Two pair | 31,433,400 | 23.495536% |
| Three of a kind | 6,461,620 | 4.829870% |
| Straight | 6,180,020 | 4.619382% |
| Flush | 4,047,644 | 3.025494% |
| Full house | 3,473,184 | 2.596102% |
| Four of a kind | 224,848 | 0.168067% |
| Straight flush, royal included | 41,584 | 0.031083% |

Of the last category, 4,324 are royal flushes (0.003232%) and 37,260 are non-royal straight flushes (0.027850%). The nine app-category counts sum exactly to the denominator. Sources: [Noga Alon, “Poker, Chance and Skill,” section 3](https://web.math.princeton.edu/~nalon/PDFS/skill4.pdf), especially pp. 4–5; the same source states that Hold’em uses the best five of the seven available cards (pp. 2–3). Alon describes the count table as exact and rounds only the displayed probabilities.

**Interpretation check:** “probability of a category in a random five-card hand” and “probability the best hand from seven cards is that category” are different measures. In seven cards, one pair is more frequent than high card; the ranking remains based on the best five-card hand, not which seven-card rank pattern is most common.

## Starting-hand combinations and range weighting

Alon describes two hole cards drawn from a standard 52-card deck. The counts follow directly from combinations and suit-equivalence:

- Concrete combinations: `C(52,2) = 1,326`.
- Unordered rank pairs: `C(13,2) = 78`.
- 13 pocket-pair classes × `C(4,2) = 6` suit combinations = 78 concrete combinations.
- 78 suited non-pair classes × 4 suits = 312 combinations.
- 78 offsuit non-pair classes × 12 suit arrangements = 936 combinations.
- Total display classes: 13 + 78 + 78 = 169; concrete combinations: 78 + 312 + 936 = 1,326.

The phrase “169 combinations” is misleading if it means concrete deals: the 169 are rank/suitedness classes. In code, `HandClass.comboCount` supplies the 6/4/12 multiplicity, `HandRange.comboCount` weights each class by that multiplicity and its strategy weight, and `HandRange.percent` divides by all 1,326 concrete combinations. `topByChen` cuts on this combo-weighted total, then includes a whole boundary class, so the resulting chart can slightly exceed its nominal percentage. See `GlassTableEngine/Sources/GlassTableEngine/HandClass.swift` and `HandRange.swift`.

These counts are elementary derivations from the standard 52-card deck, not solver output. Alon's academic treatment confirms the standard-deck/two-hole-card rules and also shows why card removal matters: with five board cards exposed, only `C(47,2) = 1,081` hole-card combinations remain (paper pp. 2, 6).

## Outs and card-to-come probabilities

An out is contextual: it is a remaining card that changes the current hand comparison into a win at the evaluated endpoint. Alon gives a textbook flop example: with four diamonds visible among a player's two hole cards and the three-card flop, nine diamonds remain among 47 unseen cards, so the next-card probability is `9/47`; if the turn misses, the river chance is conditional on 46 remaining cards (paper p. 5). That is a hidden-opponent probability convention; it does not remove unknown opponent cards from the public deck count.

The app's `countOuts(hero:villain:board:)` has a different, explicit state: turn board (four community cards), both two-card hands shown. Eight known cards leave 44 possible rivers. It enumerates all 44 and includes only rivers where `evaluate7(hero + board + river) > evaluate7(villain + board + river)`. Therefore exact turn-to-river outright-win probability for that fixed-villain drill is `outCount / 44`; ties are not counted as wins.

`ruleOf2or4` computes 2 percentage points per out with one card to come, or 4 points per out with two cards to come. This is a quick approximation. For `o` fixed cards among `N` possible cards and two draws, the probability of seeing at least one is exactly `1 - ((N-o)/N) × ((N-1-o)/(N-1))`. Even that is only the chance to see a member of a fixed set: it does not guarantee final showdown victory if later cards redraw the opponent or if “outs” change by turn. Exact heads-up equity instead enumerates complete legal runouts. See `GlassTableEngine/Sources/GlassTableEngine/Outs.swift`, `Equity.swift`, and `GlassTableDrills/Sources/GlassTableDrills/OutsSpot.swift`.

**Definition to test in copy:** do not label the count as “cards that improve the hand” unless improvement is literally intended. The implementation counts cards that make this hero beat this displayed villain at showdown on the river. Some apparent draw-completing cards may be dirty; some cards may improve a category but still lose. A tie is not an outright win here.

## Equity, pot odds, call EV, and MDF

Alon states that tied best hands split the pot equally (paper p. 3). For heads-up outcomes, the app's equity formula is therefore correct: `(wins + 0.5 × ties) / total`, the expected fraction of the pot returned to hero. Its `exactEquityHeadsUp` enumerates all combinations of remaining community cards, so this is exact for the fixed two hands and current board. Do not generalize its `ties / 2` rule to multiway pots; a three-way tie awards one third to each.

Let `P` be the pot after the opponent's bet but before hero calls, `C` be the call amount, and `e` be hero's expected pot share at showdown. Relative to folding now (EV 0), the rake-free terminal call EV is:

`callEV = e(P + C) - C = eP - (1-e)C`.

So the break-even equity is `C/(P+C)`. This matches `requiredEquity(toCall:pot:)` and `callEV(equity:toCall:pot:)` in `GlassTableEngine/PotOdds.swift`, whose comment says `pot` includes the opponent's bet. `BetSpot.requiredPct` and `CallFoldSpot.requiredPct` pass `originalPot + opponentBet`; the reveal copy expresses `call / (original pot + opponent bet + call)`, which is the same denominator. The simplification excludes rake, future implied odds, future betting, and any action other than call or fold; equity must include tie shares. Alon discusses expected value and the need to consider strategy beyond raw hand probability in the same section of the paper (p. 5).

For MDF, let `P` be the pot before the opponent bets, and `B` their bet. A pure bluff that always loses at showdown earns `P` when the defender folds and loses `B` when called. Its one-street EV is `F×P - (1-F)×B`, where `F` is the defender's fold frequency. The break-even fold frequency is `F = B/(P+B)`. The complementary defense frequency is `1-F = P/(P+B)`, the formula in `mdf(bet:pot:)` and `BetSpot.mdfPct`.

**Assumptions and limits:** this derivation assumes the bet has zero showdown equity when called, no rake, no future betting, and no other source of value. MDF counts calls and raises together as continuing; it is a range-level threshold that makes an any-two-card pure bluff indifferent in the toy model. It does not mean each individual hand should call that percentage, does not equal pot-odds equity, and does not by itself prescribe a solver's defense against a value/bluff range. The current drill correctly presents it as an aggregate “defend across your range” concept; its exact strategic assumptions should remain explicit.

## Chen score and chart strategy claims

`GlassTableEngine/Sources/GlassTableEngine/Chen.swift` implements a high-card score, pair multiplier/minimum, suited bonus, gap penalties, and a low-card straight bonus. It then returns `(s * 2).rounded(.up) / 2`. Because the score arithmetic is already in whole or half-point increments, this leaves `.5` scores unchanged: for example, 97o has score 4.5 in this implementation. Independently applying the source formula to all 169 classes yields 32 classes with half-point scores. A 2013 University of Porto academic paper's reproduced Chen function is described as returning an integer. Common modern formula summaries likewise say half-point results round up to the next whole point (for example, 7.5→8), but those are secondary sources. This is a material reason not to call the current code a verified verbatim port without checking the original text.

The code's 169-class sort resolves equal-score ties with an app-defined order (pairs, suited, smaller gap, higher high card). `RFIChart` chooses position percentages and `DefendChart` chooses fractions of those widths; these percentages and tie-breaks are app choices, not consequences of the scoring formula.

Alon's paper supplies a useful primary-source boundary: Hold’em decisions depend on position, number of players, opponent betting strategy, and bluffs; its precisely analyzed poker examples are explicitly simplified models, while the real game is more complicated (paper pp. 6–7, 15–16). Thus a scalar hand score/ranking is a heuristic for ordering starting hands, not a universal optimal policy. The app's own `Chen.swift` comments also call it a heuristic, not a solver.

**Historical/source uncertainty:** `Chen.swift` says “Bill Chen's starting-hand formula (Chen & Ankenman, *The Mathematics of Poker*, 2006), ported verbatim.” The paper “[Computing Card Probabilities in Texas Hold'em](https://web.fe.up.pt/~niadr/PUBLICATIONS/2013/TeofiloReisLopesCardoso_ComputingCardProbabilitiesInTexasHoldem.pdf)” (CISTI 2013, University of Porto-hosted) calls the Chen method a relative-value heuristic, cites Chen and Ankenman's 2006 book, and states its function returns an integer; its snippet includes a simplified code algorithm, but does not establish the wording of the original source. Lou Krieger's official bibliography confirms that *Hold'em Excellence*, 2nd edition, was published in 2000 and covered grouping starting hands by quality; it does not mention Chen. I did not find an accessible primary page proving the exact formula's first publication or the original whole-point rounding text. Thus the existing source attribution and “ported verbatim” claim should remain unverified until the cited books are checked directly. The actual current implementation demonstrably retains half points such as 4.5. The score/ranking is not itself evidence of equilibrium-optimal strategy.

## Local source map and audit questions

- `GlassTableEngine/Sources/GlassTableEngine/HandFrequency.swift`: seven-card totals and category counts; source values match Alon exactly.
- `GlassTableEngine/Tests/GlassTableEngineTests/HandFrequencyTests.swift`: exhaustive recount using this module's own evaluator; source-level test, not an independent oracle.
- `GlassTableEngine/Sources/GlassTableEngine/HandClass.swift` and `HandRange.swift`: 169 classes, concrete combo multiplicity, combo-weighted range percent and whole-class boundary rounding.
- `GlassTableEngine/Sources/GlassTableEngine/Outs.swift`: turn-river outright winners plus approximate rule-of-2/4.
- `GlassTableEngine/Sources/GlassTableEngine/Equity.swift`: exact heads-up runout enumeration and tie-share accounting; range averaging accepts concrete combos and skips blocked cards.
- `GlassTableEngine/Sources/GlassTableEngine/PotOdds.swift`, `GlassTableDrills/Sources/GlassTableDrills/BetSpot.swift`, `CallFold.swift`: pot convention, pot odds, EV, and MDF.
- `GlassTableEngine/Sources/GlassTableEngine/Chen.swift`, `GlassTableDrills/Sources/GlassTableDrills/RFIChart.swift`, `DefendChart.swift`: score formula, tie-break, and selected range widths.

Questions for product review: does the learner-facing out percentage need to be the exact `outs/44` for this exposed-villain turn spot, or is the explicitly named rule-of-2 estimate pedagogically intended? Does any range chart label imply solver/optimal status despite its disclosed Chen ranking and manually selected widths? Should tie equity language be explicitly scoped to heads-up when shown outside that drill?

## Primary sources

1. Noga Alon, “[Poker, Chance and Skill](https://web.math.princeton.edu/~nalon/PDFS/skill4.pdf),” Princeton-hosted paper. Rules and best-five/tie definitions; exact 5-card and 7-card probability tables; card-to-come example; discussion of simplified game-theoretic models and strategy dependence.
2. Neil E. Cotter, “[Probability / Combinatorics, Example 15](https://ctools.ece.utah.edu/Probability/Combinatorics/ProbCombEx15.pdf),” University of Utah. Combinatorial derivations of exact five-card category counts.
3. Luís F. Teófilo, Luís Paulo Reis, and Hugo L. Cardoso, “[Computing Card Probabilities in Texas Hold'em](https://web.fe.up.pt/~niadr/PUBLICATIONS/2013/TeofiloReisLopesCardoso_ComputingCardProbabilitiesInTexasHoldem.pdf),” CISTI 2013, University of Porto-hosted. Its Chen section describes a fast relative-value method and gives a function returning an integer, citing Chen & Ankenman (2006); this is a scholarly reproduction, not the original source.
4. Lou Krieger, “[Hold'em Excellence: From Beginner to Winner](https://www.loukrieger.com/books/holdem-excellence/),” author's official bibliography. Primary metadata for the 2000 second edition only; not sufficient by itself to source the Chen formula's exact contents or origin.
