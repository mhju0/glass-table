# Milestone 1, Part 2 — App Spine + Outs Drill (Design Spec)

> **Status:** Approved design, ready for implementation planning.
> **Date:** 2026-07-22
> **Sub-project 1 of 4** in the Math Drills app (after the engine core, `docs/plans/2026-07-21-m1-engine-core.md`). Later sub-projects: (2) the other four drills, (3) polish — full Korean glossary + progress/stats screen + app icon + study-tool visual tone, (4) App Store + GRAC submission.

## Goal

Build the **first vertical slice** of the Math Drills app: a SwiftUI iOS app that runs the **Outs & rule-of-2/4** drill end-to-end — deal a spot → estimate → commit → reveal + grade → next — on top of the already-proven `GlassTableEngine`. The point is to de-risk the *entire* Swift/SwiftUI pipeline (app builds, engine links, the decide→grade loop works, grading renders, progress persists) before replicating across the remaining four drills.

Success = the loop runs in the simulator, grades correctly against the engine, looks clean/modern (Toss-inspired), and the non-UI logic is covered by fast `swift test` unit tests.

## Scope

**In:**
- An Xcode SwiftUI iOS app target `GlassTable` (iOS 17+).
- A `swift test`-able Swift package `GlassTableDrills` (depends on `GlassTableEngine`) holding all non-UI logic.
- The **Outs drill**: procedural seeded spot generation with a quality filter; the decide→reveal→grade loop; estimation-band grading; rule-of-2/4 display; a templated "why".
- Minimal **local progress** (per-drill streak + accuracy) persisted to disk.
- A reusable **Toss-inspired design system** (tokens + SwiftUI primitives + the shared screen scaffold) so every future screen is consistent.

**Out (deferred to later sub-projects):**
- The other four drills (pot odds, call/fold, MDF, blockers).
- Full Korean glossary/copy pass, a progress/stats screen, app icon, App Store + GRAC submission.
- Difficulty tiers (excluding vs. allowing "tainted" outs), richer per-spot explanations, SwiftData.

## Architecture

Three layers, boundaries chosen so the risky logic stays CLI-fast-testable and the UI is a thin shell:

```
GlassTableEngine   (existing SPM package — pure poker math, fully tested)
      ▲
GlassTableDrills   (new SPM package — pure app-domain logic, no SwiftUI/UIKit → swift test-able)
      ▲
GlassTable         (Xcode iOS app target — SwiftUI views + design system, thin shell)
```

- **`GlassTableDrills`** imports `GlassTableEngine`. Contains: `OutsSpot`, `OutsSpotGenerator`, `DrillSession`, `Reveal`, grade mapping, and the `Progress` model + persistence. No Apple-UI imports, so it runs under `swift test` (fast, no simulator) — matching the engine's discipline.
- **`GlassTable`** app imports both packages as **local package dependencies** and renders SwiftUI. It owns only views, the design system, and app lifecycle.

**State model (unidirectional).** `DrillSession` is an `@Observable` (Observation framework) with an explicit phase:

```
enum Phase {
    case deciding(spot: OutsSpot, estimate: Int)
    case revealed(spot: OutsSpot, estimate: Int, result: Reveal)
}
```

Views render the current phase and send intents: `adjustEstimate(delta:)`, `commit()`, `next()`. No two-way bindings into model internals; the view reads state and calls intents.

## Modules & data flow

**Data flow:**
```
seed → OutsSpotGenerator.generate() → OutsSpot
     → (engine countOuts already embedded in the spot)
     → user adjusts estimate (stepper)
     → commit() → engine gradeEstimate → Reveal
     → Progress.record(band) → persist
     → next() advances the seed → new OutsSpot
```

**`OutsSpot`** (value type):
- `hero: [Card]` (2), `villain: [Card]` (2), `board: [Card]` (4, a turn).
- `outs: [Card]` — the exact winning river cards (from engine `countOuts`).
- `outCount: Int` (= `outs.count`), `improvementPct: Double` (= engine `ruleOf2or4(outs: outCount, cardsToCome: 1)`).
- `excluded: [Card]` — **best-effort** "looks like an out but isn't" cards, for the strike-through and "why". Bounded heuristic: when hero holds four to a flush, the remaining cards of that suit that are **not** in `outs` (they'd complete the flush but lose — e.g. they pair the board into villain's full house). Empty when the spot has no such draw; the reveal simply shows no struck cards then.

**`OutsSpotGenerator`** — procedural, seeded, deterministic:
1. Seed a shuffle of `Deck.all` using the engine's `SplitMix64`.
2. Draw hero (2), villain (2), turn board (4).
3. Compute `countOuts(hero:villain:board:)`.
4. **Quality filter — accept only if `2 ≤ outCount ≤ 15`.** This window *is* the operational definition of "behind and drawing": a large out-count means hero already wins on most rivers (already ahead), zero means drawing dead — both excluded. This avoids needing a 6-card turn-standing comparison the engine doesn't provide. Reject-and-redraw with a bounded attempt cap (e.g. 200); if the cap is ever hit, widen the window by one each cap-cycle so generation can never hang.
5. Determinism: `spot(index:)` derives its seed from `(baseSeed, index)`, so the same session seed replays the same sequence — a given spot always grades identically (satisfies `decisions.md` §2 determinism).

