# M1 Part 3: Four Remaining Drills + Home Navigation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 팟 오즈, MDF, 콜/폴드, and 블로커 drills behind a Toss-style home screen with per-drill progress, per `docs/specs/2026-07-22-m1-four-drills-design.md`.

**Architecture:** `GlassTableDrills` gains a generic `DrillSession<Spot, Answer, Reveal>` (the Outs drill migrates onto it; in-progress estimates become view `@State`), plus three new spot/grade files. The app gains a generic `DrillModel`, a `HomeView` with `NavigationStack`, and three new drill views — all composed from the existing `DrillScaffold`/`PlayingCardView`/`GradePill`/`PrimaryCTAButton`/`EstimateStepper` system.

**Tech Stack:** Swift 5.9, SwiftPM, XCTest, SwiftUI (iOS 17, `@Observable`), XcodeGen, iOS Simulator "iPhone 17".

## Global Constraints

- Every new source file starts with `// Copyright (c) 2026 Michael Ju (github.com/mhju0)`.
- Korean copy conventions (decisions.md §F): bands render 정확/근접/빗나감; acronyms Latin ("MDF", "AKs"); UI actions Hangul (콜, 폴드, 확인하기, 다음 문제).
- Bet sizings come only from the §A menu: 33/50/75/100/150% of pot. Amounts are integer bb.
- Engine convention: `requiredEquity(toCall:pot:)`'s `pot` **includes villain's bet** → call it as `requiredEquity(toCall: bet, pot: pot + bet)` when `pot` is displayed pot-before-bet.
- All spot generation is deterministic in `(baseSeed, index)` via `SplitMix64`, mirroring `OutsSpotGenerator` (index mixed with `0x9E37_79B9_7F4A_7C15`, attempt added).
- Drills tests run in debug: `swift test --package-path GlassTableDrills` (fast — no heavy enumeration). `GlassTableEngine` is NOT modified by this plan; if you do touch it, its gate is `swift test -c release --package-path GlassTableEngine` (~5 min).
- App builds: run `xcodegen generate` after adding/removing app source files, then
  `xcodebuild -project GlassTable.xcodeproj -scheme GlassTable -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`.
- Work on branch `m1-four-drills` off `main` (created in Task 1). The app target will NOT compile between Tasks 1–5 (package API changes land first); the package test suite is the gate until Task 6 restores the app.

---

### Task 1: Generic `DrillSession` + `OutsReveal`

**Files:**
- Modify: `GlassTableDrills/Sources/GlassTableDrills/DrillSession.swift` (full rewrite)
- Modify: `GlassTableDrills/Sources/GlassTableDrills/Reveal.swift` (rename `Reveal` → `OutsReveal`, add `estimate`)
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/DrillSessionTests.swift` (rewrite)

**Interfaces:**
- Consumes: `OutsSpotGenerator.spot(baseSeed:index:)`, `gradeOuts(estimate:spot:)`, `DrillProgress.recording(_:)`, `GradeBand` — all existing.
- Produces: `public protocol GradedReveal: Equatable { var band: GradeBand { get } }`; `public struct DrillSession<Spot: Equatable, Answer, Reveal: GradedReveal>` with `init(baseSeed:progress:generate:grade:)`, `phase` (`.deciding(spot:)` / `.revealed(spot:reveal:)`), `index`, `progress`, `commit(_ answer: Answer)`, `next()`; `public struct OutsReveal: GradedReveal` with fields `band, estimate, outs, excluded, improvementPct, whyText`; `gradeOuts(estimate:spot:) -> OutsReveal` (same signature, new return type name).

- [ ] **Step 1: Create the branch**

```bash
git checkout -b m1-four-drills main
```

- [ ] **Step 2: Rewrite the session tests (failing)**

Replace the entire contents of `GlassTableDrills/Tests/GlassTableDrillsTests/DrillSessionTests.swift`:

```swift
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class DrillSessionTests: XCTestCase {
    private func session() -> DrillSession<OutsSpot, Int, OutsReveal> {
        DrillSession(baseSeed: 42,
                     generate: OutsSpotGenerator.spot(baseSeed:index:),
                     grade: { gradeOuts(estimate: $0, spot: $1) })
    }

    func testStartsDeciding() {
        guard case let .deciding(spot) = session().phase else { return XCTFail("not deciding") }
        XCTAssertEqual(spot, OutsSpotGenerator.spot(baseSeed: 42, index: 0))
    }

    func testCommitGradesAndRecords() {
        var s = session()
        s.commit(8)
        guard case let .revealed(_, reveal) = s.phase else { return XCTFail("not revealed") }
        XCTAssertEqual(reveal.estimate, 8)
        XCTAssertEqual(s.progress.total, 1)
    }

    func testCommitWhileRevealedIsNoOp() {
        var s = session()
        s.commit(8)
        s.commit(9)
        XCTAssertEqual(s.progress.total, 1)
    }

    func testNextAdvancesToNewSpot() {
        var s = session()
        s.commit(8)
        s.next()
        XCTAssertEqual(s.index, 1)
        guard case let .deciding(spot) = s.phase else { return XCTFail("not deciding") }
        XCTAssertEqual(spot, OutsSpotGenerator.spot(baseSeed: 42, index: 1))
    }
}
```

(The old `testAdjustEstimateClamps` dies deliberately — clamping is now the views' stepper range.)

- [ ] **Step 3: Run to verify failure**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -5`
Expected: compile error — `DrillSession` takes no generic parameters / no `generate:` argument.

- [ ] **Step 4: Rewrite `DrillSession.swift`**

Replace the entire contents of `GlassTableDrills/Sources/GlassTableDrills/DrillSession.swift`:

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// A drill's graded result. Each drill's Reveal carries the user's answer plus
/// whatever its reveal screen needs; `band` is what progress tracking consumes.
public protocol GradedReveal: Equatable { var band: GradeBand { get } }

/// Pure state machine for one drill run, shared by all drills. In-progress input
/// is view state; the session only sees the committed answer.
public struct DrillSession<Spot: Equatable, Answer, Reveal: GradedReveal> {
    public enum Phase: Equatable {
        case deciding(spot: Spot)
        case revealed(spot: Spot, reveal: Reveal)
    }

    public let baseSeed: UInt64
    public private(set) var index: Int
    public private(set) var phase: Phase
    public private(set) var progress: DrillProgress
    private let generate: (UInt64, Int) -> Spot
    private let grade: (Answer, Spot) -> Reveal

    public init(baseSeed: UInt64, progress: DrillProgress = DrillProgress(),
                generate: @escaping (UInt64, Int) -> Spot,
                grade: @escaping (Answer, Spot) -> Reveal) {
        self.baseSeed = baseSeed
        self.index = 0
        self.progress = progress
        self.generate = generate
        self.grade = grade
        self.phase = .deciding(spot: generate(baseSeed, 0))
    }

    public mutating func commit(_ answer: Answer) {
        guard case let .deciding(spot) = phase else { return }
        let reveal = grade(answer, spot)
        progress = progress.recording(reveal.band)
        phase = .revealed(spot: spot, reveal: reveal)
    }

