import XCTest
@testable import GlassTableEngine

final class HandEvaluatorTests: XCTestCase {
    private func eval(_ s: String) -> Int { evaluate5(Card.parse(s)!) }

    func testCategoryOrdering() {
        let straightFlush = eval("9s8s7s6s5s")
        let quads         = eval("9s9h9d9c2s")
        let fullHouse     = eval("9s9h9dKcKs")
        let flush         = eval("As9s7s4s2s")
        let straight      = eval("9s8h7d6c5s")
        let trips         = eval("9s9h9d4c2s")
        let twoPair       = eval("9s9hKcKd2s")
        let pair          = eval("9s9h5c3d2s")
        let highCard      = eval("AsKh9d5c2s")
        // strictly decreasing
        let ordered = [straightFlush, quads, fullHouse, flush, straight, trips, twoPair, pair, highCard]
        for i in 1..<ordered.count {
            XCTAssertGreaterThan(ordered[i-1], ordered[i], "rank \(i-1) should beat \(i)")
        }
    }

    func testWheelIsFiveHighStraight() {
        XCTAssertGreaterThan(eval("6s5h4d3c2s"), eval("As2h3d4c5s")) // 6-high > wheel
        XCTAssertGreaterThan(eval("As2h3d4c5s"), eval("AsKhQdJc9s")) // wheel(straight) > ace-high
    }

    func testKickerMatters() {
        XCTAssertGreaterThan(eval("AsAhKd5c3s"), eval("AsAhQd5c3s")) // AA-K > AA-Q kicker
    }

    func testEqualHandsEqualKeys() {
        XCTAssertEqual(eval("AsAhKdQc9s"), eval("AcAdKsQh9c")) // suits irrelevant
    }

    func testEvaluate7PicksBestFive() {
        // 7 cards containing a flush; best-5 is the flush.
        let seven = Card.parse("AsKsQs7s2s5h3d")!
        let flushOnly = evaluate5(Card.parse("AsKsQs7s2s")!)
        XCTAssertEqual(evaluate7(seven), flushOnly)
    }

    func testEvaluate7FindsStraightAcrossSevenCards() {
        let seven = Card.parse("9c8h7s6d5cKsQh")!
        let straight = evaluate5(Card.parse("9c8h7s6d5c")!)
        XCTAssertEqual(evaluate7(seven), straight)
    }
}
