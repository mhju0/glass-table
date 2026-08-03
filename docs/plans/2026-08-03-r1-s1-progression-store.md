# R1 sub-project 1 — Progression store + migration (implementation plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the five per-drill `DrillProgress` files with one durable, atomic,
migration-aware `Codable` store that can carry mastery, review scheduling, streak, and
calibration data.

**Architecture:** All plain Swift in `GlassTableDrills` — no SwiftData, no third-party
deps, no simulator needed to test. `ProgressState` is a value type holding the whole
persisted state; `ProgressionStore` owns file I/O with atomic writes and a load result
that distinguishes *no file yet* from *file failed to parse*. Legacy per-drill files
fold in once. Record **shapes** land here; the **logic** that mutates them (mastery
promotion, FSRS scheduling, streak rules) is sub-project 2.

**Tech Stack:** Swift 5.9 language mode, XCTest, Foundation `JSONEncoder`/`JSONDecoder`.

## Global Constraints

- Spec: `docs/specs/2026-08-03-r1-progression-shell-design.md` §8.
- **Zero third-party dependencies.** `GlassTableDrills` depends only on `GlassTableEngine`.
- **No `import SwiftData`, no `import UIKit`, no `import SwiftUI`** in this package — it
  must stay testable without a simulator.
- All writes use `options: [.atomic]`. `save` throws; it must never silently swallow.
- `load()` must never silently return empty state for a corrupt file.
- Answer log is a **capped ring buffer of 500 entries**.
- `schemaVersion` starts at `1`.
- Every new file carries the header `// Copyright (c) 2026 Michael Ju (github.com/mhju0)`.
- Korean user-facing strings are out of scope here — this sub-project has no UI.
- Run tests with `swift test --package-path GlassTableDrills`.

## File structure

| File | Responsibility |
|---|---|
| `Sources/GlassTableDrills/Progression/Concept.swift` | The concept vocabulary (`enum Concept`) and mastery tiers. |
| `Sources/GlassTableDrills/Progression/DayKey.swift` | Calendar-day identity for streak logic, timezone/DST safe. |
| `Sources/GlassTableDrills/Progression/ProgressState.swift` | The whole persisted value type + its records + ring-buffer append. |
| `Sources/GlassTableDrills/Progression/ProgressionStore.swift` | Atomic file I/O, `StoreLoad`, corrupt-file quarantine, export/import. |
| `Sources/GlassTableDrills/Progression/LegacyMigration.swift` | One-time fold-in of the five `*-progress.json` files. |

`Sources/GlassTableDrills/Progress.swift` is **left untouched** — `LegacyMigration`
reads it, and the shipped drills keep using it until sub-project 4 rewires them.

---

### Task 1: Concept vocabulary and mastery tiers

**Files:**
- Create: `GlassTableDrills/Sources/GlassTableDrills/Progression/Concept.swift`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/ConceptTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `enum Concept: String, CaseIterable, Codable, Sendable` with cases
  `showdown, potMath, position, combos, potOdds, outs, equitySense, evCall, callFold, mdf`;
  `enum MasteryTier: String, Codable, CaseIterable, Comparable, Sendable` with cases
  `attempted, familiar, proficient, mastered`; `Concept.isEstimation: Bool`.

- [ ] **Step 1: Write the failing test**

```swift
// ConceptTests.swift
import XCTest
@testable import GlassTableDrills

final class ConceptTests: XCTestCase {
    func testRosterIsTheTenR1Concepts() {
        XCTAssertEqual(Concept.allCases.count, 10)
        XCTAssertEqual(Set(Concept.allCases.map(\.rawValue)),
                       ["showdown", "potMath", "position", "combos", "potOdds",
                        "outs", "equitySense", "evCall", "callFold", "mdf"])
    }

    /// Spec §5.4: interval input only where the answer is genuinely estimated.
    func testOnlyEstimationConceptsTakeAnInterval() {
        XCTAssertEqual(Set(Concept.allCases.filter(\.isEstimation)),
                       [.equitySense, .evCall, .outs])
        for c in [Concept.showdown, .potMath, .position, .combos, .potOdds, .callFold, .mdf] {
            XCTAssertFalse(c.isEstimation, "\(c.rawValue) has an exact answer")
        }
    }

    func testMasteryTiersOrderLowToHigh() {
        XCTAssertEqual(MasteryTier.allCases, [.attempted, .familiar, .proficient, .mastered])
        XCTAssertLessThan(MasteryTier.attempted, MasteryTier.familiar)
        XCTAssertLessThan(MasteryTier.familiar, MasteryTier.proficient)
        XCTAssertLessThan(MasteryTier.proficient, MasteryTier.mastered)
        XCTAssertEqual(max(MasteryTier.familiar, .proficient), .proficient)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path GlassTableDrills --filter ConceptTests`
Expected: FAIL — `cannot find 'Concept' in scope`.

- [ ] **Step 3: Write minimal implementation**