    public mutating func next() {
        index += 1
        phase = .deciding(spot: generate(baseSeed, index))
    }
}
```

- [ ] **Step 5: Update `Reveal.swift`**

In `GlassTableDrills/Sources/GlassTableDrills/Reveal.swift`, replace the struct and `gradeOuts` (keep `whyText(for:)` as is):

```swift
public struct OutsReveal: GradedReveal {
    public let band: GradeBand
    public let estimate: Int
    public let outs: [Card]
    public let excluded: [Card]
    public let improvementPct: Double
    public let whyText: String
}

/// Grade an out-count estimate against a spot. Bands: exact = 정확, ±2 = 근접, else = 빗나감.
public func gradeOuts(estimate: Int, spot: OutsSpot) -> OutsReveal {
    let band = gradeEstimate(user: Double(estimate), correct: Double(spot.outCount),
                             closeWithin: 2, spotOnWithin: 0)
    return OutsReveal(band: band, estimate: estimate, outs: spot.outs, excluded: spot.excluded,
                      improvementPct: spot.improvementPct, whyText: whyText(for: spot))
}
```

- [ ] **Step 6: Run package tests**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -3`
Expected: all tests pass (17 total: 4 rewritten session tests replace the old 4; RevealTests/OutsSpot*/Progress tests unchanged — they never name the `Reveal` type).

- [ ] **Step 7: Commit**

```bash
git add GlassTableDrills
git commit -m "refactor(drills): generic DrillSession; OutsReveal carries the estimate"
```

---

### Task 2: Per-drill `ProgressStore.standard(drill:)`

**Files:**
- Modify: `GlassTableDrills/Sources/GlassTableDrills/Progress.swift:39-44`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/ProgressTests.swift` (append one test)

**Interfaces:**
- Produces: `ProgressStore.standard(drill: String) -> ProgressStore` → `<drill>-progress.json` in Application Support. Replaces `standard()` (its only other caller, `OutsDrillModel`, is replaced in Task 6). Slugs used later: `outs`, `potodds`, `mdf`, `callfold`, `blockers`.

- [ ] **Step 1: Append the failing test to `ProgressTests.swift`**

```swift
    func testStandardDrillFileName() {
        XCTAssertEqual(ProgressStore.standard(drill: "outs").url.lastPathComponent,
                       "outs-progress.json")
        XCTAssertEqual(ProgressStore.standard(drill: "mdf").url.lastPathComponent,
                       "mdf-progress.json")
    }
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -5`
Expected: compile error — `standard` takes no `drill:` argument.

- [ ] **Step 3: Replace `standard()` in `Progress.swift`**

```swift
    /// Default on-device store in Application Support, one file per drill.
    public static func standard(drill: String) -> ProgressStore {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return ProgressStore(url: dir.appendingPathComponent("\(drill)-progress.json"))
    }
```

- [ ] **Step 4: Run package tests**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -3`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add GlassTableDrills
git commit -m "feat(drills): per-drill progress files via standard(drill:)"
```

---

### Task 3: `BetSpot` + 팟 오즈 / MDF grading

**Files:**
- Create: `GlassTableDrills/Sources/GlassTableDrills/BetSpot.swift`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/BetSpotTests.swift`

**Interfaces:**
- Consumes: `requiredEquity`, `mdf`, `gradeEstimate`, `SplitMix64`, `GradedReveal` (Task 1).
- Produces: `BetSpot { pot, bet: Int; requiredPct, mdfPct: Double }`; `BetSpotGenerator.spot(baseSeed:index:) -> BetSpot` (also exposes `static let pots`, `static let fractions` internally for Task 4); `PercentReveal: GradedReveal { band, answerPct: Int, correctPct: Double, whyText }`; `gradePotOdds(estimatePct: Int, spot: BetSpot) -> PercentReveal`; `gradeMDF(estimatePct: Int, spot: BetSpot) -> PercentReveal`; `public func pctText(_ x: Double) -> String` ("25" / "66.7").

- [ ] **Step 1: Write the failing tests**

Create `GlassTableDrills/Tests/GlassTableDrillsTests/BetSpotTests.swift`:

```swift
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class BetSpotTests: XCTestCase {
    func testDeterministicAndVaried() {
        XCTAssertEqual(BetSpotGenerator.spot(baseSeed: 7, index: 3),
                       BetSpotGenerator.spot(baseSeed: 7, index: 3))
        let distinct = Set((0..<20).map { BetSpotGenerator.spot(baseSeed: 7, index: $0) }
            .map { "\($0.pot)-\($0.bet)" })
        XCTAssertGreaterThan(distinct.count, 1)
    }

    func testSpotInvariants() {
        for i in 0..<200 {
            let s = BetSpotGenerator.spot(baseSeed: 7, index: i)
            XCTAssertTrue(BetSpotGenerator.pots.contains(s.pot))
            XCTAssertGreaterThanOrEqual(s.bet, 1)
            // Both answers must be reachable on the 5%-step grid within the 정확 band.
            let nearestReq = (s.requiredPct / 5).rounded() * 5
            XCTAssertLessThanOrEqual(abs(nearestReq - s.requiredPct), 2.5)
            let nearestMdf = (s.mdfPct / 5).rounded() * 5
            XCTAssertLessThanOrEqual(abs(nearestMdf - s.mdfPct), 2.5)
        }
    }

    func testPotOddsGradeAndWhy() {
        let s = BetSpot(pot: 10, bet: 5)  // required = 5/20 = 25%
        XCTAssertEqual(gradePotOdds(estimatePct: 25, spot: s).band, .spotOn)
        XCTAssertEqual(gradePotOdds(estimatePct: 30, spot: s).band, .close)
        XCTAssertEqual(gradePotOdds(estimatePct: 35, spot: s).band, .off)
        XCTAssertEqual(gradePotOdds(estimatePct: 25, spot: s).whyText,
                       "벳 5 ÷ (팟 10 + 벳 5 + 콜 5) = 25%")
    }

    func testMDFGradeAndWhy() {
        let s = BetSpot(pot: 10, bet: 5)  // mdf = 10/15 = 66.7%
        XCTAssertEqual(gradeMDF(estimatePct: 65, spot: s).band, .spotOn)  // nearest grid step
        XCTAssertEqual(gradeMDF(estimatePct: 60, spot: s).band, .close)
        XCTAssertEqual(gradeMDF(estimatePct: 55, spot: s).band, .off)
        XCTAssertEqual(gradeMDF(estimatePct: 65, spot: s).whyText,
                       "팟 10 ÷ (팟 10 + 벳 5) = 66.7%")
    }

    func testPctText() {
        XCTAssertEqual(pctText(25.0), "25")
        XCTAssertEqual(pctText(100.0 * 2 / 3), "66.7")
        XCTAssertEqual(pctText(37.5), "37.5")
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -5`
Expected: compile error — `BetSpotGenerator` not found.

