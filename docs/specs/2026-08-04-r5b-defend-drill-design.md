# Revamp R5b — 「디펜드 차트」 on the path (design)

R5 built `DefendChart` for the table. R5b gives it the same treatment every other
chart got: a path drill, so the skill is *trained* where the table merely *uses* it.
The construction is R2's RFI drill with a third answer.

## 1. The drill

A seat opens 3bb; hero holds two cards. **폴드, 콜, or 3벳?** — graded against
`DefendChart.action(for:vsOpenFrom:)`, the exact function the table grades with, so
the drill and the table can never disagree.

Hero's own seat is deliberately absent from the spot: the chart's bands depend only
on the opener's width (R5 §1's disclosed simplification), and staging a hero seat
that changes nothing would imply it does.

**Bands, not binary.** The three actions are ordered (3벳 > 콜 > 폴드), so a miss by
one band — calling what should 3-bet — is 근접, and a miss by two — folding what
should 3-bet — is 빗나감. The same softness every estimation drill has, expressed
ordinally.

**Boundary spots**, like RFI: the generator keeps Chen scores in the window where the
chart has to be *known* rather than guessed, because AA and 72o teach nothing.

## 2. Teaching

The walkthrough derives the chart instead of asserting it: the opener's range (grid),
the two shares applied to its width (action list — 상위 30% → 3벳, 75%까지 → 콜),
then the finished three-band chart with the hand ringed. `BeatFocus` gains a
`.defendChart(opener:highlight:)` case, rendered by the same `DefendGridView` the
table's 차트 보기 uses.

## 3. Curriculum

Unit **u8 「오픈에 맞서기」**, section **상대** — u7 read the opponent's postflop
actions; u8 answers his preflop one.

| node | kind | teaches |
|---|---|---|
| `u8-defend` | drill | `defend` |
| `u8-boss` 「프리플랍 종합」 | boss | `defend` mixed with `rfi`, `rangeNotation`, `combos` |

`defend` is not an estimation concept — the answer is one of three words.

## 4. Verification

1. Grade bands follow the ordinal distance: exact 정확, one off 근접, two off 빗나감.
2. Generation is deterministic and boundary-biased; every spot's opener is a seat
   that can be opened from.
3. The reveal derives its numbers from the same constants the chart uses — the
   opener's width and both shares appear in the text.
4. Wiring: 18th concept, taught by exactly one node, not estimation; the walkthrough
   ends on the chart verdict and never leaves the felt empty.
5. UI sweep gains the drill, its reveal and the chart beat.
