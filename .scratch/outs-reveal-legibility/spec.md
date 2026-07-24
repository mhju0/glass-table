# Outs drill: card legibility + full-table reveal + tap-to-explain

Status: ready-for-agent

## Problem

Cards are too small for the app's beginner audience — the reveal screen renders
hero/villain at 30pt and outs at 34pt (smallest in the app), and it doesn't show
the board at all, so a learner can't see *why* an out wins. The decide screen's
42pt default also has huge unused headroom (a 5-card row fits ~85pt on the
smallest supported iPhone).

## Design (approved 2026-07-24)

### 1. Engine — public best-hand summary

`evaluate7`'s key already encodes category (top base-16 slot) and the deciding
rank (next slot). Expose:

```swift
public struct HandBrief: Equatable {
    public let category: Int  // 0=high card … 8=straight flush
    public let topRank: Int   // pair rank, trip rank, straight/flush high card …
}
public func bestHand(_ seven: [Card]) -> HandBrief
```

Pure arithmetic on the existing key (`key >> 20`, `(key >> 16) & 0xF`). No new
evaluator logic.

### 2. Drills — per-river explanation + Korean hand names

```swift
public struct RiverExplanation: Equatable {
    public let hero: HandBrief
    public let villain: HandBrief
    public let heroWins: Bool   // river ∈ spot.outs — no re-comparison needed
}
public func explainRiver(spot: OutsSpot, river: Card) -> RiverExplanation
public func handName(_ b: HandBrief) -> String  // "A 원 페어", "K 하이 플러시", "로열 플러시"
```

Computed on tap (2× `bestHand`); no precomputation. Korean strings live in
Drills next to the existing `whyText`. Rank display uses card-letter ranks
(A/K/Q/J/10/…), matching `PlayingCardView`.

### 3. Design system — adaptive `CardRow`, adopted app-wide

`CardRow(cards:dead:)` built on `ViewThatFits(in: .horizontal)`: tries card
size 64 → 56 → 48 → 40, keeps the largest that fits. No GeometryReader; shrinks
automatically when future multi-way layouts add cards. Adopted by DecideView,
CallFoldView, BlockerView (replacing their local 42pt rows).

### 4. RevealView — full table, bigger tappable outs, inline explain panel

- Content mirrors DecideView: 상대 / 보드 · 턴 / 내 핸드 sections via `CardRow`.
- Outs + excluded grids: `LazyVGrid(.adaptive(minimum: 38))`, card size 52
  (up from 34). Outs label gains a "눌러서 확인" affordance hint.
- Tapping any out/excluded card rings it and shows an inline panel below the
  grids: board + tapped river (ringed) at 40pt, then
  `내 핸드 · A 하이 플러시` / `상대 · Q 풀하우스` / verdict line
  (`→ 내가 이겨요` / `→ 완성해도 상대가 더 강해요`). Tap again to dismiss.
- Content wraps in a ScrollView (21-out spots at 52pt won't fit an SE), with
  ScrollViewReader auto-scroll so the panel is visible after a tap.
- Grade pill / whyText / CTA sheet unchanged.

## Out of scope

- Highlighting the exact best five cards (hand name answers "why").
- Precomputing all 21 explanations.
- Multi-player table layouts (CardRow's size ladder is the hook).

## Steps (checkpoint commit each)

1. Engine `bestHand` + release-mode tests.
2. Drills `explainRiver` + `handName` + tests.
3. `CardRow` component; adopt in Decide/CallFold/Blocker; build + screenshot.
4. RevealView full-table layout + tap panel; build + screenshots.