- [ ] **Step 3: Implement `BetSpot.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// A priced decision point: pot (before villain's bet) and villain's bet, in bb.
public struct BetSpot: Equatable {
    public let pot: Int
    public let bet: Int
    public init(pot: Int, bet: Int) { self.pot = pot; self.bet = bet }

    /// Equity needed to call, in percent. Engine's `pot` param includes the bet.
    public var requiredPct: Double {
        requiredEquity(toCall: Double(bet), pot: Double(pot + bet)) * 100
    }
    /// Minimum defense frequency, in percent.
    public var mdfPct: Double { mdf(bet: Double(bet), pot: Double(pot)) * 100 }
}

/// Deterministic priced spots. Same (baseSeed, index) → same spot.
public enum BetSpotGenerator {
    static let pots = [6, 8, 10, 12, 15, 20, 24, 30]
    static let fractions = [0.33, 0.5, 0.75, 1.0, 1.5]  // decisions.md §A sizing menu

    public static func spot(baseSeed: UInt64, index: Int) -> BetSpot {
        var rng = SplitMix64(seed: baseSeed
            &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15)
        let pot = pots.randomElement(using: &rng)!
        let f = fractions.randomElement(using: &rng)!
        return BetSpot(pot: pot, bet: max(1, Int((f * Double(pot)).rounded())))
    }
}

/// Shared reveal for the two percent-estimate drills (팟 오즈, MDF).
public struct PercentReveal: GradedReveal {
    public let band: GradeBand
    public let answerPct: Int
    public let correctPct: Double
    public let whyText: String
}

/// "25" for whole numbers, "66.7" otherwise (percent formatting for UI copy).
public func pctText(_ x: Double) -> String {
    abs(x - x.rounded()) < 0.05 ? "\(Int(x.rounded()))" : String(format: "%.1f", x)
}

public func gradePotOdds(estimatePct: Int, spot: BetSpot) -> PercentReveal {
    let correct = spot.requiredPct
    return PercentReveal(
        band: gradeEstimate(user: Double(estimatePct), correct: correct,
                            closeWithin: 7.5, spotOnWithin: 2.5),
        answerPct: estimatePct, correctPct: correct,
        whyText: "벳 \(spot.bet) ÷ (팟 \(spot.pot) + 벳 \(spot.bet) + 콜 \(spot.bet)) = \(pctText(correct))%")
}

public func gradeMDF(estimatePct: Int, spot: BetSpot) -> PercentReveal {
    let correct = spot.mdfPct
    return PercentReveal(
        band: gradeEstimate(user: Double(estimatePct), correct: correct,
                            closeWithin: 7.5, spotOnWithin: 2.5),
        answerPct: estimatePct, correctPct: correct,
        whyText: "팟 \(spot.pot) ÷ (팟 \(spot.pot) + 벳 \(spot.bet)) = \(pctText(correct))%")
}
```

- [ ] **Step 4: Run package tests**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -3`
Expected: all pass. If `testSpotInvariants` fails on the grid assertion, a pot×fraction rounding produced an answer >2.5 from any 5% step — remove the offending pot from `pots` rather than loosening the band (the drill's promise is that 정확 is always reachable).

- [ ] **Step 5: Commit**

```bash
git add GlassTableDrills
git commit -m "feat(drills): BetSpot generator + pot-odds/MDF grading"
```

---

### Task 4: `CallFoldSpot`

**Files:**
- Create: `GlassTableDrills/Sources/GlassTableDrills/CallFold.swift`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/CallFoldTests.swift`

**Interfaces:**
- Consumes: `exactEquityHeadsUp(hero:villain:board:).equity`, `callIsProfitable`, `gradeBinary`, `Deck.all`, `SplitMix64`, `BetSpotGenerator.pots/.fractions` (Task 3), `pctText` (Task 3).
- Produces: `CallFoldSpot { hero, villain, board: [Card]; pot, bet: Int; equityPct: Double; requiredPct: Double; correctIsCall: Bool }`; `CallFoldSpotGenerator.spot(baseSeed:index:)`; `CallFoldReveal: GradedReveal { band, userCalls, correctIsCall: Bool, equityPct, requiredPct: Double, whyText }`; `gradeCallFold(userCalls: Bool, spot: CallFoldSpot) -> CallFoldReveal`.

- [ ] **Step 1: Write the failing tests**

Create `GlassTableDrills/Tests/GlassTableDrillsTests/CallFoldTests.swift`:

```swift
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class CallFoldTests: XCTestCase {
    func testDeterministic() {
        XCTAssertEqual(CallFoldSpotGenerator.spot(baseSeed: 11, index: 5),
                       CallFoldSpotGenerator.spot(baseSeed: 11, index: 5))
    }

    func testSpotInvariants() {
        for i in 0..<30 {
            let s = CallFoldSpotGenerator.spot(baseSeed: 11, index: i)
            XCTAssertEqual(s.board.count, 4)
            XCTAssertGreaterThanOrEqual(s.bet, 1)
            XCTAssertTrue((5.0...95.0).contains(s.equityPct), "index \(i): \(s.equityPct)")
            // equityPct must match the engine's exact enumeration.
            let exact = exactEquityHeadsUp(hero: s.hero, villain: s.villain, board: s.board).equity
            XCTAssertEqual(s.equityPct, exact * 100, accuracy: 1e-9)
            XCTAssertEqual(s.correctIsCall,
                           callIsProfitable(equity: exact, toCall: Double(s.bet),
                                            pot: Double(s.pot + s.bet)))
        }
    }

    func testGradeBothWays() {
        let s = CallFoldSpot(hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
                             board: Card.parse("Qh7h2s3c")!, pot: 10, bet: 5, equityPct: 30)
        XCTAssertTrue(s.correctIsCall)  // 30% > required 25%
        XCTAssertEqual(gradeCallFold(userCalls: true, spot: s).band, .spotOn)
        XCTAssertEqual(gradeCallFold(userCalls: false, spot: s).band, .off)
        XCTAssertEqual(gradeCallFold(userCalls: true, spot: s).whyText,
                       "에퀴티 30% vs 필요 25% → 콜")
    }

    func testFoldSpotWhy() {
        let s = CallFoldSpot(hero: Card.parse("AhKh")!, villain: Card.parse("QsQd")!,
                             board: Card.parse("Qh7h2s3c")!, pot: 10, bet: 5, equityPct: 20)
        XCTAssertFalse(s.correctIsCall)
        XCTAssertEqual(gradeCallFold(userCalls: false, spot: s).whyText,
                       "에퀴티 20% vs 필요 25% → 폴드")
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -5`
Expected: compile error — `CallFoldSpotGenerator` not found.

