# Glass Table numerical math audit — 2026-10-11

Audited candidate: root-provided HEAD `07054d0`. This is an audit, with no production source/test changes, simulator/device actions, or Git mutations. Evidence is local under `.scratch/numerical-audit-2026-10-11/math/`. Current source, package tests, `CONTEXT.md`, and the branch-specific learner-trust audit of 2026-09-20 were read; historical test counts were not reused as current evidence.

## Outcome

Poker hand frequencies, representative independently recomputed equities, blocker counts, pot odds/call EV/MDF, and table conservation checks passed. Two current outs explanations make definite false statements. Starting-hand percentile wording conflates a declared tie-broken heuristic rank with a score threshold. Published chart targets round upward to whole classes; headline VPIP/PFR figures are approximate targets rather than exact observed rates. Mixed-weight equity and one hypothetical continuation formula have limitations that do not affect current pure published graded policies.

Nothing was fixed or deployed by this audit. The package gates do not certify every seed, every UI state, or poker strategy optimality.

## Current findings and precise reproductions

### M1 — Outs generator does not enforce the currently-behind premise

`OutsSpotGenerator.swift:20–23` accepts a spot based only on 2–15 winning rivers; it never compares the existing six-card hands. Both `Progression/Beats.swift:153` and `Localization/EnglishBeatScript.swift:47` assert that the opponent is currently ahead. Among 1,000 independent recomputations at `baseSeed: 0xA0D17`, 15 heroes were ahead and 22 were tied before the river. Winning-river counts themselves matched the independent classifier in every case.

Concrete public-API reproduction: `OutsSpotGenerator.spot(baseSeed: 0xA0D17, index: 35)` deals hero `Js 4h`, villain `3h Jh`, board `8d 2s Jc Ac`. Both have a pair of jacks; A and 8 are shared kickers, and hero's 4 kicker beats villain's 3. Hero is ahead now, but there are only three outright winning rivers because many river endings chop. Calling those three strict wins an improvement from a losing hand is false. Index 34 gives a currently tied example: hero `5c Js`, villain `2s Jc`, board `Jd Kd 8d Tc`, three winning rivers.

The proposed remedy is a generator premise check or truthful conditional instruction; this report does not prescribe changing the existing strict-win answer rule. Both English and Korean walkthroughs are affected. The generator produces normal lesson/drill spots, so this is current reachable behavior, not a manually forged input.

### M2 — Excluded flush cards can tie, while explanations say they lose

`OutsSpotGenerator.swift:35–42` labels every flush-suit card outside the strict winning-outs set as excluded. Ties therefore qualify. `Reveal.swift:60` says the opponent remains ahead; `Reveal.swift:67` says the opponent is stronger. The walkthroughs describe the opponent improving more. There were 63 excluded river cards that tied across the same 1,000 generated spots. That is a count of cards, not 63 distinct spots. None of these 1,000 accepted heroes already had a flush, although the heuristic accepts a suit count of **at least** four rather than exactly four.

Reproduction: `OutsSpotGenerator.spot(baseSeed: 0xA0D17, index: 116)` deals hero `Qc 9c`, villain `2h Jd`, board `4s 9s Js Ks`. `2s`, `3s`, and `5s` are excluded examples. On each, the five spades on the board form the identical best flush for both hands; the result is a tie, not a stronger opponent hand. Excluding a tie from outright winning outs is correct; explaining the exclusion as a loss is false.

### M3 — Starting-hand “at least as strong by Chen score” is not what is computed

`PracticeReplay.swift:100–124` describes a score-threshold share but takes a prefix of `Chen.ranked` ending at the exact class. `Chen.swift:58–70` deliberately breaks equal scores by pairs, suitedness, gap, and high card. Thus 142 of 169 classes have a prefix smaller than the share of all classes with equal-or-higher score. Example: `22` and `A9o` both score 5. `22`'s prefix is 362/1326 = 27.30%, displayed as top 27%; `A9o`'s is 454/1326 = 34.24%, displayed as top 34%; the equal-or-better **score** threshold is 538/1326 = 40.57% for both. This is a semantic mismatch, not a failure to weight combos.