```swift
// Concept.swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)

/// The R1 concept vocabulary. Concepts are what mastery, review scheduling and
/// calibration are tracked against — *not* drills and *not* nodes, because the same
/// concept can be exercised by several nodes (spec §4.3).
///
/// `mdf` has no path node in R1 (spec §3.2 parks it for Block B) but keeps a concept
/// so 자유 연습 progress on the shipped MDF drill is still recorded.
public enum Concept: String, CaseIterable, Codable, Sendable {
    case showdown, potMath, position, combos
    case potOdds, outs, equitySense, evCall, callFold
    case mdf
}

extension Concept {
    /// Spec §5.4. `true` → answered with a point estimate plus a 90% interval and
    /// scored by the Winkler rule; `false` → single exact value, binary grade.
    ///
    /// `outs` is here for its *equity* half only. The out **count** is exact and is
    /// graded exactly; the rule-of-2/4 equity derived from it is explicitly an
    /// approximation, which is already how the reveal presents it.
    public var isEstimation: Bool {
        switch self {
        case .equitySense, .evCall, .outs: return true
        case .showdown, .potMath, .position, .combos, .potOdds, .callFold, .mdf: return false
        }
    }
}

/// Spec §4.3. Ordered low → high; `mastered` is reachable only through a boss node.
public enum MasteryTier: String, Codable, CaseIterable, Comparable, Sendable {
    case attempted, familiar, proficient, mastered

    public static func < (a: MasteryTier, b: MasteryTier) -> Bool {
        guard let i = allCases.firstIndex(of: a), let j = allCases.firstIndex(of: b)
        else { return false }
        return i < j
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path GlassTableDrills --filter ConceptTests`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add GlassTableDrills/Sources/GlassTableDrills/Progression/Concept.swift \
        GlassTableDrills/Tests/GlassTableDrillsTests/ConceptTests.swift
git commit -m "feat(progression): concept vocabulary and mastery tiers"
```

---

### Task 2: DayKey — timezone-safe calendar-day identity

Streak logic compares *days*, not instants. `Date` arithmetic on 86400-second
boundaries breaks across DST. `DayKey` is the whole defence, so it is its own task.

**Files:**
- Create: `GlassTableDrills/Sources/GlassTableDrills/Progression/DayKey.swift`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/DayKeyTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `struct DayKey: Codable, Hashable, Comparable, CustomStringConvertible, Sendable`
  with `init(_ date: Date, calendar: Calendar = .current)`,
  `init?(raw: String)`, `var raw: String`, and
  `func daysBetween(_ other: DayKey, calendar: Calendar = .current) -> Int?`.

- [ ] **Step 1: Write the failing test**

```swift
// DayKeyTests.swift
import XCTest
@testable import GlassTableDrills