- [ ] **Step 3: Implement `CallFold.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// Turn spot vs a face-up villain hand, with a price to call.
public struct CallFoldSpot: Equatable {
    public let hero: [Card]
    public let villain: [Card]
    public let board: [Card]      // 4 cards (turn)
    public let pot: Int           // before villain's bet, bb
    public let bet: Int
    public let equityPct: Double  // hero's exact equity over the remaining rivers, percent

    public var requiredPct: Double {
        requiredEquity(toCall: Double(bet), pot: Double(pot + bet)) * 100
    }
    public var correctIsCall: Bool {
        callIsProfitable(equity: equityPct / 100, toCall: Double(bet), pot: Double(pot + bet))
    }
}

/// Deterministic call/fold spots. Same (baseSeed, index) → same spot.
public enum CallFoldSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> CallFoldSpot {
        var attempt = 0
        while true {
            let seed = baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt)
            var rng = SplitMix64(seed: seed)
            let deck = Deck.all.shuffled(using: &rng)
            let hero = Array(deck[0..<2])
            let villain = Array(deck[2..<4])
            let board = Array(deck[4..<8])
            let equity = exactEquityHeadsUp(hero: hero, villain: villain, board: board).equity
            // ponytail: reject near-locks (5–95% passes most random deals, so no
            // widening valve like OutsSpotGenerator needs — reseeded retries suffice).
            if equity >= 0.05 && equity <= 0.95 {
                let pot = BetSpotGenerator.pots.randomElement(using: &rng)!
                let f = BetSpotGenerator.fractions.randomElement(using: &rng)!
                return CallFoldSpot(hero: hero, villain: villain, board: board,
                                    pot: pot, bet: max(1, Int((f * Double(pot)).rounded())),
                                    equityPct: equity * 100)
            }
            attempt += 1
        }
    }
}

public struct CallFoldReveal: GradedReveal {
    public let band: GradeBand
    public let userCalls: Bool
    public let correctIsCall: Bool
    public let equityPct: Double
    public let requiredPct: Double
    public let whyText: String
}

/// Binary grade: 정확 or 빗나감 — no 근접 band for a two-way decision.
public func gradeCallFold(userCalls: Bool, spot: CallFoldSpot) -> CallFoldReveal {
    let correct = spot.correctIsCall
    return CallFoldReveal(
        band: gradeBinary(userChose: userCalls, correct: correct),
        userCalls: userCalls, correctIsCall: correct,
        equityPct: spot.equityPct, requiredPct: spot.requiredPct,
        whyText: "에퀴티 \(pctText(spot.equityPct))% vs 필요 \(pctText(spot.requiredPct))% → \(correct ? "콜" : "폴드")")
}
```

- [ ] **Step 4: Run package tests**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -3`
Expected: all pass (the 30-spot invariant loop runs exact 44-river enumerations — well under a second even in debug).

- [ ] **Step 5: Commit**

```bash
git add GlassTableDrills
git commit -m "feat(drills): CallFoldSpot generator + binary grading"
```

---

### Task 5: `BlockerSpot`

**Files:**
- Create: `GlassTableDrills/Sources/GlassTableDrills/Blocker.swift`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/BlockerTests.swift`

**Interfaces:**
- Consumes: `comboCount(rankA:rankB:kind:removed:)`, `ComboKind` (.pair/.suited/.any), `Deck.all`, `SplitMix64`, `gradeEstimate`, `GradedReveal`.
- Produces: `BlockerSpot { rankA, rankB: Int; kind: ComboKind; removed: [Card]; count: Int; className: String; baseline: Int }`; `BlockerSpotGenerator.spot(baseSeed:index:)`; `BlockerReveal: GradedReveal { band, estimate, count: Int, whyText }`; `gradeBlocker(estimate: Int, spot: BlockerSpot) -> BlockerReveal`.

- [ ] **Step 1: Write the failing tests**

Create `GlassTableDrills/Tests/GlassTableDrillsTests/BlockerTests.swift`:

```swift
import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class BlockerTests: XCTestCase {
    func testDeterministic() {
        XCTAssertEqual(BlockerSpotGenerator.spot(baseSeed: 3, index: 9),
                       BlockerSpotGenerator.spot(baseSeed: 3, index: 9))
    }

    func testSpotInvariants() {
        for i in 0..<30 {
            let s = BlockerSpotGenerator.spot(baseSeed: 3, index: i)
            XCTAssertTrue((10...14).contains(s.rankA))
            XCTAssertTrue((10...14).contains(s.rankB))
            XCTAssertNotEqual(s.kind, .offsuit)
            if s.kind != .pair { XCTAssertGreaterThan(s.rankA, s.rankB) }
            XCTAssertTrue((2...4).contains(s.removed.count))
            XCTAssertTrue(s.removed.contains { $0.rank == s.rankA || $0.rank == s.rankB },
                          "index \(i): no relevant removed card")
            XCTAssertEqual(s.count, comboCount(rankA: s.rankA, rankB: s.rankB,
                                               kind: s.kind, removed: Set(s.removed)))
        }
    }

    func testClassNamesAndBaselines() {
        let qq = BlockerSpot(rankA: 12, rankB: 12, kind: .pair, removed: [Card("Qh")!], count: 3)
        XCTAssertEqual(qq.className, "QQ"); XCTAssertEqual(qq.baseline, 6)
        let ak = BlockerSpot(rankA: 14, rankB: 13, kind: .any, removed: [Card("As")!], count: 12)
        XCTAssertEqual(ak.className, "AK"); XCTAssertEqual(ak.baseline, 16)
        let aks = BlockerSpot(rankA: 14, rankB: 13, kind: .suited, removed: [Card("As")!], count: 3)
        XCTAssertEqual(aks.className, "AKs"); XCTAssertEqual(aks.baseline, 4)
    }

    func testGradeAndWhy() {
        let qq = BlockerSpot(rankA: 12, rankB: 12, kind: .pair, removed: [Card("Qh")!], count: 3)
        XCTAssertEqual(gradeBlocker(estimate: 3, spot: qq).band, .spotOn)
        XCTAssertEqual(gradeBlocker(estimate: 5, spot: qq).band, .close)
        XCTAssertEqual(gradeBlocker(estimate: 6, spot: qq).band, .off)
        XCTAssertEqual(gradeBlocker(estimate: 3, spot: qq).whyText,
                       "Q 3장 남음 → 3×2÷2 = 3 콤보")
        let ak = BlockerSpot(rankA: 14, rankB: 13, kind: .any, removed: [Card("As")!], count: 12)
        XCTAssertEqual(gradeBlocker(estimate: 12, spot: ak).whyText,
                       "A 3장 × K 4장 = 12 콤보")
        let aks = BlockerSpot(rankA: 14, rankB: 13, kind: .suited, removed: [Card("As")!], count: 3)
        XCTAssertEqual(gradeBlocker(estimate: 3, spot: aks).whyText,
                       "양쪽 다 남은 무늬 3개 = 3 콤보")
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -5`
Expected: compile error — `BlockerSpotGenerator` not found.

