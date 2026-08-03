import XCTest
import GlassTableEngine
@testable import GlassTableDrills

final class PositionTests: XCTestCase {
    func testEightMaxSeatsInPreflopOrder() {
        XCTAssertEqual(Position.allCases.count, 8)
        XCTAssertEqual(Position.preflopOrder.map(\.rawValue),
                       ["UTG", "UTG+1", "LJ", "HJ", "CO", "BTN", "SB", "BB"])
    }

    /// The inversion is the point of the drill: blinds act last preflop and first after.
    func testBlindsActLastPreflopAndFirstPostflop() {
        XCTAssertEqual(Position.preflopOrder.suffix(2), [.sb, .bb])
        XCTAssertEqual(Position.postflopOrder.prefix(2), [.sb, .bb])
        XCTAssertEqual(Position.postflopOrder.last, .btn)
    }

    func testPlayersBehindPreflop() {
        XCTAssertEqual(Position.utg.playersBehind(preflop: true), 7)
        // CO, BTN, SB, BB act after the hijack.
        XCTAssertEqual(Position.hj.playersBehind(preflop: true), 4)
        XCTAssertEqual(Position.btn.playersBehind(preflop: true), 2)
        XCTAssertEqual(Position.bb.playersBehind(preflop: true), 0)
    }

    func testPlayersBehindPostflop() {
        XCTAssertEqual(Position.sb.playersBehind(preflop: false), 7)
        XCTAssertEqual(Position.btn.playersBehind(preflop: false), 0)
        XCTAssertEqual(Position.hj.playersBehind(preflop: false), 2)   // CO, BTN
    }

    func testEverySeatHasADistinctCountOnEachStreet() {
        for preflop in [true, false] {
            let counts = Position.allCases.map { $0.playersBehind(preflop: preflop) }
            XCTAssertEqual(Set(counts).count, 8)
            XCTAssertEqual(counts.sorted(), Array(0...7))
        }
    }

    func testActsAfterUsesPostflopOrderAndIsAStrictOrdering() {
        XCTAssertTrue(Position.btn.actsAfter(.utg))
        XCTAssertFalse(Position.utg.actsAfter(.btn))
        XCTAssertFalse(Position.btn.actsAfter(.btn))
        // The blinds are the worst postflop seats despite acting last preflop.
        XCTAssertTrue(Position.utg.actsAfter(.bb))
    }

    func testGeneratorIsDeterministicAndVaried() {
        XCTAssertEqual(PositionSpotGenerator.spot(baseSeed: 11, index: 5),
                       PositionSpotGenerator.spot(baseSeed: 11, index: 5))
        let spots = (0..<60).map { PositionSpotGenerator.spot(baseSeed: 11, index: $0) }
        XCTAssertGreaterThan(Set(spots.map { "\($0.question)" }).count, 8)
        // Both question shapes must actually appear.
        var behind = 0, compare = 0
        for s in spots {
            if case .behind = s.question { behind += 1 } else { compare += 1 }
        }
        XCTAssertGreaterThan(behind, 0)
        XCTAssertGreaterThan(compare, 0)
    }

    func testComparisonSpotsNeverPitASeatAgainstItself() {
        for i in 0..<300 {
            let s = PositionSpotGenerator.spot(baseSeed: 7, index: i)
            if case let .whichIsLater(a, b) = s.question { XCTAssertNotEqual(a, b) }
        }
    }

    func testEveryGeneratedSpotHasAReachableCorrectAnswer() {
        for i in 0..<300 {
            let s = PositionSpotGenerator.spot(baseSeed: 3, index: i)
            switch s.question {
            case .behind: XCTAssertTrue((0...7).contains(s.correctAnswer))
            case .whichIsLater: XCTAssertTrue((0...1).contains(s.correctAnswer))
            }
            XCTAssertEqual(gradePosition(answer: s.correctAnswer, spot: s).band, .spotOn)
        }
    }

    func testGradingIsBinaryAndExplains() {
        let spot = PositionSpot(question: .behind(.hj, preflop: true))
        XCTAssertEqual(gradePosition(answer: 4, spot: spot).band, .spotOn)
        XCTAssertEqual(gradePosition(answer: 3, spot: spot).band, .off,
                       "an exact question has no 근접 band")
        XCTAssertTrue(gradePosition(answer: 4, spot: spot).whyText.contains("CO"))
    }

    func testTheLastSeatExplanationDoesNotClaimAnEmptyList() {
        let spot = PositionSpot(question: .behind(.bb, preflop: true))
        XCTAssertTrue(gradePosition(answer: 0, spot: spot).whyText.contains("마지막"))
    }
}