`FreeTableHandCoachView.swift:74` correctly distinguishes starting-hand rank from winning probability, but the top-percent labels at lines 105–107 do not identify this tie-break convention. The arithmetic is valid as a declared ordered-heuristic percentile. Either document that meaning or calculate the score-threshold meaning; changing it silently would also change beginner coach classifications.

### M4 — Chart targets and archetype headlines are approximate after class cuts

`HandRange.swift:75–92` intentionally includes the entire boundary class. This makes the arithmetic coherent and memorable; it produces upward deviations of less than one class (at most 12/1326 = 0.905 percentage points) from a positive target. `Archetype.swift:84–93` normalizes seat factors exactly at the **target** level, but the comment that the average “returns” the declared VPIP/PFR is not exact after cuts. `Progression/Beats.swift:462` says PFR is opened on average; the actual seven-seat averages are shown below. These are not measured VPIP/PFR over conditional dealt/play histories. The free-table bot already discloses that its authored selection percentages are not claims of observed action rates (`PracticeBot.swift:20–21`).

### M5 — Weighted ranges have unweighted equity/distribution expansion (latent API limit)

`HandRange.swift:44–49` deliberately expands partial-weight classes in full. `rangeOnBoard(range:)`, `rangeEquity`, and calls to `equityVsRange` using expanded combos therefore ignore class weights, even though `comboCount` and `percent` honor them. Probe: hero range `KK`, river board `3c 5d 7h 9s Jc`; villain `AA:1,22:0.01` has 6.06 weighted combos but expands to 12. At 100,000 fixed-seed samples, equity is the same 50.133% as `AA:1,22:1`; properly frequency-weighted equity is 0.990099%. Pure current RFI, defend, archetype, notation and shaped generated ranges contain only full-weight classes, so this probe is not evidence of a current authored drill error.

`HandRange.subtracting` is support subtraction (drop every positively present class), not subtraction of fractional frequencies. Its current pure-chart usage is coherent. Partial-weight API support should not be advertised as complete equity support without a separate weighting implementation.

### M6 — Per-combo best continuation would overprice a hypothetical raising subtree

`Table.swift:575–576` averages `max(-b, e_i*(pot+2r)-r)` across hidden combos. An informed legal continuation would choose one action against the observed raising range: maximize the aggregate fold/call EV. For a hypothetical 10bb pot, 5bb bet, 15bb raise and equal-probability hidden equities 0 and 1, the implemented mean is `(−5 + 25)/2 = 10bb`; one legal aggregate continuation gives `max(−5, 0.5*40−15) = 5bb`. This is a 5bb clairvoyance premium.

**Unreachable under all current five graded policies:** every policy's `raises` set is a subset of its `bets` set, while a checked-to state has already retained only the complement of `bets`. Station never raises; Maniac never checks. The independent probe confirms `raises.subtracting(bets)` is empty for all five, and for casual. Do not report this as a current learner grade defect. Future policy changes allowing check-raises must revisit this formula.

## Verification evidence

| Check | Current result | Boundary |
|---|---|---|
| `swift test -c release --package-path GlassTableEngine` | PASS, 93 XCTest tests, 0 failures, 136.732 seconds | Includes full 7-card census using engine evaluator and frozen eval7 equity oracle tests |
| `swift test --package-path GlassTableDrills` | PASS, 401 XCTest + 75 Swift Testing tests, 0 failures | Package only; no app/simulator tests |
| Independent exhaustive 5-card classifier | PASS, 2,598,960 hands, zero category/top-rank differences against public engine summaries | Independent array/group ranking; not a full exhaustive kicker-order equivalence proof |
| Independent direct 7-card census | PASS, all 133,784,560 sets, all nine counts and 4,324 royals agree | C++ rank/suit census, no engine call or best-five-subset algorithm |
| Independent representative complete best-seven summaries | PASS, 1,000 generated seven-card hands | Category/top-rank only; full ordering is separately exercised through equity outcomes |
| Independent exact heads-up equity | PASS, 10 flops ×990 completions, 100 turns ×44, 890 rivers ×1; wins/ties/totals all agree | Rule classifier independently evaluates every candidate five-card subset |
| Independent MC comparison | PASS, 15 flops at 100,000 samples each; largest deviation 0.178303 percentage points; repeats identical | Not a bound on every seed or on the table's 200-samples-per-combo budget |
| Independent blocker enumeration | PASS, 153 dead-card sets ×169 classes =25,857 comparisons, zero mismatches | Empty set, each individual deck card, 100 seven-card dead sets |
| Pot-odds, EV, MDF payoff identities | PASS, 151,500 formula comparisons, zero mismatches | Pots 0…100, bets 1…100, equities 0/.25/.5/.75/1 |
| Current charts | PASS, all 169 classes ×8 seats exported; all 42 archetype×seat partitions/nesting agree | Derived policy consistency, not solver or strategy validation |
| Practice conservation | PASS, 750 hands /4,058 accepted random actions; 2/3/4 players, stacks 2/3/7/40/100 | Each ongoing state, terminal contributions/refunds/payouts, every replay prefix, validate/replay passed |
| Graded heads-up conservation | PASS, 500 hands over all five archetypes | Ongoing stacks+pot=201.5bb; terminal Outcome nets coherent; no payout persistence claimed |