- [ ] **Step 3: Implement `Blocker.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import GlassTableEngine

/// "How many combos of X remain?" given removed (visible) cards.
/// Kinds used: .pair, .any, .suited — offsuit deferred (any − suited; more
/// confusing than instructive). Ranks are always T–A (10...14).
public struct BlockerSpot: Equatable {
    public let rankA: Int          // for non-pairs, always the higher rank
    public let rankB: Int
    public let kind: ComboKind
    public let removed: [Card]
    public let count: Int

    /// "QQ", "AK", "AKs" — acronyms Latin per decisions.md §F.
    public var className: String {
        switch kind {
        case .pair: return rankName(rankA) + rankName(rankA)
        case .suited: return rankName(rankA) + rankName(rankB) + "s"
        default: return rankName(rankA) + rankName(rankB)
        }
    }
    /// Unblocked baseline for the class — the stepper's starting value.
    public var baseline: Int {
        switch kind { case .pair: return 6; case .suited: return 4; default: return 16 }
    }
}

/// T–A only; the generator never produces ranks below 10.
func rankName(_ r: Int) -> String { ["T", "J", "Q", "K", "A"][r - 10] }

/// Deterministic blocker questions. Same (baseSeed, index) → same spot.
public enum BlockerSpotGenerator {
    public static func spot(baseSeed: UInt64, index: Int) -> BlockerSpot {
        var attempt = 0
        while true {
            let seed = baseSeed
                &+ UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15
                &+ UInt64(attempt)
            var rng = SplitMix64(seed: seed)
            let roll = rng.next() % 3
            var rankA = Int.random(in: 10...14, using: &rng)
            var rankB = rankA
            let kind: ComboKind
            if roll == 0 {
                kind = .pair
            } else {
                kind = roll == 1 ? .any : .suited
                repeat { rankB = Int.random(in: 10...14, using: &rng) } while rankB == rankA
                if rankB > rankA { swap(&rankA, &rankB) }
            }
            let k = Int.random(in: 2...4, using: &rng)
            let removed = Array(Deck.all.shuffled(using: &rng)[0..<k])
            // The answer must differ from the baseline: ≥1 removed card hits the class.
            guard removed.contains(where: { $0.rank == rankA || $0.rank == rankB }) else {
                attempt += 1
                continue
            }
            return BlockerSpot(rankA: rankA, rankB: rankB, kind: kind, removed: removed,
                               count: comboCount(rankA: rankA, rankB: rankB, kind: kind,
                                                 removed: Set(removed)))
        }
    }
}

public struct BlockerReveal: GradedReveal {
    public let band: GradeBand
    public let estimate: Int
    public let count: Int
    public let whyText: String
}

/// Same bands as the Outs drill: exact = 정확, ±2 = 근접, else = 빗나감.
public func gradeBlocker(estimate: Int, spot: BlockerSpot) -> BlockerReveal {
    BlockerReveal(
        band: gradeEstimate(user: Double(estimate), correct: Double(spot.count),
                            closeWithin: 2, spotOnWithin: 0),
        estimate: estimate, count: spot.count, whyText: whyText(for: spot))
}

func whyText(for spot: BlockerSpot) -> String {
    let removedSet = Set(spot.removed)
    func left(_ rank: Int) -> Int {
        (0...3).filter { !removedSet.contains(Card(rank: rank, suit: $0)) }.count
    }
    let na = left(spot.rankA)
    switch spot.kind {
    case .pair:
        return "\(rankName(spot.rankA)) \(na)장 남음 → \(na)×\(na - 1)÷2 = \(spot.count) 콤보"
    case .suited:
        return "양쪽 다 남은 무늬 \(spot.count)개 = \(spot.count) 콤보"
    default:
        return "\(rankName(spot.rankA)) \(na)장 × \(rankName(spot.rankB)) \(left(spot.rankB))장 = \(spot.count) 콤보"
    }
}
```

(`whyText(for:)` overloads the Outs one by parameter type — both internal, no clash.)

- [ ] **Step 4: Run package tests**

Run: `swift test --package-path GlassTableDrills 2>&1 | tail -3`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add GlassTableDrills
git commit -m "feat(drills): BlockerSpot generator + combo grading"
```

---

### Task 6: App — generic `DrillModel`, `HomeView`, outs migration

**Files:**
- Create: `GlassTable/Sources/DrillModel.swift`
- Create: `GlassTable/Sources/Screens/HomeView.swift`
- Create: `GlassTable/Sources/Screens/OutsDrillView.swift`
- Delete: `GlassTable/Sources/OutsDrillModel.swift`, `GlassTable/Sources/RootView.swift`
- Modify: `GlassTable/Sources/GlassTableApp.swift`, `GlassTable/Sources/Screens/DecideView.swift`, `GlassTable/Sources/Screens/RevealView.swift`, `GlassTable/Sources/DesignSystem/Components.swift` (stepper gains `step`/`suffix`)

**Interfaces:**
- Consumes: everything Tasks 1–5 produced.
- Produces: `DrillModel<Spot, Answer, Reveal>` (@Observable; `init(slug:baseSeed:generate:grade:demoAnswer:)`, `phase`, `streak`, `commit(_:)`, `next()`); `DrillKind` enum (`outs/potodds/callfold/mdf/blockers`, `name`, `subtitle`); `HomeView` (NavigationStack root); `EstimateStepper(value:step:suffix:onAdjust:)` with defaults `step: 1, suffix: ""`. Debug hook: `GT_DEMO_DRILL=<slug>` auto-opens the drill; with `GT_DEMO_REVEAL=<n>` it advances to spot n and commits `demoAnswer`. Tasks 7–9 replace the placeholder rows in `HomeView.drillView`.

- [ ] **Step 1: Create `GlassTable/Sources/DrillModel.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation
import Observation
import GlassTableDrills

@Observable
final class DrillModel<Spot: Equatable, Answer, Reveal: GradedReveal> {
    private var session: DrillSession<Spot, Answer, Reveal>
    private let store: ProgressStore

    /// `demoAnswer` is what the debug screenshot hook commits (GT_DEMO_*).
    init(slug: String, baseSeed: UInt64 = 20260722,
         generate: @escaping (UInt64, Int) -> Spot,
         grade: @escaping (Answer, Spot) -> Reveal,
         demoAnswer: Answer) {
        let store = ProgressStore.standard(drill: slug)
        self.store = store
        self.session = DrillSession(baseSeed: baseSeed, progress: store.load(),
                                    generate: generate, grade: grade)
        #if DEBUG
        // GT_DEMO_DRILL=<slug> + GT_DEMO_REVEAL=<n>: open at spot n's reveal for screenshots.
        let env = ProcessInfo.processInfo.environment
        if env["GT_DEMO_DRILL"] == slug, let n = env["GT_DEMO_REVEAL"], let idx = Int(n) {
            for _ in 0..<idx { session.next() }
            session.commit(demoAnswer)
        }
        #endif
    }

    var phase: DrillSession<Spot, Answer, Reveal>.Phase { session.phase }
    var streak: Int { session.progress.streak }

    func commit(_ answer: Answer) { session.commit(answer); store.save(session.progress) }
    func next() { session.next() }
}
```

- [ ] **Step 2: Create `GlassTable/Sources/Screens/HomeView.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

enum DrillKind: String, CaseIterable {
    case outs, potodds, callfold, mdf, blockers

    var name: String {
        switch self {
        case .outs: return "아웃 카운팅"
        case .potodds: return "팟 오즈"
        case .callfold: return "콜/폴드"
        case .mdf: return "MDF"
        case .blockers: return "블로커"
        }
    }
    var subtitle: String {
        switch self {
        case .outs: return "리버에서 몇 장이면 이기나"
        case .potodds: return "콜에 필요한 에퀴티"
        case .callfold: return "가격 대비 콜/폴드 판단"
        case .mdf: return "최소 방어 빈도"
        case .blockers: return "남은 콤보 세기"
        }
    }
}

