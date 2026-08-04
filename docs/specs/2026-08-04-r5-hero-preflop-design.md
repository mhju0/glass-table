# Revamp R5 — Hero preflop at the table (design)

R4-S4 scripted hero's preflop street because grading a call under the checkdown model
teaches calling everything, and the app had no defending baseline to grade against.
R5 builds that baseline and opens the street: **hero is dealt any two cards, and
fold / call / 3-bet is a real, graded decision.**

## 1. The defending chart

`DefendChart`: facing a 3bb open from seat V, hero (in position behind) has three
bands — **3벳**, **콜**, everything else folds.

Derived, not authored, the same way R2 derived RFI (decisions.md §E): Chen-ranked
slices whose widths scale with **the opener's range width** — the one variable that
dominates IP defense:

- 3벳 band = top `0.30 × openPercent(V)` by Chen.
- 콜 band = from there down to `0.75 × openPercent(V)`.

Sanity anchors (derived values, checked against the free benchmarks the repo already
cites, never copied): vs a ~10% UTG open → 3벳 ~3%, 콜 ~4.5% wide — premiums 3-bet,
strong-but-not-premium calls; vs a ~26% CO open → ~8% 3벳, ~11% 콜, ≈19% total
defense. Both land in the published neighborhoods for in-position defense.

**Stated simplification:** the bands depend only on the opener's seat, not hero's.
Real defense widens slightly as hero's own position improves; that refinement (and
blind defense, where hero is out of position) is future work, disclosed rather than
faked. Constants live in one place and the chart is printable — §B's grid convention,
colour = action: red 3벳, green 콜, grey 폴드.

## 2. The bot facing a 3-bet

One new rule per archetype, in character, no 4-bets (capped to a call the way the
postflop re-raise already is — stated on screen):

| | continues with (top share of his *own opening range*, by Chen) |
|---|---|
| Nit | 0.35 — folds everything but premiums |
| TAG | 0.50 |
| LAG | 0.60 |
| Station | **1.00 — never folds preflop, true to type** |
| Maniac | 0.85 |

Continue = call (v1). The band is a top-slice of the range he opened, so it is
automatically nested and printable, and his 콜 narrows `villainCombos` to exactly
that band — preflop narrowing, same inversion as postflop.

## 3. Grading — the chart is the truth, and it is not in bb

Preflop future-value is exactly what the checkdown model cannot price (that is why
S4 scripted the street). So the preflop decision is graded **against the chart**:
matched band → 최선, wrong band → 빗나감-styled miss naming the chart's action. No
fabricated bb number — the summary line shows the chart verdict where postflop lines
show bb, and the pill offers 차트 보기: the three-band grid with hero's hand ringed.

Folding junk costs nothing real here (blinds are dead money in this format), and the
grade says so: the point of dealing any two cards is that the fold region trains too.

## 4. Machine changes

- New facing: `.open(Double)` — the 3bb open, before any board. Choices: 폴드 /
  콜 3bb / 3벳 9bb (the existing 3× raise rule, one raise cap — so the bot never
  4-bets and hero never faces one).
- Hero fold → hand over, net 0 (nothing invested). Bot fold to the 3-bet → hero
  wins the 4.5bb out there. Bot call → pot 19.5bb, stacks 91bb, flop as today.
- The dealer deals hero **any two cards** — the top-30% band and its "콜할 만한
  핸드만 골라 드려요" script are deleted; that disclosure existed only because the
  street didn't.

## 5. Scope — out

- 4-bets, and hero facing a re-raise preflop.
- Blind defense / hero out of position; hero-seat-sensitive band widths (§1).
- A path drill for the defend chart (a u8 candidate — this slice is the table
  integration; the chart type is built to be reused by that drill).
- Any change to postflop grading.

## 6. Verification

1. **Bands are well-formed** — 3벳 ⊂ defend, disjoint from 콜, both monotone in the
   opener's width; every hand maps to exactly one action.
2. **Anchors pinned** — vs the widest opener the defense is strictly wider than vs
   the narrowest; AA 3-bets everywhere; a junk hand folds everywhere.
3. **The bot's continue band is nested in his open range**, ordered by the §2 shares
   (Nit ⊂ TAG ⊂ LAG ⊂ Maniac ⊂ Station as fractions), and the Station never folds.
4. **Machine**: preflop fold nets exactly 0; bot fold nets +4.5; bot call reaches the
   flop at 19.5bb pot and 91bb stacks; his combo survives his own continue-narrowing;
   accounting still balances on random play-throughs (existing invariant tests run
   the new street for free).
5. **Chart grading is total** — every dealt hand gets a verdict against every seat.
6. **UI sweep** gains the preflop node, its verdict pill and the three-band grid.