Logs: `engine-release.log`, `drills-debug.log`, `independent-probe-build.log`, `independent-probe.jsonl`, `frequency7.json`. Source and executable SHA-256 values are retained in `provenance-sha256.txt`; probe implementations are `AuditRunner/Sources/AuditRunner/main.swift` and `frequency7.cpp`. `summary.json` includes every chart class, count, archetype row and probe result. `chart-mapping-169x8.csv` includes BB's deliberately empty RFI range; the seven acting-seat columns satisfy the requested 169×7 chart inventory. `archetype-counts-6x7.csv` includes casual separately from the five gradable opponents.

Reproduction:

```sh
swift test -c release --package-path GlassTableEngine
swift test --package-path GlassTableDrills
swift run -c release --package-path .scratch/numerical-audit-2026-10-11/math/AuditRunner
clang++ -O3 -std=c++17 .scratch/numerical-audit-2026-10-11/math/frequency7.cpp -o .scratch/numerical-audit-2026-10-11/math/frequency7
.scratch/numerical-audit-2026-10-11/math/frequency7
python3 .scratch/numerical-audit-2026-10-11/math/summarize.py
```

## Frequency inventory

| Best hand category | Exact 5-card count | Exact 7-card count | 7-card percent |
|---|---:|---:|---:|
| High card | 1,302,540 | 23,294,460 | 17.4119196 |
| One pair | 1,098,240 | 58,627,800 | 43.8225457 |
| Two pair | 123,552 | 31,433,400 | 23.4955364 |
| Three of a kind | 54,912 | 6,461,620 | 4.8298698 |
| Straight | 10,200 | 6,180,020 | 4.6193821 |
| Flush | 5,108 | 4,047,644 | 3.0254941 |
| Full house | 3,744 | 3,473,184 | 2.5961023 |
| Four of a kind | 624 | 224,848 | 0.1680672 |
| Straight flush, including royal | 40 | 41,584 | 0.0310828 |
| Total | 2,598,960 | 133,784,560 | 100 |

Five-card combinatoric formulas were separately checked against enumeration in `summarize.py`. Seven-card royal count is `4*C(47,2)=4,324`, because each suit's fixed royal has two arbitrary remaining cards; there cannot be two royals in seven cards. Royal share ≈0.003232%, non-royal straight-flush count 37,260. `HoldemBasicsContent.swift:30–32` uses the split correctly, preventing royal duplication in its ten displayed categories. Five-card counts must not be presented as the distribution of best-of-seven Hold'em hands.

## Current chart and range inventories

These are **combo-weighted** figures (denominator 1,326), not counts divided by 169. All range members are full-weight classes. `HandClass` supplies 13 pairs×6=78 combos, 78 suited classes×4=312, and 78 offsuit classes×12=936; total 169 classes /1,326 combos. The independent blocker enumeration also directly counts actual unordered two-card holdings. `summarize.py` separately deals all 1,326 unordered card pairs, maps their ranks/suits to the exported cells, and recounts all eight charts; every RFI/3-bet/call/fold count agrees with the package APIs.