struct HomeView: View {
    @State private var path: [DrillKind] = []
    @State private var progress: [DrillKind: DrillProgress] = [:]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Glass Table").font(GT.title(24)).foregroundStyle(GT.ink)
                        .padding(.top, 12)
                    Text("레인지와 EV로 생각하는 홀덤 훈련")
                        .font(GT.body(13)).foregroundStyle(GT.inkSecondary)
                        .padding(.bottom, 8)
                    ForEach(DrillKind.allCases, id: \.self, content: row)
                }
                .padding(.horizontal, 18)
            }
            .background(Color.white)
            .navigationDestination(for: DrillKind.self, destination: drillView)
            .onAppear {
                for k in DrillKind.allCases {
                    progress[k] = ProgressStore.standard(drill: k.rawValue).load()
                }
                #if DEBUG
                if let slug = ProcessInfo.processInfo.environment["GT_DEMO_DRILL"],
                   let kind = DrillKind(rawValue: slug), path.isEmpty {
                    path = [kind]
                }
                #endif
            }
        }
        .tint(.white)  // white back chevron over the green drill zone
    }

    private func row(_ kind: DrillKind) -> some View {
        NavigationLink(value: kind) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.name).font(GT.title(15)).foregroundStyle(GT.ink)
                    Text(kind.subtitle).font(GT.body(12)).foregroundStyle(GT.inkMuted)
                }
                Spacer()
                if let p = progress[kind], p.total > 0 {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("🔥 \(p.streak)").font(GT.semibold(12)).foregroundStyle(GT.inkSecondary)
                        Text("\(Int(p.accuracy * 100))%").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(GT.inkMuted)
            }
            .padding(16)
            .background(GT.surface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func drillView(_ kind: DrillKind) -> some View {
        switch kind {
        case .outs: OutsDrillView()
        case .potodds: Text(kind.name)   // replaced in Task 7
        case .callfold: Text(kind.name)  // replaced in Task 8
        case .mdf: Text(kind.name)       // replaced in Task 7
        case .blockers: Text(kind.name)  // replaced in Task 9
        }
    }
}