final class DayKeyTests: XCTestCase {
    /// Fixed calendar so these assertions can't drift with the machine's locale.
    private func seoul() -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return c
    }
    private func date(_ iso: String, _ cal: Calendar) -> Date {
        let f = ISO8601DateFormatter()
        f.timeZone = cal.timeZone
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso)!
    }

    func testRawIsSortableYearMonthDay() {
        let cal = seoul()
        XCTAssertEqual(DayKey(date("2026-08-03T09:00:00+09:00", cal), calendar: cal).raw,
                       "2026-08-03")
        // Zero-padded so lexicographic order matches chronological order.
        XCTAssertEqual(DayKey(date("2026-01-05T23:59:00+09:00", cal), calendar: cal).raw,
                       "2026-01-05")
    }

    func testSameCalendarDayAcrossHoursIsOneKey() {
        let cal = seoul()
        let morning = DayKey(date("2026-08-03T00:00:00+09:00", cal), calendar: cal)
        let night = DayKey(date("2026-08-03T23:59:59+09:00", cal), calendar: cal)
        XCTAssertEqual(morning, night)
    }

    func testMidnightRollsToTheNextDay() {
        let cal = seoul()
        let before = DayKey(date("2026-08-03T23:59:59+09:00", cal), calendar: cal)
        let after = DayKey(date("2026-08-04T00:00:01+09:00", cal), calendar: cal)
        XCTAssertNotEqual(before, after)
        XCTAssertLessThan(before, after)
        XCTAssertEqual(before.daysBetween(after, calendar: cal), 1)
    }

    /// The reason DayKey exists: a DST "spring forward" day is 23 hours long, so
    /// dividing an interval by 86400 would report 0 days between consecutive days.
    func testDSTTransitionStillCountsAsOneDay() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        // 2026-03-08 is US spring-forward; that local day is only 23 hours long.
        let before = DayKey(date("2026-03-08T12:00:00-05:00", cal), calendar: cal)
        let after = DayKey(date("2026-03-09T12:00:00-04:00", cal), calendar: cal)
        XCTAssertEqual(before.raw, "2026-03-08")
        XCTAssertEqual(after.raw, "2026-03-09")
        XCTAssertEqual(before.daysBetween(after, calendar: cal), 1)
    }

    func testGapOfMoreThanOneDay() {
        let cal = seoul()
        let a = DayKey(date("2026-08-01T10:00:00+09:00", cal), calendar: cal)
        let b = DayKey(date("2026-08-05T10:00:00+09:00", cal), calendar: cal)
        XCTAssertEqual(a.daysBetween(b, calendar: cal), 4)
        XCTAssertEqual(b.daysBetween(a, calendar: cal), -4)
    }

    func testRoundTripsThroughCodableAndRawString() throws {
        let cal = seoul()
        let key = DayKey(date("2026-08-03T09:00:00+09:00", cal), calendar: cal)
        let decoded = try JSONDecoder().decode(DayKey.self,
                                               from: JSONEncoder().encode(key))
        XCTAssertEqual(decoded, key)
        XCTAssertEqual(DayKey(raw: "2026-08-03"), key)
        XCTAssertNil(DayKey(raw: "not-a-day"))
        XCTAssertNil(DayKey(raw: "2026-13-01"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path GlassTableDrills --filter DayKeyTests`
Expected: FAIL — `cannot find 'DayKey' in scope`.

- [ ] **Step 3: Write minimal implementation**

```swift
// DayKey.swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// A calendar day in the user's own timezone, stored as "yyyy-MM-dd".
///
/// Streaks compare days, not instants. Doing that with `Date` and 86400-second
/// arithmetic is wrong twice a year: a spring-forward day is 23 hours long, so two
/// consecutive days can measure < 1 day apart and silently break a streak. Every
/// day comparison in the app goes through this type.
///
/// The raw form is zero-padded so lexicographic order matches chronological order,
/// and it is human-readable in the JSON store — which is half the point of choosing
/// a plain file (spec §8.1).
public struct DayKey: Codable, Hashable, Comparable, CustomStringConvertible, Sendable {
    public let raw: String

    public init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.raw = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Fails on anything that isn't a real "yyyy-MM-dd" date, so a hand-edited or
    /// corrupted store can't smuggle in a key that later comparisons misread.
    public init?(raw: String) {
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              (1...12).contains(m), (1...31).contains(d)
        else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        guard cal.date(from: DateComponents(year: y, month: m, day: d)) != nil
        else { return nil }
        self.raw = raw
    }

    public var description: String { raw }
    public static func < (a: DayKey, b: DayKey) -> Bool { a.raw < b.raw }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let key = DayKey(raw: raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "bad DayKey \(raw)"))
        }
        self = key
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }

    /// Whole calendar days from `self` to `other`; negative if `other` is earlier.
    public func daysBetween(_ other: DayKey, calendar: Calendar = .current) -> Int? {
        guard let a = startOfDay(calendar), let b = other.startOfDay(calendar) else { return nil }
        return calendar.dateComponents([.day], from: a, to: b).day
    }

    private func startOfDay(_ calendar: Calendar) -> Date? {
        let p = raw.split(separator: "-")
        guard p.count == 3, let y = Int(p[0]), let m = Int(p[1]), let d = Int(p[2])
        else { return nil }
        return calendar.date(from: DateComponents(year: y, month: m, day: d))
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path GlassTableDrills --filter DayKeyTests`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add GlassTableDrills/Sources/GlassTableDrills/Progression/DayKey.swift \
        GlassTableDrills/Tests/GlassTableDrillsTests/DayKeyTests.swift
git commit -m "feat(progression): timezone-safe DayKey for streak arithmetic"
```

---

### Task 3: ProgressState and the capped answer log

**Files:**
- Create: `GlassTableDrills/Sources/GlassTableDrills/Progression/ProgressState.swift`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/ProgressStateTests.swift`

**Interfaces:**
- Consumes: `Concept`, `MasteryTier`, `DayKey`.
- Produces: `ProgressState` (with `schemaVersion`, `concepts: [String: ConceptRecord]`,
  `nodes: [String: NodeRecord]`, `streak: StreakRecord`, `answers: [AnswerRecord]`),
  `ConceptRecord`, `ReviewState`, `NodeRecord`, `StreakRecord`, `AnswerRecord`,
  `IntervalAnswer`, `ProgressState.answerLogCap`, and the accessors
  `record(for:)`, `updateRecord(for:_:)`, `append(_ answer:)`.

- [ ] **Step 1: Write the failing test**

```swift
// ProgressStateTests.swift
import XCTest
@testable import GlassTableDrills

final class ProgressStateTests: XCTestCase {
    func testEmptyStateHasCurrentSchemaVersionAndNoRecords() {
        let s = ProgressState()
        XCTAssertEqual(s.schemaVersion, ProgressState.currentSchemaVersion)
        XCTAssertEqual(s.schemaVersion, 1)
        XCTAssertTrue(s.concepts.isEmpty)
        XCTAssertTrue(s.nodes.isEmpty)
        XCTAssertTrue(s.answers.isEmpty)
        XCTAssertEqual(s.streak.current, 0)
        XCTAssertEqual(s.streak.freezesRemaining, 2)   // spec §7.1: two auto freezes
    }

    /// An untouched concept reads as a default record rather than nil, so callers
    /// never branch on "has this been seen" just to read a count.
    func testUntouchedConceptReadsAsDefaultRecord() {
        let s = ProgressState()
        XCTAssertEqual(s.record(for: .outs), ConceptRecord())
        XCTAssertEqual(s.record(for: .outs).tier, .attempted)
        XCTAssertEqual(s.record(for: .outs).total, 0)
    }

    func testUpdateRecordWritesThrough() {
        var s = ProgressState()
        s.updateRecord(for: .outs) { $0.total = 4; $0.correct = 3 }
        XCTAssertEqual(s.record(for: .outs).total, 4)
        XCTAssertEqual(s.record(for: .outs).correct, 3)
        XCTAssertEqual(s.concepts["outs"]?.total, 4)
    }

    func testAnswerLogIsACappedRingBufferKeepingTheNewest() {
        var s = ProgressState()
        for i in 0..<(ProgressState.answerLogCap + 50) {
            s.append(AnswerRecord(concept: .outs,
                                  at: Date(timeIntervalSince1970: Double(i)),
                                  correct: true))
        }
        XCTAssertEqual(s.answers.count, ProgressState.answerLogCap)
        // Oldest dropped, newest kept, order preserved.
        XCTAssertEqual(s.answers.first?.at, Date(timeIntervalSince1970: 50))
        XCTAssertEqual(s.answers.last?.at,
                       Date(timeIntervalSince1970: Double(ProgressState.answerLogCap + 49)))
    }

    func testRoundTripsThroughCodable() throws {
        var s = ProgressState()
        s.updateRecord(for: .equitySense) {
            $0.tier = .proficient
            $0.total = 12; $0.correct = 10; $0.consecutiveMisses = 1
            $0.review.stability = 4.5; $0.review.difficulty = 6.0; $0.review.reps = 3
        }
        s.nodes["u1-position"] = NodeRecord(cleared: true, attempts: 2)
        s.streak.current = 12
        s.append(AnswerRecord(concept: .equitySense, at: Date(timeIntervalSince1970: 1),
                              correct: false,
                              interval: IntervalAnswer(point: 40, lo: 35, hi: 45, truth: 52)))
        let decoded = try JSONDecoder().decode(
            ProgressState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(decoded, s)
    }

    /// A concept removed in a future version must not make the whole store unreadable.
    func testUnknownConceptKeysSurviveDecodingAndAreIgnoredByTypedAccess() throws {
        let json = """
        {"schemaVersion":1,
         "concepts":{"outs":{"tier":"familiar","review":{"stability":0,"difficulty":5,\
"reps":0,"lapses":0},"correct":1,"total":2,"consecutiveMisses":0},
                     "someRetiredConcept":{"tier":"mastered","review":{"stability":0,\
"difficulty":5,"reps":0,"lapses":0},"correct":9,"total":9,"consecutiveMisses":0}},
         "nodes":{},
         "streak":{"current":0,"longest":0,"freezesRemaining":2},
         "answers":[]}
        """.data(using: .utf8)!
        let s = try JSONDecoder().decode(ProgressState.self, from: json)
        XCTAssertEqual(s.record(for: .outs).tier, .familiar)
        XCTAssertEqual(s.concepts.count, 2)                 // the unknown key is preserved
        XCTAssertNotNil(s.concepts["someRetiredConcept"])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path GlassTableDrills --filter ProgressStateTests`
Expected: FAIL — `cannot find 'ProgressState' in scope`.

- [ ] **Step 3: Write minimal implementation**

```swift
// ProgressState.swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// FSRS memory state for one concept (spec §4.5). Shapes only — the scheduler that
/// advances these lives in sub-project 2.
public struct ReviewState: Codable, Equatable, Sendable {
    public var stability: Double     // days
    public var difficulty: Double    // 1...10, FSRS scale
    public var lastReview: Date?
    public var due: Date?
    public var reps: Int
    public var lapses: Int

    public init(stability: Double = 0, difficulty: Double = 5, lastReview: Date? = nil,
                due: Date? = nil, reps: Int = 0, lapses: Int = 0) {
        self.stability = stability; self.difficulty = difficulty
        self.lastReview = lastReview; self.due = due
        self.reps = reps; self.lapses = lapses
    }
}

/// Per-concept mastery and scheduling (spec §4.3, §4.5, §4.6).
public struct ConceptRecord: Codable, Equatable, Sendable {
    public var tier: MasteryTier
    public var review: ReviewState
    public var correct: Int
    public var total: Int
    /// Drives the 3-miss 천천히 offer and the 8-miss stop-drilling rule (spec §4.6).
    public var consecutiveMisses: Int
    /// When 능숙 was reached — the 12h 숙달 cooldown counts from here (spec §4.3).
    public var proficientAt: Date?
    public var masteredAt: Date?

    public init(tier: MasteryTier = .attempted, review: ReviewState = ReviewState(),
                correct: Int = 0, total: Int = 0, consecutiveMisses: Int = 0,
                proficientAt: Date? = nil, masteredAt: Date? = nil) {
        self.tier = tier; self.review = review
        self.correct = correct; self.total = total
        self.consecutiveMisses = consecutiveMisses
        self.proficientAt = proficientAt; self.masteredAt = masteredAt
    }

    public var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
}

/// Per-node completion. Unlock state is *derived* from the curriculum plus these
/// flags rather than stored, so there is no second source of truth to drift.
public struct NodeRecord: Codable, Equatable, Sendable {
    public var cleared: Bool
    public var clearedAt: Date?
    public var attempts: Int

    public init(cleared: Bool = false, clearedAt: Date? = nil, attempts: Int = 0) {
        self.cleared = cleared; self.clearedAt = clearedAt; self.attempts = attempts
    }
}

/// Spec §7.1: a streak day is "a session including at least one due item", and
/// forgiveness is silent — two auto-equipped freezes with a 48h earn-back.
public struct StreakRecord: Codable, Equatable, Sendable {
    public var current: Int
    public var longest: Int
    public var lastSessionDay: DayKey?
    public var freezesRemaining: Int
    public var lastFreezeEarnedDay: DayKey?

    public static let maxFreezes = 2

    public init(current: Int = 0, longest: Int = 0, lastSessionDay: DayKey? = nil,
                freezesRemaining: Int = StreakRecord.maxFreezes,
                lastFreezeEarnedDay: DayKey? = nil) {
        self.current = current; self.longest = longest
        self.lastSessionDay = lastSessionDay
        self.freezesRemaining = freezesRemaining
        self.lastFreezeEarnedDay = lastFreezeEarnedDay
    }
}

/// A point estimate plus its stated 90% interval, and the truth it was scored against
/// (spec §5.4). Kept alongside the answer so calibration can be recomputed if the
/// scoring rule is ever retuned.
public struct IntervalAnswer: Codable, Equatable, Sendable {
    public var point: Double
    public var lo: Double
    public var hi: Double
    public var truth: Double

    public init(point: Double, lo: Double, hi: Double, truth: Double) {
        self.point = point; self.lo = lo; self.hi = hi; self.truth = truth
    }
    public var containsTruth: Bool { truth >= lo && truth <= hi }
}

/// One graded answer. `interval` is nil for exact concepts.
public struct AnswerRecord: Codable, Equatable, Sendable {
    public var concept: String
    public var at: Date
    public var correct: Bool
    public var interval: IntervalAnswer?

    public init(concept: Concept, at: Date, correct: Bool, interval: IntervalAnswer? = nil) {
        self.concept = concept.rawValue; self.at = at
        self.correct = correct; self.interval = interval
    }
}

/// Everything the app persists, as one value type (spec §8.1). Roughly 50 KB at full
/// size, so it is loaded whole and kept in memory; no query here needs an index.
public struct ProgressState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    /// Ring-buffer cap for the answer log. Bounded on purpose — an unbounded history
    /// is the one thing that would make a single-file store the wrong choice.
    public static let answerLogCap = 500

    public var schemaVersion: Int
    /// Keyed by `Concept.rawValue` rather than by `Concept` so a concept retired in a
    /// later version can't make the whole store fail to decode.
    public var concepts: [String: ConceptRecord]
    public var nodes: [String: NodeRecord]
    public var streak: StreakRecord
    public var answers: [AnswerRecord]

    public init(schemaVersion: Int = ProgressState.currentSchemaVersion,
                concepts: [String: ConceptRecord] = [:],
                nodes: [String: NodeRecord] = [:],
                streak: StreakRecord = StreakRecord(),
                answers: [AnswerRecord] = []) {
        self.schemaVersion = schemaVersion; self.concepts = concepts
        self.nodes = nodes; self.streak = streak; self.answers = answers
    }

    public func record(for concept: Concept) -> ConceptRecord {
        concepts[concept.rawValue] ?? ConceptRecord()
    }

    public mutating func updateRecord(for concept: Concept,
                                      _ mutate: (inout ConceptRecord) -> Void) {
        var r = record(for: concept)
        mutate(&r)
        concepts[concept.rawValue] = r
    }

    /// Appends and trims from the front, so the log always holds the newest
    /// `answerLogCap` answers in chronological order.
    public mutating func append(_ answer: AnswerRecord) {
        answers.append(answer)
        if answers.count > Self.answerLogCap {
            answers.removeFirst(answers.count - Self.answerLogCap)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path GlassTableDrills --filter ProgressStateTests`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add GlassTableDrills/Sources/GlassTableDrills/Progression/ProgressState.swift \
        GlassTableDrills/Tests/GlassTableDrillsTests/ProgressStateTests.swift
git commit -m "feat(progression): ProgressState value type with capped answer log"
```

---

### Task 4: ProgressionStore — atomic writes, honest load, corrupt quarantine

This is where spec §8.2's live bug gets fixed. Two failure modes must be
distinguishable: **no file yet** (a new user, start empty) and **file won't parse**
(a returning user whose data must not be silently discarded).

**Files:**
- Create: `GlassTableDrills/Sources/GlassTableDrills/Progression/ProgressionStore.swift`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/ProgressionStoreTests.swift`

**Interfaces:**
- Consumes: `ProgressState`.
- Produces: `enum StoreLoad { case fresh, loaded(ProgressState), unreadable(String) }`;
  `struct ProgressionStore` with `init(url: URL)`, `static func standard() -> ProgressionStore`,
  `func load() -> StoreLoad`, `func save(_ state: ProgressState) throws`,
  `func quarantineCorruptFile() throws -> URL`, `func exportData() throws -> Data`,
  `func importData(_ data: Data) throws -> ProgressState`.

- [ ] **Step 1: Write the failing test**

```swift
// ProgressionStoreTests.swift
import XCTest
@testable import GlassTableDrills

final class ProgressionStoreTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gt-store-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }
    private func store() -> ProgressionStore {
        ProgressionStore(url: dir.appendingPathComponent("progress.json"))
    }

    func testMissingFileLoadsAsFreshNotAsEmptyLoaded() {
        guard case .fresh = store().load() else {
            return XCTFail("a first launch must report .fresh")
        }
    }

    func testSaveThenLoadRoundTrips() throws {
        let s = store()
        var state = ProgressState()
        state.updateRecord(for: .outs) { $0.total = 7; $0.correct = 5; $0.tier = .familiar }
        state.streak.current = 3
        try s.save(state)
        guard case let .loaded(back) = s.load() else { return XCTFail("expected .loaded") }
        XCTAssertEqual(back, state)
    }

    /// Spec §8.2 — the bug being fixed. Garbage must never read as empty progress.
    func testCorruptFileReportsUnreadableAndNeverSilentlyResets() throws {
        let s = store()
        try s.save(ProgressState())
        try Data("{ this is not json".utf8)
            .write(to: dir.appendingPathComponent("progress.json"))
        guard case .unreadable = s.load() else {
            return XCTFail("a corrupt file must report .unreadable, not .fresh/.loaded")
        }
    }

    func testTruncatedFileAlsoReportsUnreadable() throws {
        let s = store()
        var state = ProgressState()
        state.updateRecord(for: .outs) { $0.total = 3 }
        try s.save(state)
        let url = dir.appendingPathComponent("progress.json")
        let full = try Data(contentsOf: url)
        try full.prefix(full.count / 2).write(to: url)   // simulate a kill mid-write
        guard case .unreadable = s.load() else { return XCTFail("expected .unreadable") }
    }

    func testQuarantineMovesTheBadFileAsideSoTheNextLoadIsFresh() throws {
        let s = store()
        let url = dir.appendingPathComponent("progress.json")
        try Data("{ bad".utf8).write(to: url)
        let moved = try s.quarantineCorruptFile()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: moved.path))
        XCTAssertEqual(try Data(contentsOf: moved), Data("{ bad".utf8))
        guard case .fresh = s.load() else { return XCTFail("expected .fresh after quarantine") }
    }

    func testSaveIsAtomicSoAFailedWriteLeavesThePreviousFileIntact() throws {
        let s = store()
        var good = ProgressState()
        good.streak.current = 9
        try s.save(good)
        // Writing to a path whose parent does not exist must throw, not truncate.
        let bad = ProgressionStore(url: dir.appendingPathComponent("nope/progress.json"))
        XCTAssertThrowsError(try bad.save(ProgressState()))
        guard case let .loaded(back) = s.load() else { return XCTFail("expected .loaded") }
        XCTAssertEqual(back.streak.current, 9)
    }

    func testExportProducesTheStoreBytesAndImportValidates() throws {
        let s = store()
        var state = ProgressState()
        state.updateRecord(for: .potOdds) { $0.total = 5 }
        try s.save(state)

        let exported = try s.exportData()
        XCTAssertEqual(try JSONDecoder().decode(ProgressState.self, from: exported), state)

        let imported = try s.importData(exported)
        XCTAssertEqual(imported, state)
        XCTAssertThrowsError(try s.importData(Data("nonsense".utf8)))
    }

    func testImportRejectsAFutureSchemaVersion() throws {
        let s = store()
        var future = ProgressState()
        future.schemaVersion = ProgressState.currentSchemaVersion + 1
        let data = try JSONEncoder().encode(future)
        XCTAssertThrowsError(try s.importData(data)) { error in
            XCTAssertEqual(error as? StoreError, .unsupportedSchemaVersion(
                found: ProgressState.currentSchemaVersion + 1,
                supported: ProgressState.currentSchemaVersion))
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path GlassTableDrills --filter ProgressionStoreTests`
Expected: FAIL — `cannot find 'ProgressionStore' in scope`.

- [ ] **Step 3: Write minimal implementation**

```swift
// ProgressionStore.swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

public enum StoreError: Error, Equatable {
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case notDecodable
}

/// Outcome of reading the store. The three cases exist so that "no file yet" and
/// "file is there but unreadable" can never be confused: the old code answered both
/// with empty progress, which silently erased a returning user (spec §8.2).
public enum StoreLoad {
    case fresh
    case loaded(ProgressState)
    case unreadable(String)
}

public struct ProgressionStore {
    public let url: URL
    public init(url: URL) { self.url = url }

    /// One file in Application Support, replacing the five per-drill files.
    public static func standard() -> ProgressionStore {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory,
                                           in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return ProgressionStore(url: dir.appendingPathComponent("progression.json"))
    }

    public func load() -> StoreLoad {
        guard FileManager.default.fileExists(atPath: url.path) else { return .fresh }
        do {
            let state = try JSONDecoder().decode(ProgressState.self,
                                                 from: Data(contentsOf: url))
            return .loaded(state)
        } catch {
            return .unreadable(String(describing: error))
        }
    }

    /// Atomic so a kill mid-write can never truncate the live file: Foundation writes
    /// to a sibling temp file and renames, and rename is atomic on APFS. Throws rather
    /// than swallowing, because a save that silently fails is how progress disappears.
    public func save(_ state: ProgressState) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]   // stable bytes → clean diffs
        try encoder.encode(state).write(to: url, options: [.atomic])
    }

    /// Moves an unreadable file aside and returns where it went, so "start fresh" is
    /// an explicit user choice that still preserves the bytes for recovery.
    @discardableResult
    public func quarantineCorruptFile() throws -> URL {
        let stamp = Int(Date().timeIntervalSince1970)
        let dest = url.deletingPathExtension()
            .appendingPathExtension("corrupt-\(stamp).json")
        try FileManager.default.moveItem(at: url, to: dest)
        return dest
    }

    /// The store file *is* the export format (spec §8.1), so this is a straight read.
    public func exportData() throws -> Data { try Data(contentsOf: url) }

    /// Validates before returning; the caller decides whether to `save` the result.
    public func importData(_ data: Data) throws -> ProgressState {
        let state: ProgressState
        do { state = try JSONDecoder().decode(ProgressState.self, from: data) }
        catch { throw StoreError.notDecodable }
        guard state.schemaVersion <= ProgressState.currentSchemaVersion else {
            throw StoreError.unsupportedSchemaVersion(
                found: state.schemaVersion, supported: ProgressState.currentSchemaVersion)
        }
        return state
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path GlassTableDrills --filter ProgressionStoreTests`
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add GlassTableDrills/Sources/GlassTableDrills/Progression/ProgressionStore.swift \
        GlassTableDrills/Tests/GlassTableDrillsTests/ProgressionStoreTests.swift
git commit -m "feat(progression): atomic store with honest load and corrupt quarantine"
```

---

### Task 5: Legacy migration from the five per-drill files

**Files:**
- Create: `GlassTableDrills/Sources/GlassTableDrills/Progression/LegacyMigration.swift`
- Test: `GlassTableDrills/Tests/GlassTableDrillsTests/LegacyMigrationTests.swift`

**Interfaces:**
- Consumes: `DrillProgress` and `ProgressStore` from the existing `Progress.swift`;
  `ProgressState`, `Concept`.
- Produces: `enum LegacyMigration` with
  `static let drillKeyToConcept: [String: Concept]` and
  `static func migrate(from directory: URL, into state: ProgressState) -> ProgressState`.

- [ ] **Step 1: Write the failing test**

```swift
// LegacyMigrationTests.swift
import XCTest
@testable import GlassTableDrills

final class LegacyMigrationTests: XCTestCase {
    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gt-legacy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: dir) }

    private func writeLegacy(_ drill: String, _ p: DrillProgress) throws {
        try JSONEncoder().encode(p)
            .write(to: dir.appendingPathComponent("\(drill)-progress.json"))
    }

    func testFoldsEachLegacyDrillIntoItsConcept() throws {
        try writeLegacy("outs", DrillProgress(streak: 4, correct: 9, total: 12))
        try writeLegacy("potodds", DrillProgress(streak: 0, correct: 3, total: 5))
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.record(for: .outs).correct, 9)
        XCTAssertEqual(s.record(for: .outs).total, 12)
        XCTAssertEqual(s.record(for: .potOdds).correct, 3)
        XCTAssertEqual(s.record(for: .potOdds).total, 5)
    }

    /// Spec §3.2 / §8.3: 블로커 was always combinatorics, so its history is 콤보's.
    func testBlockersHistoryBecomesCombos() throws {
        try writeLegacy("blockers", DrillProgress(streak: 2, correct: 6, total: 8))
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.record(for: .combos).correct, 6)
        XCTAssertEqual(s.record(for: .combos).total, 8)
        XCTAssertNil(s.concepts["blockers"])
    }

    /// MDF is parked from the path but its 자유 연습 history is not thrown away.
    func testParkedMdfHistoryIsStillCarried() throws {
        try writeLegacy("mdf", DrillProgress(streak: 1, correct: 2, total: 4))
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.record(for: .mdf).total, 4)
    }

    func testHighestLegacyStreakSeedsTheStreakCount() throws {
        try writeLegacy("outs", DrillProgress(streak: 4, correct: 9, total: 12))
        try writeLegacy("callfold", DrillProgress(streak: 11, correct: 20, total: 25))
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.streak.longest, 11)
    }

    func testTierIsDerivedFromLegacyAccuracy() throws {
        try writeLegacy("outs", DrillProgress(streak: 0, correct: 9, total: 10))     // 90%
        try writeLegacy("potodds", DrillProgress(streak: 0, correct: 2, total: 10))  // 20%
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s.record(for: .outs).tier, .familiar)      // >= 70%
        XCTAssertEqual(s.record(for: .potOdds).tier, .attempted)  // < 70%
        // 능숙/숙달 are earned in-app only; migration never grants them.
        for c in Concept.allCases { XCTAssertLessThan(s.record(for: c).tier, .proficient) }
    }

    func testNoLegacyFilesLeavesStateUntouched() {
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertEqual(s, ProgressState())
    }

    func testEmptyLegacyProgressIsSkippedRatherThanCreatingBlankRecords() throws {
        try writeLegacy("outs", DrillProgress())   // never played
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertTrue(s.concepts.isEmpty)
    }

    /// Migration must not clobber real progress if it is ever run twice.
    func testDoesNotOverwriteAConceptThatAlreadyHasState() throws {
        try writeLegacy("outs", DrillProgress(streak: 4, correct: 9, total: 12))
        var existing = ProgressState()
        existing.updateRecord(for: .outs) { $0.total = 99; $0.correct = 90; $0.tier = .mastered }
        let s = LegacyMigration.migrate(from: dir, into: existing)
        XCTAssertEqual(s.record(for: .outs).total, 99)
        XCTAssertEqual(s.record(for: .outs).tier, .mastered)
    }

    func testCorruptLegacyFileIsSkippedNotFatal() throws {
        try Data("{ bad".utf8).write(to: dir.appendingPathComponent("outs-progress.json"))
        try writeLegacy("potodds", DrillProgress(streak: 0, correct: 3, total: 5))
        let s = LegacyMigration.migrate(from: dir, into: ProgressState())
        XCTAssertTrue(s.concepts["outs"] == nil)
        XCTAssertEqual(s.record(for: .potOdds).total, 5)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path GlassTableDrills --filter LegacyMigrationTests`
Expected: FAIL — `cannot find 'LegacyMigration' in scope`.

- [ ] **Step 3: Write minimal implementation**

```swift
// LegacyMigration.swift
// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import Foundation

/// One-time fold-in of the five M1 `<drill>-progress.json` files (spec §8.3).
///
/// Old files are read, never deleted — they stay on disk unread for one release so a
/// downgrade or a botched migration is recoverable.
public enum LegacyMigration {
    /// `blockers` → `combos` is the rename from spec §3.2: the drill was always
    /// combinatorics, so its history belongs to 콤보.
    public static let drillKeyToConcept: [String: Concept] = [
        "outs": .outs,
        "potodds": .potOdds,
        "callfold": .callFold,
        "mdf": .mdf,
        "blockers": .combos,
    ]

    public static func migrate(from directory: URL, into state: ProgressState) -> ProgressState {
        var out = state
        var bestStreak = 0

        for (key, concept) in drillKeyToConcept.sorted(by: { $0.key < $1.key }) {
            let url = directory.appendingPathComponent("\(key)-progress.json")
            guard let data = try? Data(contentsOf: url),
                  let legacy = try? JSONDecoder().decode(DrillProgress.self, from: data),
                  legacy.total > 0                       // never played → nothing to carry
            else { continue }
            bestStreak = max(bestStreak, legacy.streak)
            // Never clobber state the app has already written for this concept.
            guard out.concepts[concept.rawValue] == nil else { continue }
            out.updateRecord(for: concept) {
                $0.correct = legacy.correct
                $0.total = legacy.total
                // Accuracy maps onto the two *earnable-by-drilling* tiers only.
                // 능숙 needs a clean run and 숙달 needs a boss node (spec §4.3), and
                // neither can be inferred from a bare correct/total pair.
                $0.tier = legacy.accuracy >= 0.7 ? .familiar : .attempted
            }
        }

        out.streak.longest = max(out.streak.longest, bestStreak)
        return out
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path GlassTableDrills --filter LegacyMigrationTests`
Expected: PASS (9 tests).

- [ ] **Step 5: Run the whole package and commit**

Run: `swift test --package-path GlassTableDrills`
Expected: all pre-existing tests still green plus the new ones.

```bash
git add GlassTableDrills/Sources/GlassTableDrills/Progression/LegacyMigration.swift \
        GlassTableDrills/Tests/GlassTableDrillsTests/LegacyMigrationTests.swift
git commit -m "feat(progression): fold legacy per-drill progress into the new store"
```

---

## Verification for this sub-project

1. `swift test --package-path GlassTableDrills` — all green, no simulator.
2. `git diff main -- GlassTableEngine` is **empty** (no engine change here, so the
   release-mode engine gate is not required for this sub-project).
3. No `import SwiftData` / `UIKit` / `SwiftUI` anywhere in `GlassTableDrills`.
4. `Progress.swift` is unmodified — the shipped drills keep working untouched.
