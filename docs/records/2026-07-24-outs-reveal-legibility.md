# Outs drill: card legibility, full-table reveal and tap-to-explain

- **Date:** 2026-07-24
- **Kind:** spec notes
- **Originals:** `.scratch/outs-reveal-legibility/spec.md` (tracked: `git show f5c5e22:.scratch/outs-reveal-legibility/spec.md`)
- **Asked by / for:** design approved 2026-07-24 [Unknown who asked]

## What it was
Spec for larger cards in the outs drill, a reveal that shows the whole table, and a
tap-to-explain panel per river card.

## Findings and decisions
- Problem: reveal rendered hero/villain at 30pt and outs at 34pt (smallest in the app)
  and did not show the board, so a learner could not see why an out wins. The decide
  screen's 42pt default had unused headroom (a 5-card row fits ~85pt on the smallest
  supported iPhone).
- Engine: `public struct HandBrief { category: Int (0=high card … 8=straight flush);
  topRank: Int }` and `public func bestHand(_ seven: [Card]) -> HandBrief`, pure
  arithmetic on the existing `evaluate7` key (`key >> 20`, `(key >> 16) & 0xF`).
- Drills: `RiverExplanation { hero, villain: HandBrief; heroWins: Bool }` (heroWins =
  river ∈ spot.outs), `explainRiver(spot:river:)` computed on tap (2x `bestHand`), and
  `handName(_:)` ("A 원 페어", "K 하이 플러시", "로열 플러시") next to `whyText`, using card
  letter ranks like `PlayingCardView`.
- Design system: adaptive `CardRow(cards:dead:)` on `ViewThatFits(in: .horizontal)`,
  sizes 64 → 56 → 48 → 40, largest that fits, no GeometryReader. Adopted by DecideView,
  CallFoldView, BlockerView (replacing local 42pt rows).
- RevealView: 상대 / 보드 · 턴 / 내 핸드 sections via `CardRow`; outs and excluded grids
  `LazyVGrid(.adaptive(minimum: 38))` at card size 52 (up from 34) with a "눌러서 확인"
  hint. Tapping a card rings it and shows an inline panel: board + tapped river (ringed)
  at 40pt, `내 핸드 · A 하이 플러시` / `상대 · Q 풀하우스` / verdict (`→ 내가 이겨요` or
  `→ 완성해도 상대가 더 강해요`); tap again to dismiss. ScrollView with ScrollViewReader
  auto-scroll (21-out spots at 52pt do not fit an SE). Grade pill, whyText and CTA sheet
  unchanged.
- Out of scope: highlighting the exact best five, precomputing all 21 explanations,
  multi-player layouts (CardRow's ladder is the hook).
- Steps, a checkpoint commit each: engine + release tests; Drills + tests; CardRow
  adoption + screenshot; RevealView + screenshots.

## Outcome
Shipped 2026-07-24, commits `d05dcff` (engine `bestHand`) through `551cf4f` (full-table
reveal); spec marked done in `e9e57a0`. The Hold'em basics spec (2026-09-25)
reuses the engine's `bestHand`.

## Still open
Nothing.
