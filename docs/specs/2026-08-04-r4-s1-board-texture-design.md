# Revamp R4-S1 — Board texture and range-vs-board (design)

R4 in the slice table (`2026-08-03-r1-progression-shell-design.md` §1) is
**"Archetype bots + Table"**, which unlocks Block C and is where "advanced" stops
being a promise. It is far too large for one spec.

## 0. R4 decomposition

Four sub-projects, in dependency order. Each ships on its own.

| | Sub-project | Ships | Needs |
|---|---|---|---|
| **S1** | **Board texture + range-vs-board** (this spec) | 히트 프리퀀시 ★ · 레인지 어드밴티지 ★ | — |
| S2 | EV-loss grading | The grading model Block C requires | S1 |
| S3 | Archetype postflop policy (the bot) | An opponent that acts after the flop | S1 |
| S4 | Table mode | Play a whole hand against a bot | S1–S3 |

S1 first because **everything postflop asks the same question** — what does a range do
on this board — and because it alone ships two of the ★ exercises no surveyed
competitor has, with no bot needed. A bot built before this primitive would be
guessing about the boards it plays.

## 1. The primitive

`RangeOnBoard`: take a `HandRange` and a 3–5 card board, drop every combo the board
blocks, classify what remains, and weight by combos.

Five buckets. Fewer would not distinguish a decision; more would split hands a learner
does not yet play differently:

| bucket | Korean | what it is |
|---|---|---|
| `air` | 노페어 | worse than a pair, and no draw |
| `draw` | 드로우 | worse than a pair, but a flush or straight draw |
| `weakPair` | 약한 페어 | a pair, but not of the top board card |
| `topPair` | 탑 페어 | pairs the top board card — **or an overpair** |
| `strong` | 투페어 이상 | two pair or better |

Two rules keep the classification total and unambiguous:

1. **The made hand decides the bucket. `draw` applies only when the made hand is worse
   than a pair.** A flopped set with a flush draw is `strong`, not `draw`. Any other
   rule needs a tiebreak table nobody can hold in their head.
2. **An overpair counts as `topPair`.** It is stronger, and at the street where that
   difference changes an action it is S2's problem, not a hit-frequency bucket's.

Two numbers fall out, and both are named rather than one standing in for the other:
`hitRate` is anything but `air` (it counts draws), and `pairOrBetter` is a made pair or
better. The drill grades on **`pairOrBetter`**, because that is the number a bet
actually turns on; the reveal shows both.

## 2. Draws, computed not guessed

- **Flush draw** — exactly four cards of a suit. Five is a made flush, which the
  category already caught.
- **Straight draw** — for each rank 2–14, ask whether adding it completes a straight.
  The count of such ranks is the classification: **2 or more → 오픈엔드**, exactly one
  → **것샷**, zero → none.

Deriving open-ended from the number of completing ranks rather than from "are the four
cards consecutive" gets the awkward cases right for free: 6-7-8-9 has two completing
ranks, A-2-3-4 has one because the ace is already the low end, and J-Q-K-A has one.

## 3. Board texture

`BoardTexture`, all derived: `isPaired`, suitedness (레인보우 / 투톤 / 모노톤 by the
largest suit count), `highCard`, and `straightiness` — how many of the ten five-rank
straight windows the board already has three of. A one-line Korean summary is built
from those, so the drill never authors a description of a board it generated.

## 4. Range versus range

`rangeEquity(hero:villain:board:)`, needed by 레인지 어드밴티지.

**Fixed-seed Monte Carlo over (hero combo, villain combo, runout) triples.** Exact
enumeration on a flop is 990 runouts × ~200 × ~200 combo pairs ≈ 40M showdowns once
card collisions are handled per pair, which they must be — a hero and a villain cannot
hold the same card. Sampling makes collisions trivial to reject and puts the cost at
two evaluations per sample.

At 20,000 samples the standard error is ≈0.35 percentage points. The drill's tolerance
bands are an order of magnitude wider, so the approximation is invisible to grading,
and the fixed seed makes it reproducible in tests. This is stated in-app rather than
hidden: the reveal says the number is sampled.

## 5. The two drills

**히트 프리퀀시** — a board plus a named range ("UTG 오픈 레인지"). *What share of this
range has a made pair or better?* (`pairOrBetter`, not `hitRate` — see §1.) An estimate, so it takes a point plus a 90% interval and
scores by the Winkler rule — the same treatment 에퀴티 감각 gets, and it feeds the same
calibration screen.

**레인지 어드밴티지** — two ranges on one board, typically an opener against a caller.
*Whose range does this board favour, and by how much?* Answered as an equity split.
Also estimation-graded.

Both reveals show the **full bucket breakdown for both ranges**, because the number is
not the lesson — "A-high boards favour the opener because only he has AA, AK and AQ" is
the lesson, and that is visible only as a distribution.

## 6. Scope — out

Postflop betting decisions, c-bet sizing, EV-loss grading (S2). The bot (S3). The Table
(S4). Turn and river texture *changes* — S1 classifies a board, it does not narrate how
the turn changed it.

## 7. Verification

1. **Bucketing is total and exclusive** — every combo of every range on any board lands
   in exactly one bucket, and the five shares sum to 1.
2. **Draws are checked against the engine** — a hand classified as an eight-out draw
   must have its completing ranks agree with a brute-force count over the deck.
3. **Known boards give known answers** — hand-checked fixtures: a monotone board, a
   paired board, and a board where a range has zero `strong` hands.
4. **Range equity is symmetric and sums to one** — `rangeEquity(a, b) + rangeEquity(b, a)`
   is 1 within sampling error, and a range against itself is 0.5.
5. **Monte Carlo is deterministic** — same seed, same answer, every run.
6. **Sampling error is bounded** — on a complete (river) board, where exact enumeration
   is cheap, the sampled number must agree with the exact one inside the stated bound.
7. **Engine release gate**, since all of this is engine code.
8. **UI sweep** gains both screens.
