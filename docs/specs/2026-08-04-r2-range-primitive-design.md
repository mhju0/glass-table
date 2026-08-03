# Revamp R2 — Range primitive, derived charts, 13×13 grid (design)

Second slice of the four-slice re-architecture (`2026-08-03-r1-progression-shell-design.md` §1).
Completes Block A and unlocks Block B.

## 0. Why this slice

`product-brief.md` promises **"ranges, not hand ladders."** Every drill shipped so far
grades against a *known villain hand*. There is still no range type in the engine, so
the product's own thesis is unimplemented. R2 is where that changes.

Two Block A nodes are still missing because they need it — 레인지 표기법 and RFI 차트 —
and 12+ of the 20 exercises in the full ladder are queries against the same object.
Build it once.

## 1. The derivation — corrected

R1 spec §13 resolved that we **derive our own chart values and name the public charts
we validate against**, rather than redistributing a chart nobody licenses. That still
stands. What does **not** stand is the rule it suggested for deriving them.

### The measurement that killed it

§13 proposed "top N% by all-in equity versus a uniform random hand." Ranking all 169
classes that way (Monte Carlo, 3000 trials each, via `exactEquityHeadsUp`) puts real
opening hands in the wrong places:

| hand | equity-vs-random | every published chart |
|---|---|---|
| 76s | 129/169 — bottom quartile | opened from CO/BTN |
| 22 | 87/169 | opened from most seats |
| A9o | 25/169 | **folded** from UTG at 8-max |
| ATo | 14 — *above* AJs at 15 | AJs preferred everywhere |

Equity-vs-random measures raw showdown value against junk. It cannot see
**playability**: suited connectors and small pairs earn their value from flopping
flushes, straights and sets, which never appears in an all-in metric. Offsuit
broadways are flattered because they dominate random hands but fare badly against an
actual continuing range.

A published derivation of a wrong chart is worse than no chart — the entire claim is
that the answer is defensible.

### What replaces it — the Chen formula

**Bill Chen's starting-hand formula** (Chen & Ankenman, *The Mathematics of Poker*,
2006), which is public, widely republished, and built for exactly this job:

- High card: A 10 · K 8 · Q 7 · J 6 · else rank ÷ 2 (highest card only)
- Pair: double it, minimum 5
- Suited: +2
- Gap: 0 → −0 · 1 → −1 · 2 → −2 · 3 → −4 · 4+ → −5
- Straight bonus: +1 when gap ≤ 1 and both cards below Q
- Round to the nearest half

Same hands, ranked by Chen:

| hand | Chen rank | matches convention |
|---|---|---|
| AJs 9 · ATo 51 | AJs well above ATo | ✅ |
| 76s 40 (top 24%) | inside CO/BTN ranges | ✅ |
| 22 55 (top 33%) | mid-to-late opening | ✅ |
| A9o 80 (top 47%) | outside early ranges | ✅ |
| JTs 12 · T9s 17 | high, as charts have them | ✅ |
| 72o 169 | dead last | ✅ |

It is a heuristic, not a solver — and the app says so. That is the honest version of
the transparency claim: **the formula is printed in-app, the arithmetic is shown for
the hand on screen, and the source is named.** "Provably correct" was always the wrong
frame for preflop opening ranges, which are a strategic choice rather than a fact;
"explicitly derived, and here is the derivation" is the claim we can actually keep.

### Cut points per seat

A chart is the top N% by Chen score, N set by how many players still act:

| seat | players behind | opens |
|---|---|---|
| UTG | 7 | 15% |
| UTG+1 | 6 | 17% |
| LJ | 5 | 20% |
| HJ | 4 | 23% |
| CO | 3 | 28% |
| BTN | 2 | 42% |
| SB | 1 | 36% |

BB has no RFI — folded to the BB ends the hand. **8-handed has no canonical public
chart**, so these are interpolated between 9-max and 6-max conventions, and the app
discloses that on the chart screen. That disclosure *is* the transparency feature
(`decisions.md` §E).

