# M1 Part 3: Four remaining drills + home navigation — Design

**Goal:** Add the four remaining drills — 팟 오즈 (pot odds), MDF, 콜/폴드 (call/fold vs price), 블로커 (blockers) — behind a Toss-style home screen, with per-drill progress. Everything rides on the sub-project-1 spine: `DrillScaffold`, `PlayingCardView`, `EstimateStepper`, `GradePill`, `PrimaryCTAButton`, the engine's math, and the seeded-generation pattern.

## 1. Shared changes (GlassTableDrills + app)

### Generic `DrillSession`

The in-progress estimate moves out of the session into view `@State` (it is UI state). What remains is one phase machine shared by all five drills:

```swift
public protocol GradedReveal: Equatable { var band: GradeBand { get } }

public struct DrillSession<Spot: Equatable, Answer, Reveal: GradedReveal> {
    public enum Phase: Equatable {
        case deciding(spot: Spot)
        case revealed(spot: Spot, reveal: Reveal)
    }
    public let baseSeed: UInt64
    public private(set) var index: Int
    public private(set) var phase: Phase
    public private(set) var progress: DrillProgress

    public init(baseSeed: UInt64, progress: DrillProgress = DrillProgress(),
                generate: @escaping (UInt64, Int) -> Spot,
                grade: @escaping (Answer, Spot) -> Reveal)
    public mutating func commit(_ answer: Answer)  // grade → record progress → .revealed
    public mutating func next()                    // index += 1 → .deciding
}
```