**`DrillSession`** — holds `baseSeed`, current index, current `Phase`, and a `Progress`. `commit()` grades and transitions to `.revealed`; `next()` increments the index, generates the next spot, returns to `.deciding`.

**`Reveal`** (value type): `band: GradeBand`, `correctOuts: [Card]`, `excluded: [Card]`, `improvementPct: Double`, `whyText: String`.

## Grading

- **Estimation bands (integer outs)** via engine `gradeEstimate(user:correct:closeWithin:spotOnWithin:)` with `spotOnWithin: 0`, `closeWithin: 2`:
  - `정확` (spot-on) = exact count.
  - `근접` (close) = off by 1–2.
  - `빗나감` (off) = off by 3+.
  - Thresholds are tunable constants.
- **Rule of 2/4:** river = one card to come → `ruleOf2or4(outs: outCount, cardsToCome: 1)` = `outCount × 2`, shown as "≈ N% 개선" on reveal (not separately estimated by the user — it's a formula on the count, so one clean input).
- **"Why" text (templated):** base "N 아웃"; if the spot has excluded/tainted cards, append a plain-Korean reason (e.g. "2♥·3♥는 보드를 페어시켜 상대가 풀하우스 — 제외"). Full copy polish is a later sub-project.

## Visual design system (Toss-inspired)

The consistency layer. Derived from the Toss Design System (borderless, flat color layering, generous whitespace, Pretendard type). Reference mockups: `.superpowers/brainstorm/.../outs-toss-redesign.html` (loop) and `outs-decide-zones.html` (D1 decide layout).

**Layout pattern (app-wide):** every drill/reveal screen = **green content zone on top** (the spot / cards) + **white action sheet on the bottom** (question + input, or grade + Next), corners `radius 24` where the sheet meets the green. This pairing is the app's signature and is reused everywhere.

**Tokens:**
- Brand green (felt/primary): `#157A47`. CTA green: `#0FA968`.
- Text: primary `#191F28`, secondary `#4E5968`, muted `#8B95A1`.
- Surface (grey fill for "why" boxes etc.): `#F2F4F6`.
- Card faces: white, red suits `#E5484D`, black suits `#191F28`, `radius 7`, soft shadow (no border).
- Grade pills (soft semantic tints): 정확 `#E7F7EF`/`#12864E`; 근접 `#FEF0DA`/`#C77700`; 빗나감 `#FDECEC`/`#D23B3B`.
- Type: **Pretendard** bundled (SIL OFL), weights 400/600/700. Titles 700, body 400/600, near-black on white.
- Radius 14–24; spacing scale 4/8/16/24.
- **No hard 1px borders** — separate content with fills, whitespace, and tonal zones.

**Reusable SwiftUI primitives:** `PlayingCardView`, `SectionLabel`, `PrimaryCTAButton`, `GradePill`, `Stepper`-style estimate control, and `DrillScaffold` (the green-zone + white-sheet container). The Outs screens compose these; future drills reuse them unchanged.

## Persistence

`Progress` — per-drill `streak: Int` and `accuracy` (counts of each band, or correct/total). `Codable`, saved as JSON in Application Support (`FileManager`), loaded at launch, written on each grade. SwiftData is deferred to the stats-screen sub-project — a single counter doesn't warrant it (YAGNI).

## Testing

- **`GlassTableDrills` (`swift test`, fast, no simulator):**
  - Generator determinism — same `(baseSeed, index)` → identical `OutsSpot`.
  - Quality-filter invariant — every generated spot has `2 ≤ outCount ≤ 15`; generation always terminates (window-widening fallback honored, never hangs).
  - Grade-band mapping — exact→정확, ±2→근접, ≥3→빗나감.
  - `Progress` persistence round-trip (encode → decode preserves streak/accuracy).
  - Spot correctness — `outs` matches an independent `countOuts` call (guards against wiring bugs).
- **`GlassTable` app:** SwiftUI `#Preview`s for `.deciding` and `.revealed`. Optional `xcodebuild test` launch/loop smoke test (advance one spot, assert phase transition) — nice-to-have for the slice.
- **Engine:** already fully tested (31 tests, eval7 oracle).

## Confirmed decisions

- Vertical slice first; **Outs** drill leads.
- **Procedural seeded generation + quality filter** (pattern reused by later drills).
- Outs framed as **"river cards that beat the shown villain"** (uses `countOuts`; villain cards visible).
- **Decide layout D1** (green spot zone + white answer tray); reveal = grade sheet. Green-top/white-bottom is the app-wide pattern.
- **Toss-inspired, borderless** visual language; Pretendard bundled now.
- `GlassTableDrills` as a **separate testable package**; grade bands **exact / ±2 / else**.
```