Benchmarks named in-app, reproduced nowhere: **Upswing's free 9-handed RFI PDF** and
**PokerCoaching's free charts**.

## 2. The Range primitive

Lives in `GlassTableEngine` — it is poker math, and Block B/C exercises are queries
against it. Engine change means the release-mode gate applies.

```
HandClass      169 classes: rank pair + suited/offsuit/pair
Range          weighted map HandClass → Double (0…1), the weight being
               the frequency that class is played
  .combos(removing:)     expand to concrete card pairs, minus dead cards
  .comboCount(removing:) how many combos survive removal
  .percent               share of all 1326 combos
  .contains(_ hand:)     is this specific holding in the range
  ∪ ∩ −                  set algebra, weight-aware
RangeNotation  parse and print "22+, ATs+, KQs, 76s"
```

`percent` is combo-weighted, not class-weighted: a pair is 6 combos, suited 4, offsuit
12. Ranking 169 classes and cutting at "top 20%" without weighting would be wrong by
roughly a factor of two on pair-heavy cuts.

## 3. New content

| node | asks | grades |
|---|---|---|
| **레인지 표기법** | "22+, ATs+, KQs" → how many combos? and → what % of hands? | exact integer / exact percent |
| **RFI 차트** | hand + seat → open or fold | exact vs the derived chart |

Both complete Block A. Unit 3 「레인지」 is added to the path: 레인지 표기법 · RFI 차트 ·
**[boss] 오픈 결정**, a mixed node over both plus 포지션 and 콤보.

The RFI reveal shows the full 13×13 grid with the hand highlighted, the Chen
arithmetic for that hand, and where the cut falls — so a fold is never just "no."

## 4. The 13×13 grid

Universal conventions (`decisions.md` §B): pairs on the diagonal AA→22, **suited upper
right, offsuit lower left**, colour = action. Identical to every other tool, so it
needs no orientation.

**R2 is display-only.** At 13 cells across a 339pt-wide screen a cell is ~26pt, well
under the 44pt touch minimum — painting needs a magnifier or a different interaction,
and that is R3's problem (Range Read is the mode that paints). R2 shows charts and
highlights one hand, which needs no touch target at all.

Mixed-frequency cells render as proportional split fills rather than collapsing to one
colour, so the grid is already correct when R3 starts painting on it.

## 5. Out of scope

No Range Read mode, no archetype ranges, no bots, no postflop. No painting. Block B
exercises beyond what Block A needs. MDF stays parked until its Block B prerequisites
(fold equity, combos-in-a-range) exist — which R2 creates, so it unparks in R3.

## 6. Verification

1. **Chen is ported exactly.** Table-driven test over all 169 classes against
   hand-checked values, including the pair minimum, the gap ladder and the straight
   bonus boundary at Q.
2. **The derived charts match convention.** Assert the named boundary cases: AJs above
   ATo, 76s and 22 inside late ranges, A9o outside early ones, 72o last, and every
   chart nested — UTG ⊂ UTG+1 ⊂ LJ ⊂ HJ ⊂ CO ⊂ BTN.
3. **Combo arithmetic.** 1326 total; pair 6, suited 4, offsuit 12; removal reduces
   counts correctly; `percent` is combo-weighted, property-tested against brute force.
4. **Notation round-trips.** parse → print → parse is stable across the full corpus.
5. **Engine release gate** — `swift test -c release --package-path GlassTableEngine`,
   required because `Range` lands in the engine.
6. **Grid renders every chart** without clipping at the narrowest supported width.

## 7. Open questions

1. **Do the seven cut percentages need a poker-literate review before shipping?** They
   are interpolated for 8-handed and are the one number in R2 that is a judgement
   call rather than a computation.
2. **Does the app show the Chen score itself, or only the verdict?** Showing it is the
   transparency play; it also teaches a heuristic that is *not* how strong players
   actually think, which may be worth a caveat in the copy.