- The session loses `Equatable` (it holds closures); `Phase` stays `Equatable`.
- Each drill's `Reveal` struct carries the user's answer (for the "내 답" line) and conforms to `GradedReveal`. `Reveal` (outs) gains an `estimate: Int` field and is renamed `OutsReveal` for symmetry; `gradeOuts` signature is unchanged.
- The Outs drill migrates onto the generic session; `DrillSessionTests` adapt (estimate clamping is now the stepper's range, tested implicitly by view config).

### Per-drill progress

`ProgressStore.standard()` becomes `standard(drill: String)` → `<drill>-progress.json` in Application Support. Slugs: `outs`, `potodds`, `mdf`, `callfold`, `blockers`. Outs keeps its existing file name (`outs-progress.json`) — no migration.

### Generic app model + navigation

- `OutsDrillModel` becomes `DrillModel<Spot, Answer, Reveal>` (@Observable, generic): wraps the session + store, exposes `phase`, `streak`, `commit(_:)`, `next()`.
- `RootView` becomes `NavigationStack { HomeView }`. `HomeView`: app title + one Toss-style row per drill (Korean name, 🔥 streak, accuracy %, chevron), values loaded from each drill's `ProgressStore` on appear. Tap pushes the drill's container view, which switches decide/reveal on `model.phase` (as `RootView` does today). Back returns home; row stats refresh on return.
- Debug hook extends: `GT_DEMO_DRILL=<slug>` auto-opens that drill; `GT_DEMO_REVEAL=<n>` advances to spot *n* and commits the drill's default answer (for state screenshots).

## 2. The four drills

All spot generation follows the `OutsSpotGenerator` pattern: `SplitMix64`-seeded, deterministic in `(baseSeed, index)`, quality filter with reject-and-redraw. Bet sizings come from the decisions.md §A menu: **33 / 50 / 75 / 100 / 150% of pot**. Amounts are in bb (integers). Engine convention: `requiredEquity(toCall:pot:)`'s `pot` **includes villain's bet** — display shows pot-before-bet, so the call is `requiredEquity(toCall: bet, pot: pot + bet)`.

### 팟 오즈 (pot odds) — `potodds`

- **Spot** `BetSpot { pot: Int, bet: Int }` (shared with MDF): pot sampled from {6, 8, 10, 12, 15, 20, 24, 30} bb; fraction from the sizing menu; `bet = max(1, Int((fraction × pot).rounded()))`.
- **Decide:** green zone shows "팟 \(pot) · 벳 \(bet)" (no cards); question "콜하려면 에퀴티가 몇 % 필요할까요?"; `EstimateStepper` 0–100, ±5, start 50; CTA 확인하기.
- **Truth:** `requiredEquity(toCall: bet, pot: pot + bet) × 100`. Answers land near the canonical five: 20 / 25 / 30 / 33.3 / 37.5% — that recognition is the drill's point.
- **Grade:** `gradeEstimate(user:correct:closeWithin: 7.5, spotOnWithin: 2.5)` — on the 5% grid: nearest step = 정확, one step off = 근접.
- **Reveal why:** the fraction spelled out, e.g. "벳 5 ÷ (팟 10 + 벳 5 + 콜 5) = 25%".

### MDF — `mdf`

Same `BetSpot`, same sampling, same stepper and bands. Question: "최소 몇 %는 폴드하지 않아야 할까요?" Truth: `mdf(bet: bet, pot: pot) × 100` (canonical five: 40 / 50 / 57.1 / 66.7 / 75%). Reveal why: "팟 10 ÷ (팟 10 + 벳 5) = 67%".

Pot odds and MDF share one SwiftUI view (`PercentDrillView`) parameterized by a small config (title, question, why builder, store slug) — they differ only in copy and grade function.

### 콜/폴드 (call/fold) — `callfold`

- **Spot** `CallFoldSpot { hero, villain: [Card](2), board: [Card](4), pot: Int, bet: Int, equityPct: Double }`: seeded deal (hero + face-up villain + turn board) plus a `BetSpot`-style price. Filter: hero equity via `exactEquityHeadsUp` (44 rivers, cheap) kept within **5–95%**; reject-and-redraw otherwise.
- **Decide:** green zone shows villain (face-up), board, hero rows — same layout grammar as Outs — plus "팟 \(pot) · 벳 \(bet)". Question: "콜해야 할까요?" Input: two full-width buttons **콜 / 폴드** (no stepper; tapping commits).
- **Truth:** `callIsProfitable(equity: equity, toCall: bet, pot: pot + bet)`.
- **Grade:** `gradeBinary` → 정확 / 빗나감 (no 근접).
- **Reveal why:** "에퀴티 32% vs 필요 25% → 콜" (both percentages to one decimal or whole, from the actual spot).

### 블로커 (blockers) — `blockers`

- **Spot** `BlockerSpot { rankA, rankB: Int, kind: ComboKind, removed: [Card], count: Int }`: ranks sampled from T–A (10–14); `kind` ∈ {pair (when rankA == rankB), any, suited} — offsuit deferred (it's `any − suited`, more confusing than instructive). `removed` = 2–4 seeded cards; filter: at least one removed card's rank ∈ {rankA, rankB} (so the answer differs from the baseline). `count = comboCount(...)`.
- **Decide:** green zone shows the removed cards labeled "제거된 카드" (hero hand and/or board cards); question "남은 \(className) 콤보는 몇 개?" where className is "QQ" / "AK" / "AKs" (decisions.md: acronyms Latin). Stepper 0–16, ±1, start at the class baseline (pair 6, any 16, suited 4).
- **Grade:** `gradeEstimate(closeWithin: 2, spotOnWithin: 0)` — same bands as Outs.
- **Reveal why**, per kind, from remaining-card counts: pair "Q \(n)장 남음 → \(n)×\(n−1)÷2 = \(count)"; any "A \(na)장 × K \(nb)장 = \(count)"; suited "양쪽 다 남은 무늬 \(count)개".

## 3. Grading bands (summary)

| Drill | Input | 정확 | 근접 | 빗나감 |
|---|---|---|---|---|
| 아웃 (existing) | int ±1 | exact | ±2 | else |
| 팟 오즈, MDF | % ±5 | ≤2.5 | ≤7.5 | else |
| 콜/폴드 | 콜/폴드 buttons | correct | — | wrong |
| 블로커 | int ±1 | exact | ±2 | else |

Progress semantics unchanged: streak counts consecutive non-빗나감, accuracy counts 정확 only.

## 4. File structure

**GlassTableDrills** — new: `BetSpot.swift` (spot + both generators + both grades + both reveals), `CallFold.swift`, `Blocker.swift`. Modified: `DrillSession.swift` (generic), `Reveal.swift` (`OutsReveal` + estimate field + `GradedReveal`), `Progress.swift` (`standard(drill:)`).
**GlassTable app** — new: `Screens/HomeView.swift`, `Screens/PercentDrillView.swift`, `Screens/CallFoldView.swift`, `Screens/BlockerView.swift`. Modified: `RootView.swift` (NavigationStack), `OutsDrillModel.swift` → `DrillModel.swift` (generic), Outs decide/reveal views (session API change), `Components.swift` (add a neutral secondary variant of `PrimaryCTAButton` — 폴드 renders neutral, 콜 renders the existing green).

## 5. Testing

`GlassTableDrills` (`swift test`, debug is fine — no heavy enumeration): per-generator determinism (same seed+index → same spot) and filter invariants (equity 5–95, ≥1 relevant removed card, bet ≥1); grade-band mapping including the 33.3→35 정확 edge; why-text content checks; generic-session commit/next/progress round-trip (Outs instantiation); `standard(drill:)` file naming. App: `xcodegen generate` + simulator build + one screenshot per drill via the debug hook.

## 6. Out of scope (committed roadmap, not dropped)

Sub-project 3 — **committed by Michael 2026-07-22**: Korean glossary polish, stats screen, app icon, study-tool visual tone. Sub-project 4: App Store + GRAC submission. Deferred beyond M1: difficulty tiers, richer why-copy, SwiftData. Tracked in `docs/milestone-1.md` ("Rough shape") and agent memory.