| Seat | RFI target % | Classes | RFI combos | Actual % | 3-bet combos | Call combos | Fold combos |
|---|---:|---:|---:|---:|---:|---:|---:|
| UTG | 15 | 37 | 204 | 15.384615 | 64 | 88 | 1,174 |
| UTG+1 | 17 | 39 | 228 | 17.194570 | 68 | 104 | 1,154 |
| LJ | 20 | 47 | 270 | 20.361991 | 88 | 116 | 1,122 |
| HJ | 23 | 50 | 306 | 23.076923 | 94 | 138 | 1,094 |
| CO | 28 | 61 | 374 | 28.205128 | 114 | 168 | 1,044 |
| BTN | 42 | 84 | 562 | 42.383107 | 168 | 250 | 908 |
| SB | 36 | 75 | 478 | 36.048265 | 148 | 214 | 964 |
| BB | absent | 0 | 0 | 0 | 0 | 0 | 1,326 |

Defend widths use the **target** opener percentage: 3-bet target =0.30×; all-continue target =0.75×; call is the difference of the two whole-class cuts. Each action partitions every class. The same chart is used regardless of the hero seat and opponent archetype; the graded table grades preflop by this seat-based chart, even though its dealt opponent range is archetype-specific. This is a declared simplified policy, not a claim that 3-bet/call/fold is EV-optimal against each archetype. Charts cannot certify real-money advice or game-theoretic quality.

| Archetype | VPIP target % | Actual mean play % | PFR target % | Actual mean raise % |
|---|---:|---:|---:|---:|
| Nit | 12 | 12.346477 | 9 | 9.265245 |
| TAG | 20 | 20.383538 | 17 | 17.302306 |
| LAG | 27 | 27.494075 | 22 | 22.365869 |
| Station | 40 | 40.573152 | 10 | 10.364146 |
| Maniac | 55 | 55.397544 | 40 | 40.573152 |
| Casual, excluded from gradable allCases | 45 | 45.528981 | 12 | 12.346477 |

Every one of the 42 seat/archetype rows has `raise + call = play`; the 3-bet continue range is nested in raise. Per-seat concrete counts are retained in the CSV/JSON rather than hidden behind averages. Practice bots use unscaled headline widths, unlike graded seat-dependent archetype ranges. Casual adds seeded calls/bluffs and therefore has no gradable deterministic action-inversion promise.

## Formula and policy review