#Preview { HomeView() }
```

- [ ] **Step 3: Create `GlassTable/Sources/Screens/OutsDrillView.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct OutsDrillView: View {
    @State private var model = DrillModel<OutsSpot, Int, OutsReveal>(
        slug: DrillKind.outs.rawValue,
        generate: OutsSpotGenerator.spot(baseSeed:index:),
        grade: { gradeOuts(estimate: $0, spot: $1) },
        demoAnswer: 8)
    @State private var estimate = 8

    var body: some View {
        Group {
            switch model.phase {
            case let .deciding(spot):
                DecideView(spot: spot, estimate: estimate, streak: model.streak,
                           onAdjust: { estimate = max(0, min(21, estimate + $0)) },
                           onCommit: { model.commit(estimate) })
            case let .revealed(spot, reveal):
                RevealView(spot: spot, reveal: reveal, streak: model.streak,
                           onNext: { estimate = 8; model.next() })
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
```

- [ ] **Step 4: Delete the superseded files and update the entry point**

```bash
rm GlassTable/Sources/OutsDrillModel.swift GlassTable/Sources/RootView.swift
```

In `GlassTable/Sources/GlassTableApp.swift`, change the scene body to:

```swift
        WindowGroup { HomeView() }
```

- [ ] **Step 5: Update `DecideView.swift` and `RevealView.swift`**

`DecideView` body is unchanged; only its stored properties already match (`spot`, `estimate`, `streak`, `onAdjust`, `onCommit`) — no edit needed beyond confirming it compiles.

In `RevealView.swift`: delete the `let estimate: Int` property, change `let reveal: Reveal` to `let reveal: OutsReveal`, and change the "내 답" line to use the reveal:

```swift
    let spot: OutsSpot
    let reveal: OutsReveal
    let streak: Int
    let onNext: () -> Void
```

```swift
                    Text("내 답 \(reveal.estimate) · 정답 \(spot.outCount)")
```

Update its `#Preview` tail to match:

```swift
    return RevealView(spot: spot, reveal: gradeOuts(estimate: 9, spot: spot),
                      streak: 8, onNext: {})
```

- [ ] **Step 6: Extend `EstimateStepper` in `Components.swift`**

Replace the `EstimateStepper` struct with:

```swift
struct EstimateStepper: View {
    let value: Int
    var step: Int = 1
    var suffix: String = ""
    let onAdjust: (Int) -> Void
    private func key(_ s: String, _ d: Int) -> some View {
        Button { onAdjust(d) } label: {
            Text(s).font(GT.semibold(22)).foregroundStyle(GT.inkSecondary)
                .frame(width: 44, height: 44)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 13))
        }.buttonStyle(.plain)
    }
    var body: some View {
        HStack(spacing: 12) {
            key("−", -step)
            Text("\(value)\(suffix)").font(GT.title(24)).foregroundStyle(GT.green)
                .frame(minWidth: 60, minHeight: 50)
                .background(.white, in: RoundedRectangle(cornerRadius: 13))
            key("+", step)
        }
    }
}
```

(Existing call sites keep working — `step`/`suffix` default to the old behavior.)

- [ ] **Step 7: Build and verify on the simulator**

```bash
xcodegen generate
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
```
Expected: `BUILD SUCCEEDED`.

```bash
SCRATCHPAD=<your session scratchpad directory>   # screenshots go here, not /tmp
APP=build/Build/Products/Debug-iphonesimulator/GlassTable.app
xcrun simctl boot "iPhone 17" 2>/dev/null; xcrun simctl install booted "$APP"
xcrun simctl terminate booted com.michaelju.glasstable.GlassTable 2>/dev/null
xcrun simctl launch booted com.michaelju.glasstable.GlassTable
xcrun simctl io booted screenshot "$SCRATCHPAD/home.png"
xcrun simctl terminate booted com.michaelju.glasstable.GlassTable
SIMCTL_CHILD_GT_DEMO_DRILL=outs SIMCTL_CHILD_GT_DEMO_REVEAL=29 \
  xcrun simctl launch booted com.michaelju.glasstable.GlassTable
xcrun simctl io booted screenshot "$SCRATCHPAD/outs-reveal.png"
```

Read both screenshots: home shows the five rows (outs row shows any prior streak/accuracy); the outs reveal matches the pre-refactor screen (regression check), now with a white back chevron top-left.

- [ ] **Step 8: Commit**

```bash
git add -A GlassTable project.yml
git commit -m "feat(app): home navigation + generic DrillModel; outs drill migrated"
```

---

### Task 7: `PercentDrillView` (팟 오즈 + MDF)

**Files:**
- Create: `GlassTable/Sources/Screens/PercentDrillView.swift`
- Modify: `GlassTable/Sources/Screens/HomeView.swift` (two placeholder lines)

**Interfaces:**
- Consumes: `BetSpot`, `BetSpotGenerator.spot`, `gradePotOdds`, `gradeMDF`, `PercentReveal`, `pctText`, `DrillModel`, `DrillScaffold`, `EstimateStepper(value:step:suffix:onAdjust:)`, `GradePill`, `PrimaryCTAButton`, `SectionLabel`.
- Produces: `PercentDrillView(config:)` with `PercentDrillConfig.potOdds` / `.mdf`.

- [ ] **Step 1: Create `GlassTable/Sources/Screens/PercentDrillView.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableDrills

struct PercentDrillConfig {
    let slug: String
    let title: String
    let question: String
    let questionEn: String
    let grade: (Int, BetSpot) -> PercentReveal

    static let potOdds = PercentDrillConfig(
        slug: DrillKind.potodds.rawValue, title: "팟 오즈",
        question: "콜하려면 에퀴티가 몇 % 필요할까요?",
        questionEn: "Equity needed to call?",
        grade: { gradePotOdds(estimatePct: $0, spot: $1) })

    static let mdf = PercentDrillConfig(
        slug: DrillKind.mdf.rawValue, title: "MDF",
        question: "최소 몇 %는 폴드하지 않아야 할까요?",
        questionEn: "Minimum defense frequency?",
        grade: { gradeMDF(estimatePct: $0, spot: $1) })
}

struct PercentDrillView: View {
    let config: PercentDrillConfig
    @State private var model: DrillModel<BetSpot, Int, PercentReveal>
    @State private var estimate = 50

    init(config: PercentDrillConfig) {
        self.config = config
        _model = State(initialValue: DrillModel(
            slug: config.slug,
            generate: BetSpotGenerator.spot(baseSeed:index:),
            grade: config.grade,
            demoAnswer: 50))
    }

    private func chip(_ label: String, _ bb: Int) -> some View {
        VStack(spacing: 4) {
            Text(label).font(GT.semibold(11)).foregroundStyle(.white.opacity(0.62))
            Text("\(bb) bb").font(GT.title(26)).foregroundStyle(.white)
        }
        .frame(minWidth: 96)
        .padding(.vertical, 14).padding(.horizontal, 18)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private func potBet(_ spot: BetSpot) -> some View {
        HStack(spacing: 14) { chip("팟", spot.pot); chip("벳", spot.bet) }
            .padding(.top, 30)
    }

    var body: some View {
        Group {
            switch model.phase {
            case let .deciding(spot):
                DrillScaffold(title: config.title, streak: model.streak) {
                    potBet(spot)
                } sheet: {
                    VStack(spacing: 15) {
                        VStack(spacing: 3) {
                            Text(config.question).font(GT.title(15)).foregroundStyle(GT.ink)
                            Text(config.questionEn).font(GT.body(11)).foregroundStyle(GT.inkMuted)
                        }
                        EstimateStepper(value: estimate, step: 5, suffix: "%",
                                        onAdjust: { estimate = max(0, min(100, estimate + $0)) })
                        PrimaryCTAButton(title: "확인하기", action: { model.commit(estimate) })
                    }
                }
            case let .revealed(spot, reveal):
                DrillScaffold(title: config.title, streak: model.streak) {
                    potBet(spot)
                } sheet: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 9) {
                            GradePill(band: reveal.band)
                            Text("내 답 \(reveal.answerPct)% · 정답 \(pctText(reveal.correctPct))%")
                                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                        }
                        Text(reveal.whyText)
                            .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                        PrimaryCTAButton(title: "다음 문제", action: { estimate = 50; model.next() })
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview { PercentDrillView(config: .potOdds) }
```

- [ ] **Step 2: Wire into `HomeView.drillView`**

Replace the two placeholder lines:

```swift
        case .potodds: PercentDrillView(config: .potOdds)
```
```swift
        case .mdf: PercentDrillView(config: .mdf)
```

- [ ] **Step 3: Build and screenshot both drills**

```bash
xcodegen generate
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
APP=build/Build/Products/Debug-iphonesimulator/GlassTable.app
xcrun simctl install booted "$APP"
xcrun simctl terminate booted com.michaelju.glasstable.GlassTable 2>/dev/null
SIMCTL_CHILD_GT_DEMO_DRILL=potodds xcrun simctl launch booted com.michaelju.glasstable.GlassTable
xcrun simctl io booted screenshot "$SCRATCHPAD/potodds-decide.png"
xcrun simctl terminate booted com.michaelju.glasstable.GlassTable
SIMCTL_CHILD_GT_DEMO_DRILL=mdf SIMCTL_CHILD_GT_DEMO_REVEAL=2 \
  xcrun simctl launch booted com.michaelju.glasstable.GlassTable
xcrun simctl io booted screenshot "$SCRATCHPAD/mdf-reveal.png"
```

Read both: pot/bet chips centered in the green zone, stepper shows "50%", MDF reveal shows pill + why box.

- [ ] **Step 4: Commit**

```bash
git add GlassTable
git commit -m "feat(app): pot-odds + MDF drills (shared PercentDrillView)"
```

---

### Task 8: `SecondaryCTAButton` + `CallFoldView`

**Files:**
- Create: `GlassTable/Sources/Screens/CallFoldView.swift`
- Modify: `GlassTable/Sources/DesignSystem/Components.swift` (append `SecondaryCTAButton`)
- Modify: `GlassTable/Sources/Screens/HomeView.swift` (placeholder line)

**Interfaces:**
- Consumes: `CallFoldSpot`, `CallFoldSpotGenerator.spot`, `gradeCallFold`, `CallFoldReveal`, `DrillModel`, plus the design system.
- Produces: `CallFoldView`; `SecondaryCTAButton(title:action:)` (neutral surface/ink twin of `PrimaryCTAButton`).

- [ ] **Step 1: Append `SecondaryCTAButton` to `Components.swift`**

```swift
struct SecondaryCTAButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(GT.title(15)).foregroundStyle(GT.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Create `GlassTable/Sources/Screens/CallFoldView.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct CallFoldView: View {
    @State private var model = DrillModel<CallFoldSpot, Bool, CallFoldReveal>(
        slug: DrillKind.callfold.rawValue,
        generate: CallFoldSpotGenerator.spot(baseSeed:index:),
        grade: { gradeCallFold(userCalls: $0, spot: $1) },
        demoAnswer: true)

    private func row(_ cards: [Card]) -> some View {
        HStack(spacing: 7) {
            ForEach(Array(cards.enumerated()), id: \.offset) { PlayingCardView(card: $0.element) }
        }
    }

    private func cardZone(_ spot: CallFoldSpot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "상대 · VILLAIN"); row(spot.villain)
            SectionLabel(text: "보드 · 턴").padding(.top, 10); row(spot.board)
            SectionLabel(text: "내 핸드 · HERO").padding(.top, 10); row(spot.hero)
            Text("팟 \(spot.pot) bb · 벳 \(spot.bet) bb")
                .font(GT.title(15)).foregroundStyle(.white).padding(.top, 12)
        }
    }

    var body: some View {
        Group {
            switch model.phase {
            case let .deciding(spot):
                DrillScaffold(title: "콜/폴드", streak: model.streak) {
                    cardZone(spot)
                } sheet: {
                    VStack(spacing: 15) {
                        VStack(spacing: 3) {
                            Text("콜해야 할까요?").font(GT.title(15)).foregroundStyle(GT.ink)
                            Text("Call or fold?").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                        }
                        HStack(spacing: 10) {
                            SecondaryCTAButton(title: "폴드", action: { model.commit(false) })
                            PrimaryCTAButton(title: "콜", action: { model.commit(true) })
                        }
                    }
                }
            case let .revealed(spot, reveal):
                DrillScaffold(title: "콜/폴드", streak: model.streak) {
                    cardZone(spot)
                } sheet: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 9) {
                            GradePill(band: reveal.band)
                            Text("내 답 \(reveal.userCalls ? "콜" : "폴드") · 정답 \(reveal.correctIsCall ? "콜" : "폴드")")
                                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                        }
                        Text(reveal.whyText)
                            .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                        PrimaryCTAButton(title: "다음 문제", action: model.next)
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview { CallFoldView() }
```

- [ ] **Step 3: Wire into `HomeView.drillView`**

```swift
        case .callfold: CallFoldView()
```

- [ ] **Step 4: Build and screenshot**

```bash
xcodegen generate
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
APP=build/Build/Products/Debug-iphonesimulator/GlassTable.app
xcrun simctl install booted "$APP"
xcrun simctl terminate booted com.michaelju.glasstable.GlassTable 2>/dev/null
SIMCTL_CHILD_GT_DEMO_DRILL=callfold xcrun simctl launch booted com.michaelju.glasstable.GlassTable
xcrun simctl io booted screenshot "$SCRATCHPAD/callfold-decide.png"
xcrun simctl terminate booted com.michaelju.glasstable.GlassTable
SIMCTL_CHILD_GT_DEMO_DRILL=callfold SIMCTL_CHILD_GT_DEMO_REVEAL=1 \
  xcrun simctl launch booted com.michaelju.glasstable.GlassTable
xcrun simctl io booted screenshot "$SCRATCHPAD/callfold-reveal.png"
```

Read both: decide shows three card rows + price + 폴드/콜 button pair; reveal shows pill + 콜/폴드 verdict + why.

- [ ] **Step 5: Commit**

```bash
git add GlassTable
git commit -m "feat(app): call/fold drill + secondary CTA button"
```

---

### Task 9: `BlockerView` + final gate

**Files:**
- Create: `GlassTable/Sources/Screens/BlockerView.swift`
- Modify: `GlassTable/Sources/Screens/HomeView.swift` (last placeholder line)

**Interfaces:**
- Consumes: `BlockerSpot` (`className`, `baseline`, `removed`), `BlockerSpotGenerator.spot`, `gradeBlocker`, `BlockerReveal`, `DrillModel`, design system.
- Produces: `BlockerView`. Note the estimate starts at the *spot's* baseline, so view state is `Int?` resolved lazily per spot.

- [ ] **Step 1: Create `GlassTable/Sources/Screens/BlockerView.swift`**

```swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import SwiftUI
import GlassTableEngine
import GlassTableDrills

struct BlockerView: View {
    @State private var model = DrillModel<BlockerSpot, Int, BlockerReveal>(
        slug: DrillKind.blockers.rawValue,
        generate: BlockerSpotGenerator.spot(baseSeed:index:),
        grade: { gradeBlocker(estimate: $0, spot: $1) },
        demoAnswer: 6)
    // nil = "not touched yet" → falls back to the current spot's class baseline.
    @State private var estimate: Int?

    private func zone(_ spot: BlockerSpot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "제거된 카드 · REMOVED")
            HStack(spacing: 7) {
                ForEach(Array(spot.removed.enumerated()), id: \.offset) {
                    PlayingCardView(card: $0.element)
                }
            }
            Text("남은 \(spot.className) 콤보는?")
                .font(GT.title(20)).foregroundStyle(.white).padding(.top, 16)
        }
    }

    var body: some View {
        Group {
            switch model.phase {
            case let .deciding(spot):
                DrillScaffold(title: "블로커", streak: model.streak) {
                    zone(spot)
                } sheet: {
                    VStack(spacing: 15) {
                        VStack(spacing: 3) {
                            Text("남은 \(spot.className) 콤보는 몇 개?")
                                .font(GT.title(15)).foregroundStyle(GT.ink)
                            Text("Combos remaining?").font(GT.body(11)).foregroundStyle(GT.inkMuted)
                        }
                        EstimateStepper(value: estimate ?? spot.baseline, onAdjust: { d in
                            estimate = max(0, min(16, (estimate ?? spot.baseline) + d))
                        })
                        PrimaryCTAButton(title: "확인하기",
                                         action: { model.commit(estimate ?? spot.baseline) })
                    }
                }
            case let .revealed(spot, reveal):
                DrillScaffold(title: "블로커", streak: model.streak) {
                    zone(spot)
                } sheet: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 9) {
                            GradePill(band: reveal.band)
                            Text("내 답 \(reveal.estimate) · 정답 \(reveal.count)")
                                .font(GT.semibold(14)).foregroundStyle(GT.inkSecondary)
                        }
                        Text(reveal.whyText)
                            .font(GT.body(12.5)).foregroundStyle(GT.inkSecondary)
                            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                            .background(GT.surface, in: RoundedRectangle(cornerRadius: 14))
                        PrimaryCTAButton(title: "다음 문제",
                                         action: { estimate = nil; model.next() })
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview { BlockerView() }
```

- [ ] **Step 2: Wire into `HomeView.drillView`**

```swift
        case .blockers: BlockerView()
```

- [ ] **Step 3: Build and screenshot**

```bash
xcodegen generate
xcodebuild -project GlassTable.xcodeproj -scheme GlassTable \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
APP=build/Build/Products/Debug-iphonesimulator/GlassTable.app
xcrun simctl install booted "$APP"
xcrun simctl terminate booted com.michaelju.glasstable.GlassTable 2>/dev/null
SIMCTL_CHILD_GT_DEMO_DRILL=blockers xcrun simctl launch booted com.michaelju.glasstable.GlassTable
xcrun simctl io booted screenshot "$SCRATCHPAD/blockers-decide.png"
xcrun simctl terminate booted com.michaelju.glasstable.GlassTable
SIMCTL_CHILD_GT_DEMO_DRILL=blockers SIMCTL_CHILD_GT_DEMO_REVEAL=3 \
  xcrun simctl launch booted com.michaelju.glasstable.GlassTable
xcrun simctl io booted screenshot "$SCRATCHPAD/blockers-reveal.png"
```

Read both: decide shows removed cards + class question, stepper starts at the class baseline; reveal shows pill + count + why.

- [ ] **Step 4: Final gate**

```bash
swift test --package-path GlassTableDrills 2>&1 | tail -3
git diff main --stat -- GlassTableEngine
```
Expected: all drills tests pass; the engine diff is EMPTY (if not, run the engine release gate before proceeding).

Launch the plain app once more (no env vars), screenshot, and confirm the home screen now shows streak/accuracy on every drill row that has demo progress.

- [ ] **Step 5: Commit, then finish**

```bash
git add -A
git commit -m "feat(app): blocker drill; all five drills live behind home navigation"
```

Announce and use **superpowers:finishing-a-development-branch** (tests already verified; expected outcome per project convention: merge to main + push).
