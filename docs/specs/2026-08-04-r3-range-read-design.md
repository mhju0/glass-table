# Revamp R3 — Range Read (design)

Third slice (`2026-08-03-r1-progression-shell-design.md` §1). The mode the brief calls
the strongest differentiator, and the one no surveyed competitor ships.

## 0. What it is

You see **only the betting actions** — no cards — then mark what you think the villain
holds. Scored against that archetype's **declared** range.

This is the thesis made literal. `product-brief.md`: opponents are archetypes with
published, inspectable strategies, so "what does his call mean?" has a correct answer
that can be graded numerically instead of hand-waved. Every other trainer either
grades against a solver (opaque) or a neural bot that will not tell you what it had.

## 1. The input — decided

**Width slider plus tendency chips.** No cell painting.

A grid cell is ~24pt on the narrowest supported screen, against a 44pt touch minimum,
so painting needs a magnifier — but the deeper reason is that **cell-perfect painting
is false precision for a read**. Grading is overlap against a declared range; marking
someone down for missing K7s when they had the shape right teaches nothing.

So the input is deliberately coarse, and its controls are the vocabulary a player
already uses out loud:

- **Width** — one slider, "he calls about 20% there". The grid fills by strength as it
  moves, so the abstraction stays visible.
- **Tendency** — chips that tilt the *shape*: 페어 많이 · 수티드 많이 · 오프수트
  브로드웨이 · 커넥터. These express the reads that actually matter ("wide, but only
  suited stuff") without ever asking for a small target.

A tendency re-weights the Chen ranking before the cut rather than adding cells
afterwards, so the result is always a coherent "top N% under this preference" rather
than a shape with holes punched in it.

**Exact painting is not cut, only deferred.** Drag-with-loupe is the right tool for
Lab-style authoring later, behind a 정확히 칠하기 affordance. It is the wrong thing for
a learner to meet first, because it makes range reading feel like pixel art.

## 2. Archetypes

Five, with the VPIP/PFR already settled in `decisions.md` §C:

| | VPIP | PFR | character |
|---|---|---|---|
| Nit | 12 | 9 | tight-passive |
| TAG | 20 | 17 | tight-aggressive |
| LAG | 27 | 22 | loose-aggressive |
| Calling Station | 40 | 10 | loose-passive |
| Maniac | 55 | 40 | loose + hyper-aggressive |

Ranges are **derived from those two numbers**, the same way R2's charts are derived
from a seat: raise with the top PFR% by Chen, call with the band between PFR% and VPIP%
— the hands good enough to play but not to raise. The defining discriminator is the
VPIP−PFR gap, which is exactly what that construction encodes: tiny for TAG and LAG,
enormous for the Station.

Position still applies. An archetype's numbers are its *average* across seats, so each
seat's width scales by the same players-behind factor R2 uses, normalised so the
average across seats returns the declared VPIP/PFR.

**Every range the app grades against is printable in-app**, which is the whole
transparency claim: the reveal shows the archetype's declared rule, the resulting grid,
and where your estimate differed.

## 3. Grading

**Combo-weighted Jaccard**: |A ∩ B| ÷ |A ∪ B|, counting combos rather than classes,
since a pair is 6 and an offsuit class is 12.

Bands (estimation-style, not pass/fail — spec §5.4's rule that "근접" is honest where
the answer is genuinely an estimate):

| overlap | band |
|---|---|
| ≥ 0.70 | 정확 |
| ≥ 0.45 | 근접 |
| < 0.45 | 빗나감 |

The reveal names *how* it differed — too wide, too tight, right width but wrong shape —
because "0.52" teaches nothing on its own. Direction is computable: compare widths
first, then, at similar widths, which tendency the truth had that the guess did not.

## 4. Scope — in

- `Archetype` and its derived ranges, in `GlassTableDrills` (position lives there).
- `HandRange.shaped(width:tendencies:)` in the engine — the input's output.
- Jaccard scoring.
- Preflop only: villain opens, or villain calls an open. One decision point.
- The Range Read screen: action list, grid, slider, chips, reveal.
- A new unit 4 「레인지 리드」.

## 5. Scope — out

Postflop range narrowing (needs the board-texture classifier, which is R4's bot work).
Multi-street action. Exact cell painting. Multiway beyond one villain. The Table mode.

## 6. Verification

1. **Archetype ranges are internally consistent** — raise ⊂ play, the raise/call split
   reproduces the declared VPIP and PFR within a point, and averaging each seat's width
   returns the archetype's headline number.
2. **The Station is separable from TAG by shape, not just width** — its VPIP−PFR gap
   must produce a call range several times wider than its raise range, or the archetype
   is not modelling anything.
3. **Shaped ranges are coherent** — `shaped(width:tendencies:)` always returns
   approximately the requested width, and a tendency measurably raises that category's
   share without leaving holes.
4. **Jaccard is combo-weighted** — property-tested against brute force over combos, and
   identical ranges score exactly 1.
5. **Every archetype range is printable and re-parsable**, so what the reveal shows is
   what was graded.
6. **UI sweep** — `tools/uisweep.sh` gains the Range Read screens.

## 7. Open questions — resolved 2026-08-04

1. **Does the user pick the archetype, or is it hidden?** **Named early, hidden later,
   as a difficulty band.** The first three spots always name the opponent; after that
   it is named two times in three. A hidden archetype renders as 「모르는 상대 · 어떤
   사람인지도 액션으로 판단해야 해요」 rather than a blank, so the missing name reads as
   part of the question instead of a bug.
2. **Do tendency chips stack?** **Yes.** The re-weighting stays explicable because
   bonuses are added to the Chen score *before* the cut, so any combination is still
   "the top N% under this preference" — never a shape with holes. Pinned by
   `testShapedRangesHaveNoHoles`.

## 8. Saturation — found during implementation

A tendency is a *preference*, and once a category lies entirely inside the cut there is
nothing left to prefer. Pairs are 78 of 1326 combos (5.9%) and offsuit broadways 120
(9%), so both are fully contained well before a loose range: at 30% width the 페어 and
오프수트 브로드웨이 chips change the resulting grid **not at all**.

This is correct behaviour, but a control that silently does nothing reads as broken. So
it is surfaced rather than hidden: `RangeTendency.isSaturated(atWidth:)` is public, and
a saturated chip is labelled 「이 넓이엔 이미 전부 포함」 under its name. The first
version of the test asserted every tendency bites at one fixed width and failed for
exactly this reason; it now asserts each tendency bites *somewhere*, never lowers its
own share, and that the saturation itself holds.

## 9. Grid comparison

Two 13×13 grids side by side on a 12 mini is ~12pt a cell, and a third fill colour
would be neither legible nor colour-blind-safe. The reveal instead draws one grid with
**two independent channels**: fill = the true range, ring = your estimate. Filled and
ringed is agreement, filled only is a miss, ringed only is over-inclusion — readable in
greyscale, with a printed legend.