- **Exact equity:** four private cards plus known community cards are removed from the deck; on a legal flop 45 unseen cards give 990 unordered runouts, turn gives 44, river gives one. A heads-up tie contributes half a pot. For all legal private-card combos, `equityVsRange` filters hero/board collisions and equally averages surviving full-frequency combos. Equal runout counts make that average correct. Empty-range equity returns 0, while `rangeEquity` returns 0.5 when no samples are possible; these are API sentinel choices, not a defined poker equity for an impossible state.
- **MC deck sampling:** partial Fisher–Yates draws without replacement within each trial. Retaining a shuffled deck between trials does not duplicate cards or change its uniform conditional draw law. `%` reduction has negligible modulo bias (64-bit randomness), but not formal cryptographic unbiasedness. The fixed seed makes outputs reproducible, not exact.
- **Range-v-range sampling:** sample one hero and one villain combo uniformly, reject collisions, then uniformly sample a legal runout. This is the uniform joint distribution over legal pure-range combo pairs, rather than equal weighting of 169 classes. Board dead cards are removed before pairing. The 20× attempt cap can reduce achieved samples in pathological overlapping ranges and exposes no sample count. Current authored ranges do not prove this impossible for arbitrary caller-supplied input.
- **Sampling disclosure:** default 8,000 range-equity samples have worst-case standard error `sqrt(.25/8000)*100=0.559017` percentage points; a normal 95% interval has half-width ≈1.096 pp. `BoardDrills.swift:133–139` says about ±1% error without specifying percentage points or confidence. It is a reasonable rough scale, not a guaranteed bound. Generated range-advantage grading uses 4pp/10pp bands. The table flop uses only 200 samples per opponent combo (`Table.swift:534`), exact turn/river; no numerical error bound relative to its 0.5bb grade threshold was proved here. UI does disclose sampled flop/checkdown assumptions (`GradedTableLearningUI.swift:31`).
- **Call EV and ties:** with current pot P already including the opponent wager, hero call C, and equity `e=winProbability+tieProbability/2`, incremental EV is `e*(P+C)-C`, identical to engine `e*P-(1-e)*C`. The tie branch yields `(P-C)/2`. Prior hero money in P is sunk and legitimately included in the amount contested; subtracting it again would be wrong. Gross heads-up Outcome net is separately payout minus cumulative investment.
- **Pot odds/MDF:** with pre-bet pot P and matched bet B, required equity is `B/(P+2B)`, MDF is `P/(P+B)`. MDF follows from a zero-showdown-equity bluff and is a simplified range-level defense relation, not a universal optimal-calling rule on every board. The source consistently distinguishes pre-bet and bet-included pot parameters. Negative/NaN inputs and impossible duplicate cards are not broadly validated by pure APIs; current legal generators are the audited domain.
- **Outs:** strict winning rivers are counted exactly; ties intentionally contribute zero outs. True win probability on these face-up turn spots is `outs/44`; equity also needs ties/88. Rule-of-2 `2*outs%` is a disclosed approximation, consistently below `100*outs/44` by 0.272727 pp per out (4.090909 pp at 15 outs). Rule-of-4 is also a heuristic; clean fixed outs on flop give `1-(47-o)*(46-o)/(47*46)`, and actual outs can change after the turn. No exact-two-card probability promise should be inferred from it.
- **Chen:** the code consistently applies the internally declared high-card/pair/suited/gap/straight-bonus arithmetic. Its upward half-point rounding is a mathematical identity because all ingredients already lie on a half-point lattice. Therefore it retains e.g. 76s=6.5 and 72o=−1.5. Source/spec “ported verbatim” and bibliography were not verified against an original-author formula publication; various externally published formula variants differ. This audit establishes the implementation's declared heuristic, not original-author provenance or its strategic optimality. Chen's own [interview explanation](https://oldpokerinterviews.wordpress.com/interview-with-bill-chen/) describes a quantitative hand-grouping heuristic, without establishing this code's rounding convention.
- **Grading:** numeric absolute-error bands, exact outs/combos, binary RFI/call-fold, Jaccard-weighted range overlap, and best-minus-chosen EV are policy rules. EV bands ≤0.5bb and ≤2bb are absolute, not pot-relative. Exact and near-best share a progression band while wording distinguishes positive loss. Defend adjacency grading is chart agreement, not a claim of low EV loss. Estimates and 90% intervals are different evidence; count questions do not gain calibration credit.
- **Table settlement:** practice side pots use contribution-level slices, exclude folded players from winning eligibility, return a sole contributor's unmatched slice, divide tied pots by integer quotient, and award odd chips clockwise from the dealer. Test coverage includes unequal stacks, short all-ins/reopening, and odd chips. The new random check supplements it with all replay prefixes and small stacks. Graded heads-up uses dead blinds=1.5bb and 100bb per active player, clamps bets to effective stacks, and exposes terminal net rather than mutating stacks with a payout. Uncalled own bets cancel correctly in payout-minus-investment.
- **PotMath:** raises add `target-alreadyIn`; calls add the incremental call amount; folds do not remove contributions. Fraction questions use literal .33/.5/.75 and round once to integer chips. Replay steps and existing tests cover contribution arithmetic. A three-way partial-action sequence can legitimately pause while another caller still owes a 3-bet response; its current pot includes only chips actually placed.
- **Buckets and river policy:** `madeHand` classifies a best hand and then differentiates top/weak personal pair versus a board-only one-pair hand. It intentionally groups shared two-pair-or-better boards as strong. The graded table remaps an unmade river draw to air before both play and grading (`Table.swift:217`). The practice coach does the same; practice bots classify raw river draws at `PracticeBot.swift:43,80` and therefore can still call/bet on that raw category. This asymmetry is real, but the free bot's published selection behavior differs from the graded model and no solver-optimal play promise is made.

## Limits and remaining work

No app launch, screenshots, VoiceOver, phone action, submission, production deployment, actual human comprehension study, or persistent-data migration audit was performed. Exhaustive frequency agreement certifies category counts, not every ordering relation; the independent equity probes and frozen eval7 tests add representative ordering evidence. All charts were inspected as derived policies, not validated against a current licensed external strategy chart. The full 7-card independent census and representative equity oracle provide mathematical evidence without dependence on a web probability table. The M1/M2 false claims need a scoped fix and regression coverage before marking them resolved. M3/M4 wording needs a declared meaning; M5/M6 require attention before extending the policy/API domain.
